import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Login',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
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
  String _errorMessage = '';

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      setState(() {
        _user = googleUser;
        _errorMessage = '';
      });

      // ส่งข้อมูลไป backend
      final response = await http.post(
        Uri.parse('https://mfu-food-guide-review.onrender.com/user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': googleUser.displayName,
          'username': googleUser.email.split('@')[0],
          'email': googleUser.email,
          'google_id': googleUser.id,
        }),
      );

      print("✅ Data sent to backend:");
      print("fullname: ${googleUser.displayName}");
      print("username: ${googleUser.email.split('@')[0]}");
      print("email: ${googleUser.email}");
      print("google_id: ${googleUser.id}");
      print("📡 Backend response: ${response.body}");
    } catch (error) {
      print("❌ Login Error: $error");
      setState(() {
        _errorMessage = 'Login failed: ${error.toString()}';
      });
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Sign-In")),
      body: Center(
        child: _user == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: signInWithGoogle,
                    child: Text("Login with Google"),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_user!.photoUrl != null)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(_user!.photoUrl!),
                    ),
                  SizedBox(height: 10),
                  Text("Hello, ${_user!.displayName}"),
                  Text("Email: ${_user!.email}"),
                  ElevatedButton(onPressed: signOut, child: Text("Sign Out")),
                  if (_user!.photoUrl == null) Text('fg'),
                ],
              ),
      ),
    );
  }
}
