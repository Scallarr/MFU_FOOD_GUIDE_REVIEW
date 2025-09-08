import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/admin/Admin-Home.dart';
import 'package:myapp/home.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  GoogleSignInAccount? _user;

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
        Uri.parse('http://10.214.52.39:8080/user/login'),
        // Uri.parse('https://mfu-food-guide-review.onrender.com/user/login'),
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
          Uri.parse('http://10.214.52.39:8080/user/info/$userId'),
          // headers: {'Authorization': 'Bearer $token'},
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
          if (role == 'User' || status != 'Banned') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => RestaurantListPageAdmin()),
              (Route<dynamic> route) => false,
            );
          } else if (role == 'Admin' || status != 'Banned') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => RestaurantListPageAdmin()),
              (Route<dynamic> route) => false,
            );
          }

          // else if (status == 'Banned') {
          //   await _googleSignIn.signOut();
          //   final prefs = await SharedPreferences.getInstance();
          //   await prefs.clear();
          //   _showAlert(context, 'Your account has been banned.');
          //   return;
          // }
        } else if (response.statusCode == 401) {
          // Token หมดอายุ
          _showAlert(context, 'Session expired');
          return;
        } else if (response.statusCode == 403) {
          // User ถูกแบน - ดึงข้อมูลจาก backend
          final data = json.decode(response.body);

          String extraMessage = '';
          if (data['remainingTime'] is Map) {
            final time = data['remainingTime'];
            extraMessage =
                '\nRemaining: ${time['days']}d ${time['hours']}h ${time['minutes']}m ${time['seconds']}s';
          } else {
            extraMessage = '\nRemaining: Permanent Ban';
          }

          _showAlert(
            context,
            'Your account has been banned.\n'
            'Reason: ${data['reason']}\n'
            'Ban Date: ${data['banDate']}\n'
            'Expected Unban: ${data['expectedUnbanDate'] ?? "N/A"}'
            '$extraMessage',
          );

          return;
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
