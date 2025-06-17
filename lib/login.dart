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

      // SEND TO BACKEND
      final response = await http.post(
        Uri.parse('https://your-backend.cleverapps.io/user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': googleUser.displayName,
          'username': googleUser.email.split('@')[0],
          'email': googleUser.email,
          'google_id': googleUser.id,
        }),
      );
      print(response.body);
    } catch (error) {
      print("Login Error: $error");
      setState(() {
        _errorMessage = 'Login failed';
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
                  Text("Hello, ${_user!.displayName}"),
                  ElevatedButton(onPressed: signOut, child: Text("Sign Out")),
                ],
              ),
      ),
    );
  }
}
