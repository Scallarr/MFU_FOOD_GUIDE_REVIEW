import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfilePage({Key? key, required this.profile}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Color _primaryColor = Color(0xFF8B5A2B); // Rich brown
  final Color _secondaryColor = Color(0xFFD2B48C); // Tan
  final Color _accentColor = Color(0xFFA67C52); // Medium brown
  final Color _backgroundColor = Color(0xFFF5F0E6); // Cream
  final Color _textColor = Color(0xFF5D4037); // Dark brown

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _requiredCoinsController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Cloudinary configuration
  final String _cloudName = 'doyeaento';
  final String _uploadPreset = 'flutter_upload';

  @override
  void initState() {
    super.initState();
    _profileNameController.text = widget.profile['name'];
    _descriptionController.text = widget.profile['description'];
    _requiredCoinsController.text = widget.profile['coins'].toString();
    _imageUrl = widget.profile['image'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFCEBFA3),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isUploading
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.save),
            onPressed: _isUploading ? null : _submitForm,
          ),
        ],
      ),
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Profile Image'),
              SizedBox(height: 12),
              _buildImageUploadSection(),
              SizedBox(height: 25),
              _buildSectionTitle('Profile Information'),
              SizedBox(height: 12),
              _buildTextFieldWithCounter(
                controller: _profileNameController,
                label: 'Profile Name*',
                icon: Icons.person,
                maxLength: 15,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter profile name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildTextFieldWithCounter(
                controller: _descriptionController,
                label: 'Description*',
                icon: Icons.description,
                maxLines: 3,
                maxLength: 100, // กำหนดความยาวสูงสุดสำหรับ description
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildTextFieldWithCounter(
                controller: _requiredCoinsController,
                label: 'Required Coins*',
                icon: Icons.monetization_on,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // อนุญาตเฉพาะตัวเลข
                ],
                maxLength: 7,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter required coins';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a positive number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              _buildUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _primaryColor,
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _secondaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accentColor, width: 2),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : _imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_imageUrl!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: _accentColor,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to change profile image',
                            style: TextStyle(color: _textColor),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _accentColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _accentColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        prefixIcon: Icon(icon, color: _accentColor),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(color: _textColor),
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildTextFieldWithCounter({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _textColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _accentColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _accentColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            prefixIcon: Icon(icon, color: _accentColor),
            filled: true,
            fillColor: Colors.white,
            counterText: '', // ซ่อน counter เริ่มต้น
          ),
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(color: _textColor),
          inputFormatters: inputFormatters,
          onChanged: (value) {
            setState(() {}); // อัพเดต UI เมื่อพิมพ์ข้อความ
          },
        ),
        SizedBox(height: 4),
        // แสดงตัวนับตัวอักษรแบบกำหนดเอง
        Text(
          '${controller.text.length}/$maxLength ',
          style: TextStyle(
            fontSize: 12,
            color: controller.text.length >= maxLength!
                ? const Color.fromARGB(255, 250, 12, 12)
                : _textColor.withOpacity(1),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder(
                    duration: Duration(milliseconds: 300),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 40,
                            color: const Color.fromARGB(255, 255, 9, 9),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Confirm Changes',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Are you sure you want to apply these profile changes?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.7),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.7),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        if (confirm == true) {
          _submitForm(); // ฟังก์ชันของคุณสำหรับอัปเดตข้อมูลโปรไฟล์
        }
      },

      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 77, 76, 75),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      child: Text(
        'Update Profile',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(255, 233, 224, 224),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      if (_imageFile != null) {
        await _uploadToCloudinary();
      }

      await _updateProfileInDatabase();

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Profile updated successfully!'),
      //     backgroundColor: Color.fromARGB(255, 22, 22, 22),
      //   ),
      // );
      // Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadToCloudinary() async {
    try {
      if (_imageFile == null) return;

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      var request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
          await http.MultipartFile.fromPath('file', _imageFile!.path),
        );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (jsonResponse['secure_url'] != null) {
        setState(() {
          _imageUrl = jsonResponse['secure_url'];
        });
      } else {
        throw Exception(
          'Upload failed: ${jsonResponse['error']?.toString() ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Image upload error: $e');
    }
  }

  Future<void> _updateProfileInDatabase() async {
    try {
      final response = await http.put(
        Uri.parse(
          'http://172.22.173.39:8080/api/profiles/${widget.profile['id']}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'profileName': _profileNameController.text,
          'description': _descriptionController.text,
          'imageUrl': _imageUrl ?? widget.profile['image'],
          'requiredCoins': int.parse(_requiredCoinsController.text),
        }),
      );

      if (response.statusCode == 409) {
        final data = json.decode(response.body);
        final errorMsg = data['error'] ?? 'Username already exists';

        // คืนค่ากลับไปเป็น username เก่า

        await showDialog(
          context: context,
          barrierDismissible: false, // กดนอก dialog ไม่ปิด
          builder: (BuildContext dialogContext) {
            // ใช้ dialogContext แยกจาก context ภายนอก
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 10,
              backgroundColor: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(66, 94, 81, 81),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Update Fail!',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMsg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(
                            dialogContext,
                          ).pop(); // ใช้ dialogContext ปิดเฉพาะ dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                          shadowColor: const Color.fromARGB(
                            255,
                            0,
                            0,
                            0,
                          ).withOpacity(0.6),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (response.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update Profile Successfull'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      throw Exception('Database update error: $e');
    }
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    _requiredCoinsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
