import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class EditMenuPage extends StatefulWidget {
  final int menuId;
  final String currentThaiName;
  final String currentEnglishName;
  final String currentPrice;
  final String currentImageUrl;
  final int restaurantId;

  const EditMenuPage({
    Key? key,
    required this.menuId,
    required this.currentThaiName,
    required this.currentEnglishName,
    required this.currentPrice,
    required this.currentImageUrl,
    required this.restaurantId,
  }) : super(key: key);

  @override
  _EditMenuPageState createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  final Color _primaryColor = Color(0xFF8B5A2B);
  final Color _secondaryColor = Color(0xFFD2B48C);
  final Color _accentColor = Color(0xFFA67C52);
  final Color _backgroundColor = Color(0xFFF5F0E6);
  final Color _textColor = Color(0xFF5D4037);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _thaiNameController = TextEditingController();
  final TextEditingController _englishNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  // Cloudinary Configuration
  final String _cloudName = 'doyeaento'; // Replace with your Cloud Name
  final String _uploadPreset =
      'flutter_upload'; // Replace with your Upload Preset

  @override
  void initState() {
    super.initState();
    _thaiNameController.text = widget.currentThaiName;
    _englishNameController.text = widget.currentEnglishName;
    _priceController.text = widget.currentPrice;
    _imageUrl = widget.currentImageUrl;
  }

  @override
  void dispose() {
    _thaiNameController.dispose();
    _englishNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isUploading = true;
      });
      await _uploadToCloudinary();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('อัปโหลดรูปภาพสำเร็จ')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'อัปโหลดรูปภาพล้มเหลว: ${jsonResponse['error']?.toString() ?? 'Unknown error'}',
            ),
          ),
        );
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

  Future<void> _updateMenu() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/Edit/Menu/${widget.menuId}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'restaurantId': widget.restaurantId,
          'menuThaiName': _thaiNameController.text,
          'menuEnglishName': _englishNameController.text,
          'price': double.parse(_priceController.text),
          'menuImage': _imageUrl ?? widget.currentImageUrl,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปเดตเมนูล้มเหลว: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขเมนู', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFCEBFA3),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isSaving
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.save),
            onPressed: _isSaving ? null : _updateMenu,
          ),
        ],
      ),
      backgroundColor: _backgroundColor,
      body: _isSaving
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
                    Text(
                      'รูปภาพเมนู',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    SizedBox(height: 20),
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
                              onTap: _pickAndUploadImage,
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
                                    ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.file(
                                              _imageFile!,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          if (_isUploading)
                                            Container(
                                              color: Colors.black54,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              ),
                                            ),
                                        ],
                                      )
                                    : (_imageUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                _imageUrl!,
                                                width: double.infinity,
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
                                                  'แตะเพื่อเปลี่ยนรูปภาพเมนู',
                                                  style: TextStyle(
                                                    color: _textColor,
                                                  ),
                                                ),
                                              ],
                                            )),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_imageUrl != null && !_isUploading)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _imageFile != null
                              ? 'อัปโหลดรูปภาพเรียบร้อยแล้ว'
                              : 'รูปภาพปัจจุบัน',
                          style: TextStyle(color: Colors.green, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(height: 25),
                    _buildSectionTitle('ข้อมูลเมนู'),
                    _buildTextField(
                      controller: _thaiNameController,
                      label: 'ชื่อเมนู (ไทย)*',
                      icon: Icons.food_bank,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกชื่อเมนู';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _englishNameController,
                      label: 'ชื่อเมนู (อังกฤษ)',
                      icon: Icons.food_bank_outlined,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _priceController,
                      label: 'ราคา*',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกราคา';
                        }
                        if (double.tryParse(value) == null) {
                          return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _updateMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 77, 76, 75),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        'บันทึกการเปลี่ยนแปลง',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
      style: TextStyle(color: _textColor),
      inputFormatters: inputFormatters,
    );
  }
}
