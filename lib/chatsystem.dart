import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/admin/Admin-Dashboard.dart';
import 'package:myapp/admin/Admin-Home.dart';
import 'package:myapp/admin/Admin-Leaderboard.dart';
import 'package:myapp/admin/Admin-Thread.dart';
import 'package:myapp/chatbot.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Cohere API function
Future<String> fetchCohere(String message) async {
  final apiKey = 'jg9xhX0cMSv6eZxA9VWLYed39ADtKjenJuWyIYgs';
  final url = Uri.parse('https://api.cohere.com/v1/chat');
  final payload = {'model': 'command-r-plus', 'message': message};

  try {
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200) {
      final decoded = utf8.decode(res.bodyBytes);
      final data = jsonDecode(decoded);
      return data['text'] ?? 'No response from AI';
    } else {
      return 'Error: ${res.statusCode} ${res.body}';
    }
  } catch (e) {
    return 'Connection error: $e';
  }
}

// ฟังก์ชัน global สำหรับดึงรูปโปรไฟล์
Future<String?> fetchProfilePicture(int userId) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://mfu-food-guide-review.onrender.com/user-profile/$userId',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['picture_url'];
    } else {
      print('Failed to load profile picture');
      return null;
    }
  } catch (e) {
    print('Error fetching profile picture: $e');
    return null;
  }
}

// ฟังก์ชันสำหรับดึงข้อมูลผู้ใช้จาก API
Future<Map<String, dynamic>?> fetchUserProfile(int userId) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://mfu-food-guide-review.onrender.com/user-profile/$userId',
      ),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to load user profile: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching user profile: $e');
    return null;
  }
}

class Chatbot2Screen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<Chatbot2Screen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  String? profileImageUrl;
  int? userId;
  int _selectedIndex = 2;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  FocusNode _focusNode = FocusNode();
  bool _showAppBar = true;
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    loadUserIdAndFetchProfile();
    _addWelcomeMessage();

    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _typingAnimation = CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    );

    // เพิ่ม listener สำหรับ scroll controller
    _scrollController.addListener(() {
      // ตรวจจับการเลื่อนและซ่อน/แสดง AppBar
      if (_scrollController.offset > 100 && _showAppBar) {
        setState(() {
          _showAppBar = false;
        });
      } else if (_scrollController.offset <= 100 && !_showAppBar) {
        setState(() {
          _showAppBar = true;
        });
      }
    });

    // เพิ่ม listener สำหรับ keyboard
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // เมื่อ keyboard เปิด ให้เลื่อนไปยังด้านล่าง
        scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> loadUserIdAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('user_id');

    if (storedUserId != null) {
      setState(() {
        userId = storedUserId;
      });

      // ดึงรูปโปรไฟล์
      final imageUrl = await fetchProfilePicture(userId!);
      final profileData = await fetchUserProfile(userId!);
      setState(() {
        profileImageUrl = imageUrl;
        userProfile = profileData;
      });
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage =
        "สวัสดีครับ! ผมเป็นผู้ช่วย Food Threads ที่นี่เพื่อตอบคำถามเกี่ยวกับร้านอาหารและบริการต่างๆ ในมหาวิทยาลัยแม่ฟ้าหลวง ถ้าคุณมีคำถามอะไร ถามได้เลยนะครับ";

    setState(() {
      _messages.add({
        "role": "bot",
        "content": welcomeMessage,
        "timestamp": DateTime.now().toString(),
      });
    });

    // เลื่อนไปยังข้อความล่าสุดหลังจากเพิ่มข้อความต้อนรับ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
  }

  void sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        "role": "user",
        "content": message,
        "timestamp": DateTime.now().toString(),
      });
      _controller.clear();
    });

    scrollToBottom();

    // // ตรวจสอบว่าผู้ใช้ต้องการดูข้อมูลโปรไฟล์
    // if (message.toLowerCase().contains('profile') ||
    //     message.toLowerCase().contains('โปรไฟล์') ||
    //     message.toLowerCase().contains('ข้อมูลส่วนตัว')) {
    //   setState(() {
    //     _isLoading = true;
    //   });

    //   // รอสักครู่เพื่อแสดงการโหลด
    //   await Future.delayed(Duration(milliseconds: 500));

    //   if (userProfile != null) {
    //     setState(() {
    //       _messages.add({
    //         "role": "bot",
    //         "content": "นี่คือข้อมูลโปรไฟล์ของคุณ",
    //         "timestamp": DateTime.now().toString(),
    //       });
    //       _isLoading = false;
    //     });

    //     // เลื่อนไปยังส่วนบนเพื่อแสดงข้อมูลโปรไฟล์
    //     _scrollController.animateTo(
    //       0,
    //       duration: Duration(milliseconds: 500),
    //       curve: Curves.easeOut,
    //     );
    //   } else {
    //     setState(() {
    //       _messages.add({
    //         "role": "bot",
    //         "content": "ไม่สามารถโหลดข้อมูลโปรไฟล์ได้",
    //         "timestamp": DateTime.now().toString(),
    //       });
    //       _isLoading = false;
    //     });
    //   }
    // }
    // // ตรวจสอบว่าผู้ใช้ต้องการดูข้อมูล coins
    // else
    if (message.toLowerCase().contains('coin') ||
        message.toLowerCase().contains('coins') ||
        message.toLowerCase().contains('เหรียญ') ||
        message.toLowerCase().contains('คะแนน')) {
      setState(() {
        _isLoading = true;
      });

      // รอสักครู่เพื่อแสดงการโหลด
      await Future.delayed(Duration(milliseconds: 500));

      if (userProfile != null) {
        final coins = userProfile!['coins'] ?? 0;
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "You have $coins coins",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "ไม่สามารถโหลดข้อมูล coins ได้",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });
        scrollToBottom();
      }
    } else if (message.toLowerCase().contains('username') ||
        message.toLowerCase() == 'user' ||
        message.toLowerCase().contains('my username') ||
        message.toLowerCase().contains('ชื่อผู้ใช้')) {
      setState(() {
        _isLoading = true;
      });

      // รอสักครู่เพื่อแสดงการโหลด
      await Future.delayed(Duration(milliseconds: 500));

      if (userProfile != null) {
        final username = userProfile!['username'] ?? 0;
        setState(() {
          _messages.add({
            "role": "bot",
            "content": " Hello, $username ",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });

        scrollToBottom();
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "ไม่สามารถโหลดข้อมูล coins ได้",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });
      }
    } else if (message.toLowerCase().contains('fullname') ||
        message.toLowerCase().contains('full name') ||
        message.toLowerCase().contains('ชื่อจริง') ||
        message.toLowerCase().contains('นามสกุล') ||
        message.toLowerCase().contains('ชื่อ-นามสกุล')) {
      setState(() {
        _isLoading = true;
      });

      // รอสักครู่เพื่อแสดงการโหลด
      await Future.delayed(Duration(milliseconds: 500));

      if (userProfile != null) {
        final fullname = userProfile!['fullname'] ?? 0;
        setState(() {
          _messages.add({
            "role": "bot",
            "content": " Your Fullname is, $fullname ",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });

        scrollToBottom();
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "ไม่สามารถโหลดข้อมูล coins ได้",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });
      }
    } else if (message.toLowerCase().contains('chatbot'))
    // message.toLowerCase().contains('c') ||
    // message.toLowerCase().contains('user') ||
    // message.toLowerCase().contains('name'))
    {
      setState(() {
        _messages.add({
          "role": "bot",
          "content": "Redirect To  Chat system",
          "timestamp": DateTime.now().toString(),
        });
      });

      // รอสักครู่เพื่อแสดงการโหลด

      Future.delayed(Duration(milliseconds: 1500), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatbotScreen()),
        );
      });
    }
    // ตรวจสอบว่าผู้ใช้พิมพ์คำว่า "dashboard" หรือไม่
    else if (message.toLowerCase().contains('dashboard') ||
        message.toLowerCase().contains('แดชบอร์ด') ||
        (message.toLowerCase().contains('ภาพรวม'))) {
      // แสดงข้อความตอบรับก่อนนำทาง
      setState(() {
        _messages.add({
          "role": "bot",
          "content": "Redirect To Dashboard...",
          "timestamp": DateTime.now().toString(),
        });
      });

      // รอสักครู่แล้วนำทางไปยังหน้า Dashboard
      Future.delayed(Duration(milliseconds: 1500), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashboardAdmin()),
        );
      });
    } else {
      // สำหรับข้อความอื่นๆ ให้แสดงข้อความตอบกลับคงที่
      setState(() {
        _isLoading = true;
      });

      // จำลองการโหลดข้อมูล
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _messages.add({
          "role": "bot",
          "content":
              "ขออภัย ระบบตอบกลับอัตโนมัติไม่พร้อมใช้งานในขณะนี้ กรุณาติดต่อผู้ดูแลระบบ",
          "timestamp": DateTime.now().toString(),
        });
        _isLoading = false;
      });

      scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      body: Column(
        children: [
          // AppBar ที่สามารถซ่อนได้เมื่อเลื่อน
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _showAppBar ? 90 : 0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFCEBFA3), Color(0xFFB39D70)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: OverflowBox(
              maxHeight: 90,
              child: Container(
                padding: EdgeInsets.only(left: 20, right: 20, top: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Food  Assistant',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 25,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 4,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => ProfilePageAdmin(),
                        //   ),
                        // );
                      },
                      child: profileImageUrl == null
                          ? CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.3),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 26,
                              ),
                              radius: 24,
                            )
                          : CircleAvatar(
                              backgroundImage: NetworkImage(profileImageUrl!),
                              radius: 24,
                              backgroundColor: Colors.grey[300],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ส่วนแสดงข้อความแชท
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                // ตรวจจับการเลื่อน
                if (scrollNotification is ScrollUpdateNotification) {
                  if (scrollNotification.metrics.pixels > 100 && _showAppBar) {
                    setState(() {
                      _showAppBar = false;
                    });
                  } else if (scrollNotification.metrics.pixels <= 100 &&
                      !_showAppBar) {
                    setState(() {
                      _showAppBar = true;
                    });
                  }
                }
                return false;
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFFF7F4EF), const Color(0xFFF7F4EF)],
                  ),
                ),
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: 8, top: 16),
                  children: [
                    // แสดงการ์ดข้อมูลผู้ใช้หากมีข้อมูล
                    if (userProfile != null)
                      UserProfileCard(
                        userProfile: userProfile!,
                        profileImageUrl: profileImageUrl,
                      ),

                    // แสดงข้อความแชท
                    ..._messages.map((msg) {
                      final isUser = msg['role'] == 'user';
                      final content = msg['content'] ?? '';
                      final timestamp = msg['timestamp'] ?? '';

                      return ChatBubble(
                        message: content,
                        isUser: isUser,
                        isError: content.toLowerCase().contains('error'),
                        timestamp: timestamp,
                        userId: userId,
                      );
                    }).toList(),

                    // แสดงตัวบ่งชี้การพิมพ์หากกำลังโหลด
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TypingIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Input field
          MessageInputField(
            controller: _controller,
            onSend: sendMessage,
            isLoading: _isLoading,
            userId: userId,
            focusNode: _focusNode,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFB39D70),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
          elevation: 10,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events_rounded),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum_rounded),
              label: 'Threads',
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RestaurantListPageAdmin()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LeaderboardPageAdmin()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ThreadsAdminPage()),
        );
        break;
    }
  }
}

// ฟังก์ชันช่วยเหลือสำหรับการจัดรูปแบบวันที่
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final messageDate = DateTime(date.year, date.month, date.day);

  if (messageDate == today) {
    return 'วันนี้';
  } else if (messageDate == yesterday) {
    return 'เมื่อวาน';
  } else {
    return '${date.day}/${date.month}/${date.year + 543}'; // แปลงเป็น พ.ศ.
  }
}

// ส่วนที่เหลือของโค้ด (ChatBubble, MessageInputField, TypingIndicator) ไม่มีการเปลี่ยนแปลง
// [คงเหลือส่วนของโค้ดเดิมไว้ตามเดิม]
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isError;
  final String timestamp;
  final int? userId;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.isError = false,
    required this.timestamp,
    required this.userId,
  }) : super(key: key);

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  // ใน Widget ChatBubble
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // ข้อความแชท
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar สำหรับบอท (ด้านซ้าย)
              if (!isUser && !isError)
                Container(
                  width: 40,
                  height: 40,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A7DE9), Color(0xFF9D50BB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

              // Avatar สำหรับ error (ด้านซ้าย)
              if (isError)
                Container(
                  width: 40,
                  height: 40,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

              // ข้อความและเวลา
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isError
                            ? Colors.red[100]
                            : isUser
                            ? Color(0xFFB39D70)
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: isUser
                              ? const Radius.circular(20)
                              : const Radius.circular(6),
                          bottomRight: isUser
                              ? const Radius.circular(6)
                              : const Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: isError
                              ? Colors.red[900]
                              : isUser
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),

                    // เวลาอยู่ใต้ข้อความ
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ระยะห่างสำหรับ user
              if (isUser) SizedBox(width: 10),

              // Avatar สำหรับ user (ด้านขวา)
              if (isUser && !isError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 6),
                  child: FutureBuilder<String?>(
                    future: userId != null
                        ? fetchProfilePicture(userId!)
                        : Future.value(null),
                    builder: (context, snapshot) {
                      // if (snapshot.connectionState == ConnectionState.waiting) {
                      //   return CircleAvatar(
                      //     radius: 22,
                      //     backgroundColor: Colors.grey.shade300,
                      //     child: const CircularProgressIndicator(
                      //       strokeWidth: 2,
                      //       valueColor: AlwaysStoppedAnimation<Color>(
                      //         Colors.white,
                      //       ),
                      //     ),
                      //   );
                      // } else
                      if (snapshot.hasError || snapshot.data == null) {
                        return CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFFB39D70),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22,
                          ),
                        );
                      } else {
                        return CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(snapshot.data!),
                          backgroundColor: Colors.grey.shade300,
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final int? userId;
  final FocusNode focusNode;

  const MessageInputField({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.isLoading,
    this.userId,
    required this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FutureBuilder<String?>(
            future: userId != null
                ? fetchProfilePicture(userId!)
                : Future.value(null),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade300,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              } else if (snapshot.hasError || snapshot.data == null) {
                return CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFB39D70),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                );
              } else {
                return CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(snapshot.data!),
                  backgroundColor: Colors.grey.shade300,
                );
              }
            },
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey[300]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  isLoading
                      ? Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFB39D70),
                              ),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: Color(0xFFB39D70),
                            size: 26,
                          ),
                          onPressed: onSend,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Create staggered animations for each dot
    _dotAnimations = List.generate(3, (index) {
      return Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2, // Stagger the start time for each dot
            1.0,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 60, right: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedDot(0),
                SizedBox(width: 5),
                _buildAnimatedDot(1),
                SizedBox(width: 5),
                _buildAnimatedDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _dotAnimations[index].value,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Color(0xFFB39D70),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// เพิ่ม Widget ใหม่สำหรับแสดงข้อมูลผู้ใช้
class UserProfileCard extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final String? profileImageUrl;

  const UserProfileCard({
    Key? key,
    required this.userProfile,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Today',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7E8B9F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // profileImageUrl != null
              //     ? CircleAvatar(
              //         backgroundImage: NetworkImage(profileImageUrl!),
              //         radius: 30,
              //       )
              //     : CircleAvatar(
              //         backgroundColor: Color(0xFFB39D70),
              //         child: Icon(Icons.person, color: Colors.white),
              //         radius: 30,
              //       ),
              // SizedBox(width: 16),
              // Expanded(
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         userProfile['fullname'] ?? 'No Name',
              //         style: TextStyle(
              //           fontSize: 18,
              //           fontWeight: FontWeight.bold,
              //           color: Colors.black87,
              //         ),
              //       ),
              //       SizedBox(height: 4),
              //       Text(
              //         '@${userProfile['username'] ?? 'No username'}',
              //         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
          // SizedBox(height: 16),
          // Text(
          //   userProfile['bio'] ?? 'No bio available',
          //   style: TextStyle(fontSize: 14, color: Colors.black54),
          // // ),
          // SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // _buildStatItem(
              //   'Reviews',
              //   userProfile['total_reviews']?.toString() ?? '0',
              // ),
              // _buildStatItem(
              //   'Likes',
              //   userProfile['total_likes']?.toString() ?? '0',
              // ),
              // _buildStatItem('Coins', userProfile['coins']?.toString() ?? '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB39D70),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
