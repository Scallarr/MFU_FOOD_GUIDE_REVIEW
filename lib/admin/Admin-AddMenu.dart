import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Addmenu extends StatefulWidget {
  final int restaurantId;

  const Addmenu({Key? key, required this.restaurantId}) : super(key: key);

  @override
  _AddmenuState createState() => _AddmenuState();
}

class _AddmenuState extends State<Addmenu> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _thaiNameController = TextEditingController();
  final TextEditingController _englishNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;
  final String _imgbbApiKey =
      '762958d4dfc64c8a75fe00a0359c6b05'; // เปลี่ยนเป็น API Key จริงของคุณ

  // 1. เลือกรูปภาพ
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 2. อัปโหลดรูปไปยัง ImgBB
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (jsonResponse['success'] == true) {
        setState(() {
          _imageUrl = jsonResponse['data']['url']; // ได้ URL รูปภาพจาก ImgBB
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('อัปโหลดรูปภาพสำเร็จ')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('อัปโหลดรูปภาพล้มเหลว')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // 3. ส่งข้อมูลทั้งหมดไปยัง Backend (Node.js)
  Future<void> _submitMenu() async {
    if (_formKey.currentState!.validate() && _imageUrl != null) {
      try {
        final response = await http.post(
          Uri.parse(
            'http://your-nodejs-server.com/api/menus',
          ), // เปลี่ยนเป็น URL จริง
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'restaurantId': widget.restaurantId,
            'menuThaiName': _thaiNameController.text,
            'menuEnglishName': _englishNameController.text,
            'price': double.parse(_priceController.text),
            'menuImage': _imageUrl,
          }),
        );

        if (response.statusCode == 200) {
          Navigator.pop(context, true); // ส่งค่า true เพื่อ refresh หน้าหลัก
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('บันทึกข้อมูลล้มเหลว: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('เพิ่มเมนูใหม่')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // ชื่อเมนู (ไทย)
            TextFormField(
              controller: _thaiNameController,
              decoration: InputDecoration(labelText: 'ชื่อเมนู (ไทย)'),
              validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อเมนู' : null,
            ),
            // ชื่อเมนู (อังกฤษ)
            TextFormField(
              controller: _englishNameController,
              decoration: InputDecoration(labelText: 'ชื่อเมนู (อังกฤษ)'),
            ),
            // ราคา
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'ราคา'),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'กรุณากรอกราคา' : null,
            ),
            // เลือกรูปภาพ
            ElevatedButton(onPressed: _pickImage, child: Text('เลือกรูปภาพ')),
            // แสดงรูปภาพที่เลือก
            if (_imageFile != null) Image.file(_imageFile!, height: 100),
            // อัปโหลดรูปภาพ
            ElevatedButton(
              onPressed: _uploadImage,
              child: _isUploading
                  ? CircularProgressIndicator()
                  : Text('อัปโหลดรูปภาพ'),
            ),
            // ส่งข้อมูล
            ElevatedButton(onPressed: _submitMenu, child: Text('บันทึกเมนู')),
          ],
        ),
      ),
    );
  }
}
