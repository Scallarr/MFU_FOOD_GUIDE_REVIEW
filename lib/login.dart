import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/admin/Admin-Home.dart';
import 'package:myapp/home.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: MaterialApp(
        title: 'MFU Food Guide',
        theme: ThemeData(fontFamily: 'Arial'),
        home: LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  GoogleSignInAccount? _user;
  late AnimationController _lockIconController; // ✅ เพิ่ม AnimationController
  late Animation<double> _lockIconAnimation; // ✅ เพิ่ม Animation

  void initState() {
    super.initState();
    _lockIconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _lockIconAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _lockIconController, curve: Curves.easeInOut),
    );
  }

  void dispose() {
    _lockIconController.dispose(); // ✅ อย่าลืม dispose controller
    super.dispose();
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      final userPhotoUrl = googleUser?.photoUrl;
      if (googleUser == null) return;

      final isAdmin = googleUser.email == 'kasiditkosit@gmail.com';
      final isAdmin2 = googleUser.email == '49369@cru.ac.th';

      if (!googleUser.email.endsWith('@lamduan.mfu.ac.th') &&
          !isAdmin &&
          !isAdmin2) {
        await _googleSignIn.signOut();
        setState(() => _user = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only @lamduan.mfu.ac.th email accounts are allowed.',
            ),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://172.22.173.39:8080/user/login'),
        // Uri.parse('http://172.22.173.39:8080/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': googleUser.displayName,
          'username': googleUser.email.split('@')[0],
          'email': googleUser.email,
          'google_id': googleUser.id,
          'picture_url': googleUser.photoUrl ?? '', // ✅ เพิ่มตรงนี้
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userId = data['userId'];

        print('dg' + userPhotoUrl.toString());
        // ดึงข้อมูล user เพิ่มเติมจาก API (เช่น role, bio, etc.)
        final userInfoResponse = await http.get(
          Uri.parse('http://172.22.173.39:8080/user/info/$userId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (userInfoResponse.statusCode == 200) {
          final userInfo = jsonDecode(userInfoResponse.body);
          final role = userInfo['role'] ?? 'User';
          final status = userInfo['status'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setInt('user_id', userId);
          await prefs.setString('user_photo', googleUser.photoUrl ?? '');
          await prefs.setString('user_role', role);
          await prefs.setString('user_name', googleUser.displayName ?? '');
          await prefs.setString('user_email', googleUser.email);
          await prefs.setString('status', status);
          print(status);
          setState(() => _user = googleUser);

          // ไปหน้า HomePage ตาม role
          if (role == 'User' && status != 'Banned') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => RestaurantListPageUser()),
              (Route<dynamic> route) => false,
            );
          } else if (role == 'Admin' && status != 'Banned') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => RestaurantListPageAdmin()),
              (Route<dynamic> route) => false,
            );
          } else if (status == 'Banned') {
            await _googleSignIn.signOut();
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            _showAlert(context, 'Your account has been banned.');
            return;
          }
        } else if (userInfoResponse.statusCode == 401) {
          // Token หมดอายุ
          _showAlert(context, 'Session expired');
          return;
        } else if (userInfoResponse.statusCode == 403) {
          // User ถูกแบน - ดึงข้อมูลจาก backend
          final data = json.decode(userInfoResponse.body);

          // แก้ไขการ parse วันที่
          DateTime? expectedUnban;
          if (data['expectedUnbanDate'] != null) {
            try {
              // ลอง parse ในรูปแบบต่างๆ
              expectedUnban = DateTime.tryParse(data['expectedUnbanDate']);
              if (expectedUnban == null &&
                  data['expectedUnbanDate'] is String) {
                // ลองแปลงจาก timestamp string
                final timestamp = int.tryParse(data['expectedUnbanDate']);
                if (timestamp != null) {
                  expectedUnban = DateTime.fromMillisecondsSinceEpoch(
                    timestamp,
                  );
                }
              }
            } catch (e) {
              debugPrint('Error parsing expectedUnbanDate: $e');
            }
          }

          _showBanDialog(
            context,
            reason: data['reason'] ?? "Unknown",
            ban_duration_days: data['ban_duration_days'] as int?, // nullable
            banDate: data['banDate'] ?? "N/A",
            expectedUnban: expectedUnban,
          );
        } else {
          throw Exception('Failed to get user information');
        }
      } else {
        throw Exception('Failed to login');
      }
    } catch (error) {
      print('Login error: $error');
      setState(() => _user = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${error.toString()}'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _showBanDialog(
    BuildContext context, {
    required String reason,
    required int? ban_duration_days,
    required String banDate,
    DateTime? expectedUnban,
  }) {
    // Format วันที่ให้แสดงแค่วันที่ ไม่ต้องมีเวลา
    String formatDateOnly(String dateString) {
      try {
        final dateTime = DateTime.parse(dateString);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        return dateString; // หาก parse ไม่ได้ return ค่าเดิม
      }
    }

    String formatExpectedUnban(DateTime? date) {
      if (date == null) return "Permanent";
      return '${date.day}/${date.month}/${date.year}';
    }

    // State สำหรับ remaining time
    final remainingTimeNotifier = ValueNotifier<String>(
      expectedUnban == null ? "Permanent Ban" : "Calculating...",
    );

    Timer? timer;
    if (expectedUnban != null) {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        final now = DateTime.now();
        final diff = expectedUnban.difference(now);

        if (diff.isNegative) {
          remainingTimeNotifier.value = "00.00.00";
          t.cancel();
        } else {
          final days = diff.inDays;
          final hours = diff.inHours % 24;
          final minutes = diff.inMinutes % 60;
          final seconds = diff.inSeconds % 60;
          remainingTimeNotifier.value =
              "${days}d ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s";
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  top: -20,
                  right: -20,
                  child: Icon(
                    Icons.lock_outlined,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Icon(
                    Icons.security,
                    size: 100,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ แก้ไขเป็น AnimatedBuilder สำหรับไอคอนล็อค
                      AnimatedBuilder(
                        animation: _lockIconAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _lockIconAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE74C3C).withOpacity(0.2),
                                border: Border.all(
                                  color: const Color(0xFFE74C3C),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                size: 48,
                                color: Color(0xFFE74C3C),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        "Account Restricted",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      const Text(
                        "Your account has been temporarily suspended",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          left: 50,
                          right: 0,
                          top: 20,
                          bottom: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInfoRow("Reason", reason),
                            const SizedBox(height: 12),
                            _buildInfoRow("Ban Date", formatDateOnly(banDate)),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              "Ban Duration",
                              ban_duration_days != null
                                  ? "$ban_duration_days Days"
                                  : "Permanent Ban",
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Countdown Timer (แสดงเฉพาะถ้าไม่ใช่แบนถาวร)
                      if (expectedUnban != null)
                        ValueListenableBuilder<String>(
                          valueListenable: remainingTimeNotifier,
                          builder: (context, remainingTime, _) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C3E50),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFFE74C3C,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "TIME REMAINING",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    remainingTime,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFE74C3C),
                                      fontFamily: 'Monospace',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3E50),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE74C3C).withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            "PERMANENT BAN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE74C3C),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE74C3C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            elevation: 4,
                          ),
                          onPressed: () async {
                            timer?.cancel();
                            await _googleSignIn.signOut();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.exit_to_app, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Sign Out",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Support Text
                      GestureDetector(
                        onTap: () {
                          // Handle support contact
                        },
                        child: const Text(
                          "Contact support if you believe this is a mistake",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() async {
      // ✅ ตรงนี้จะถูกเรียกเสมอ หลัง dialog หาย (ไม่ว่าจะปิดยังไง)
      timer?.cancel();
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            "$label:",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    setState(() => _user = null);
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // ผู้ใช้ต้องกดปุ่ม OK ก่อนปิด
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 15),
              Text(
                'Warning',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              // ❌ เปลี่ยนจาก SingleChildScrollView เป็น Column ธรรมดา
              children: [
                SizedBox(height: isMobile ? 45 : 40),
                Text(
                  "MFU Food Guide",
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "assets/food.png",
                    height: isMobile ? 170 : 200,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 32),
                Text(
                  "MFU Food Guide & Review",
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Discover and review delicious campus food",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: isMobile ? 30 : 36),

                if (_user == null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Image.asset(
                              "assets/google_logo.png",
                              height: 28,
                            ),
                            label: Text(
                              "Login with Google",
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.black),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(child: Divider(color: Colors.grey)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                              ),
                              child: Text(
                                "or",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey)),
                          ],
                        ),
                        SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.person_outline, size: 28),
                            label: Text(
                              "Stay as Guest",
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () {
                              print("Guest login");
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.black),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          "Only @lamduan.mfu.ac.th email accounts are allowed to login\nNo sign-up option available",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Spacer(), // ดันให้ footer อยู่ด้านล่าง
                Text(
                  "©2025 MFU Food Guide\nMae Fah Luang University",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
