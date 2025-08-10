import 'package:flutter/material.dart';
import 'login.dart'; // สมมติว่าหน้า LoginScreen เก็บไว้ในไฟล์ login.dart
import 'package:firebase_storage/firebase_storage.dart'; // เพิ่ม Firebase Storage
import 'package:firebase_core/firebase_core.dart'; // เพิ่ม Firebase Core

void main() async {
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
