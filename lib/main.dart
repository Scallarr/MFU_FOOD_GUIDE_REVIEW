import 'package:flutter/material.dart';
import 'package:myapp/Atlas-model.dart';
import 'login.dart'; // สมมติว่าหน้า LoginScreen เก็บไว้ในไฟล์ login.dart
import 'package:firebase_storage/firebase_storage.dart'; // เพิ่ม Firebase Storage
import 'package:firebase_core/firebase_core.dart'; // เพิ่ม Firebase Core
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null); // ✅ โหลด locale ไทย
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: ChatbotScreen(),
      home: LoginScreen(), // เรียกใช้หน้า LoginScreen
    );
  }
}
