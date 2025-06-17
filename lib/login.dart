import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MFU Food Guide',
      theme: ThemeData(fontFamily: 'Arial'),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
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
      if (googleUser == null) return;

      if (!googleUser.email.endsWith('@lamduan.mfu.ac.th')) {
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

      // POST data to backend login route
      final response = await http.post(
        Uri.parse('https://mfu-food-guide-review.onrender.com/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': googleUser.displayName,
          'username': googleUser.email.split('@')[0],
          'email': googleUser.email,
          'google_id': googleUser.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userId = data['userId'];

        // เก็บ token และ userId ไว้ใน SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setInt('user_id', userId);

        setState(() => _user = googleUser);

        print('Login success. User ID: $userId');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "MFU Food Guide ",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "assets/food.png",
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "MFU Food Guide & Review",
                  style: TextStyle(
                    fontSize: 26,
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
                    fontSize: 16,
                    color: Color.fromARGB(255, 50, 49, 49),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 32),
                if (_user == null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Image.asset("assets/google_logo.png", height: 30),
                      label: Text(
                        "Login with Google",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.black),
                        padding: EdgeInsets.symmetric(vertical: 16),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          "or",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.person_outline, size: 30),
                      label: Text(
                        "Stay as Guest",
                        style: TextStyle(
                          fontSize: 18,
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
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Only @lamduan.mfu.ac.th email accounts are allowed to login\nNo sign-up option available",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  if (_user!.photoUrl != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_user!.photoUrl!),
                    ),
                  SizedBox(height: 16),
                  Text(
                    "Hello, ${_user!.displayName}",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Email: ${_user!.email}",
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: signOut,
                    child: Text("Sign Out", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 40,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                Spacer(),
                Text(
                  "©2025 MFU Food Guide\nMae Fah Luang University",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
