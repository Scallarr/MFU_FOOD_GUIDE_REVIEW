// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:image_picker/image_picker.dart';
// // import 'dart:io';
// // import 'package:intl/intl.dart';
// // import 'package:flutter/services.dart';

// // class Addmenu extends StatefulWidget {
// //   final int restaurantId;

// //   const Addmenu({Key? key, required this.restaurantId}) : super(key: key);

// //   @override
// //   _AddmenuState createState() => _AddmenuState();
// // }

// // class _AddmenuState extends State<Addmenu> {
// //   final Color _primaryColor = Color(0xFF8B5A2B); // Rich brown
// //   final Color _secondaryColor = Color(0xFFD2B48C); // Tan
// //   final Color _accentColor = Color(0xFFA67C52); // Medium brown
// //   final Color _backgroundColor = Color(0xFFF5F0E6); // Cream
// //   final Color _textColor = Color(0xFF5D4037); // Dark brown

// //   final _formKey = GlobalKey<FormState>();
// //   final TextEditingController _thaiNameController = TextEditingController();
// //   final TextEditingController _englishNameController = TextEditingController();
// //   final TextEditingController _priceController = TextEditingController();

// //   File? _imageFile;
// //   String? _imageUrl;
// //   bool _isUploading = false;
// //   bool _isSaving = false;

// //   final ImagePicker _picker = ImagePicker();
// //   final String _imgbbApiKey = '762958d4dfc64c8a75fe00a0359c6b05';

// //   @override
// //   void dispose() {
// //     _thaiNameController.dispose();
// //     _englishNameController.dispose();
// //     _priceController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _pickAndUploadImage() async {
// //     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
// //     if (pickedFile != null) {
// //       setState(() {
// //         _imageFile = File(pickedFile.path);
// //         _isUploading = true;
// //       });
// //       await _uploadImage();
// //     }
// //   }

// //   Future<void> _uploadImage() async {
// //     try {
// //       final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey');
// //       final request = http.MultipartRequest('POST', uri);
// //       request.files.add(
// //         await http.MultipartFile.fromPath('image', _imageFile!.path),
// //       );

// //       final response = await request.send();
// //       final responseData = await response.stream.bytesToString();
// //       final jsonResponse = json.decode(responseData);

// //       if (jsonResponse['success'] == true) {
// //         setState(() {
// //           _imageUrl = jsonResponse['data']['url'];
// //         });
// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(SnackBar(content: Text('อัปโหลดรูปภาพสำเร็จ')));
// //       } else {
// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(SnackBar(content: Text('อัปโหลดรูปภาพล้มเหลว')));
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
// //     } finally {
// //       setState(() {
// //         _isUploading = false;
// //       });
// //     }
// //   }

// //   Future<void> _submitMenu() async {
// //     if (!_formKey.currentState!.validate()) return;
// //     if (_imageUrl == null) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('กรุณาเลือกรูปภาพ')));
// //       return;
// //     }

// //     setState(() {
// //       _isSaving = true;
// //     });

// //     try {
// //       final response = await http.post(
// //         Uri.parse('https://mfu-food-guide-review.onrender.com/Add/menus'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: json.encode({
// //           'restaurantId': widget.restaurantId,
// //           'menuThaiName': _thaiNameController.text,
// //           'menuEnglishName': _englishNameController.text,
// //           'price': double.parse(_priceController.text),
// //           'menuImage': _imageUrl,
// //         }),
// //       );

// //       if (response.statusCode == 200) {
// //         Navigator.pop(context, true);
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('บันทึกข้อมูลล้มเหลว: ${response.body}')),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
// //     } finally {
// //       setState(() {
// //         _isSaving = false;
// //       });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('เพิ่มเมนูใหม่', style: TextStyle(color: Colors.white)),
// //         backgroundColor: const Color(0xFFCEBFA3),
// //         iconTheme: IconThemeData(color: Colors.white),
// //         actions: [
// //           IconButton(
// //             icon: _isSaving
// //                 ? CircularProgressIndicator(color: Colors.white)
// //                 : Icon(Icons.save),
// //             onPressed: _isSaving ? null : _submitMenu,
// //           ),
// //         ],
// //       ),
// //       backgroundColor: _backgroundColor,
// //       body: _isSaving
// //           ? Center(
// //               child: CircularProgressIndicator(
// //                 valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
// //               ),
// //             )
// //           : SingleChildScrollView(
// //               padding: const EdgeInsets.all(20.0),
// //               child: Form(
// //                 key: _formKey,
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.stretch,
// //                   children: [
// //                     // Header
// //                     Text(
// //                       'รูปภาพเมนู',
// //                       style: TextStyle(
// //                         fontSize: 20,
// //                         fontWeight: FontWeight.bold,
// //                         color: _primaryColor,
// //                       ),
// //                       textAlign: TextAlign.start,
// //                     ),
// //                     SizedBox(height: 20),

// //                     // Image Upload Section
// //                     Card(
// //                       elevation: 4,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(15),
// //                       ),
// //                       child: Padding(
// //                         padding: const EdgeInsets.all(0.0),
// //                         child: Column(
// //                           children: [
// //                             GestureDetector(
// //                               onTap: _pickAndUploadImage,
// //                               child: Container(
// //                                 height: 220,
// //                                 width: double.infinity,
// //                                 decoration: BoxDecoration(
// //                                   color: _secondaryColor.withOpacity(0.3),
// //                                   borderRadius: BorderRadius.circular(12),
// //                                   border: Border.all(
// //                                     color: _accentColor,
// //                                     width: 2,
// //                                   ),
// //                                 ),
// //                                 child: _imageFile != null
// //                                     ? Stack(
// //                                         children: [
// //                                           ClipRRect(
// //                                             borderRadius: BorderRadius.circular(
// //                                               12,
// //                                             ),
// //                                             child: Image.file(
// //                                               _imageFile!,
// //                                               width: double.infinity,
// //                                               fit: BoxFit.cover,
// //                                             ),
// //                                           ),
// //                                           if (_isUploading)
// //                                             Container(
// //                                               color: Colors.black54,
// //                                               child: Center(
// //                                                 child: CircularProgressIndicator(
// //                                                   valueColor:
// //                                                       AlwaysStoppedAnimation<
// //                                                         Color
// //                                                       >(Colors.white),
// //                                                 ),
// //                                               ),
// //                                             ),
// //                                         ],
// //                                       )
// //                                     : Column(
// //                                         mainAxisAlignment:
// //                                             MainAxisAlignment.center,
// //                                         children: [
// //                                           Icon(
// //                                             Icons.add_a_photo,
// //                                             size: 50,
// //                                             color: _accentColor,
// //                                           ),
// //                                           SizedBox(height: 8),
// //                                           Text(
// //                                             'แตะเพื่อเพิ่มรูปภาพเมนู',
// //                                             style: TextStyle(color: _textColor),
// //                                           ),
// //                                         ],
// //                                       ),
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                     if (_imageUrl != null && !_isUploading)
// //                       Padding(
// //                         padding: const EdgeInsets.only(top: 8.0),
// //                         child: Text(
// //                           'อัปโหลดรูปภาพเรียบร้อยแล้ว',
// //                           style: TextStyle(color: Colors.green, fontSize: 14),
// //                           textAlign: TextAlign.center,
// //                         ),
// //                       ),
// //                     SizedBox(height: 25),

// //                     // Menu Information
// //                     _buildSectionTitle('ข้อมูลเมนู'),

// //                     // Thai Name
// //                     _buildTextField(
// //                       controller: _thaiNameController,
// //                       label: 'ชื่อเมนู (ไทย)*',
// //                       icon: Icons.food_bank,
// //                       validator: (value) {
// //                         if (value == null || value.isEmpty) {
// //                           return 'กรุณากรอกชื่อเมนู';
// //                         }
// //                         return null;
// //                       },
// //                     ),
// //                     SizedBox(height: 16),

// //                     // English Name
// //                     _buildTextField(
// //                       controller: _englishNameController,
// //                       label: 'ชื่อเมนู (อังกฤษ)',
// //                       icon: Icons.food_bank_outlined,
// //                     ),
// //                     SizedBox(height: 16),

// //                     // Price
// //                     _buildTextField(
// //                       controller: _priceController,
// //                       label: 'ราคา*',
// //                       icon: Icons.attach_money,
// //                       keyboardType: TextInputType.numberWithOptions(
// //                         decimal: true,
// //                       ),
// //                       inputFormatters: [
// //                         FilteringTextInputFormatter.allow(
// //                           RegExp(r'^\d+\.?\d{0,2}'),
// //                         ),
// //                       ],
// //                       validator: (value) {
// //                         if (value == null || value.isEmpty) {
// //                           return 'กรุณากรอกราคา';
// //                         }
// //                         if (double.tryParse(value) == null) {
// //                           return 'กรุณากรอกตัวเลขที่ถูกต้อง';
// //                         }
// //                         return null;
// //                       },
// //                     ),
// //                     SizedBox(height: 30),

// //                     // Submit Button
// //                     ElevatedButton(
// //                       onPressed: _submitMenu,
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Color.fromARGB(255, 77, 76, 75),
// //                         padding: EdgeInsets.symmetric(vertical: 16),
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                         ),
// //                         elevation: 3,
// //                       ),
// //                       child: Text(
// //                         'บันทึกเมนู',
// //                         style: TextStyle(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.w600,
// //                           color: const Color.fromARGB(255, 233, 224, 224),
// //                         ),
// //                       ),
// //                     ),
// //                     SizedBox(height: 20),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //     );
// //   }

// //   Widget _buildSectionTitle(String title) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 12.0),
// //       child: Text(
// //         title,
// //         style: TextStyle(
// //           fontSize: 18,
// //           fontWeight: FontWeight.w600,
// //           color: _primaryColor,
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildTextField({
// //     required TextEditingController controller,
// //     required String label,
// //     required IconData icon,
// //     TextInputType? keyboardType,
// //     String? Function(String?)? validator,
// //     List<TextInputFormatter>? inputFormatters,
// //   }) {
// //     return TextFormField(
// //       controller: controller,
// //       decoration: InputDecoration(
// //         labelText: label,
// //         labelStyle: TextStyle(color: _textColor),
// //         border: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(10),
// //           borderSide: BorderSide(color: _accentColor),
// //         ),
// //         enabledBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(10),
// //           borderSide: BorderSide(color: _accentColor),
// //         ),
// //         focusedBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(10),
// //           borderSide: BorderSide(color: _primaryColor, width: 2),
// //         ),
// //         prefixIcon: Icon(icon, color: _accentColor),
// //         filled: true,
// //         fillColor: Colors.white,
// //       ),
// //       keyboardType: keyboardType,
// //       validator: validator,
// //       style: TextStyle(color: _textColor),
// //       inputFormatters: inputFormatters,
// //     );
// //   }
// // }










//   Future<void> _uploadImage() async {
//     if (_imageFile == null) return;

//     setState(() {
//       _isUploading = true;
//     });

//     try {
//       // สร้าง unique ID สำหรับรูปภาพ
//       final imageId = 'restaurant_${DateTime.now().millisecondsSinceEpoch}';

//       // สร้าง request ไปยัง Cloudflare Images API
//       final uri = Uri.parse(
//         'https://api.cloudflare.com/client/v4/accounts/$_cloudflareAccountId/images/v1',
//       );

//       var request = http.MultipartRequest('POST', uri)
//         ..headers['Authorization'] = 'Bearer $_cloudflareApiToken'
//         ..fields['id'] = imageId
//         ..fields['requireSignedURLs'] = 'false'
//         ..files.add(await http.MultipartFile.fromPath(
//           'file',
//           _imageFile!.path,
//         ));

//       var response = await request.send();
//       var responseData = await response.stream.bytesToString();
//       var jsonResponse = json.decode(responseData);

//       if (jsonResponse['success'] == true) {
//         // สร้าง URL รูปภาพจาก Cloudflare
//         setState(() {
//           _imageUrl = 'https://imagedelivery.net/$_cloudflareImagesHash/$imageId/public';
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Image uploaded successfully')),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to upload image: ${jsonResponse['errors']?.first['message'] ?? 'Unknown error'})),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error uploading image: $e')),
//       );
//     } finally {
//       setState(() {
//         _isUploading = false;
//       }