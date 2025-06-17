import 'package:flutter/material.dart';
import 'login.dart'; // สมมติว่าหน้า LoginScreen เก็บไว้ในไฟล์ login.dart

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(), // เรียกใช้หน้า LoginScreen
    );
  }
}
