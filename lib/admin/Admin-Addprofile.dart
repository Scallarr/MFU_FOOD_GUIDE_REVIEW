import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AddProfilePage extends StatefulWidget {
  @override
  _AddProfilePageState createState() => _AddProfilePageState();
}

class _AddProfilePageState extends State<AddProfilePage> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Profile', style: TextStyle(color: Colors.white)),
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
      body: _isUploading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      'Profile Image',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    SizedBox(height: 20),

                    // Image Upload Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
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
                                  border: Border.all(
                                    color: _accentColor,
                                    width: 2,
                                  ),
                                ),
                                child: _imageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo,
                                            size: 50,
                                            color: _accentColor,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Tap to add profile photo',
                                            style: TextStyle(color: _textColor),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 25),

                    // Profile Name
                    _buildSectionTitle('Profile Information'),
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

                    // Description
                    _buildTextFieldWithCounter(
                      controller: _descriptionController,
                      label: 'Description*',
                      icon: Icons.description,
                      maxLines: 3,
                      maxLength: 100,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Required Coins
                    _buildTextFieldWithCounter(
                      controller: _requiredCoinsController,
                      label: 'Required Coins*',
                      icon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
                      maxLength: 7,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter required coins';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 25),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 77, 76, 75),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        'Add Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 233, 224, 224),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _primaryColor,
        ),
      ),
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
    if (_imageFile == null) {
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
      // First upload image to Cloudinary
      await _uploadToCloudinary();

      // Then insert data to database
      await _insertProfileToDatabase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile added successfully!'),
          backgroundColor: const Color.fromARGB(255, 22, 22, 22),
        ),
      );
      Navigator.pop(context, true);
      // Clear form after successful submission

      setState(() {
        _imageFile = null;
        _imageUrl = null;
      });
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

  Future<void> _insertProfileToDatabase() async {
    if (_imageUrl == null) {
      throw Exception('Image URL is required');
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.214.52.39:8080/Add/profiles'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'profileName': _profileNameController.text,
          'description': _descriptionController.text,
          'imageUrl': _imageUrl,
          'requiredCoins': int.parse(_requiredCoinsController.text),
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to insert profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Database insertion error: $e');
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
