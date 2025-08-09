import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddRestaurantPage extends StatefulWidget {
  final int userId;

  const AddRestaurantPage({Key? key, required this.userId}) : super(key: key);

  @override
  _AddRestaurantPageState createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCategory = 'Main_dish';
  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;

  final List<String> _categories = ['Main_dish', 'Snack', 'Drinks'];
  final ImagePicker _picker = ImagePicker();
  final String _imgbbApiKey = '762958d4dfc64c8a75fe00a0359c6b05';

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _hoursController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

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
          _imageUrl = jsonResponse['data']['url'];
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _addRestaurant() async {
    if (_formKey.currentState!.validate()) {
      if (_imageUrl == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please upload an image')));
        return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://mfu-food-guide-review.onrender.com/restaurants'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'restaurant_name': _nameController.text,
            'location': _locationController.text,
            'operating_hours': _hoursController.text,
            'phone_number': _phoneController.text,
            'photos': _imageUrl,
            'category': _selectedCategory,
            'added_by': widget.userId,
          }),
        );

        if (response.statusCode == 201) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to add restaurant')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Restaurant'),
        actions: [
          IconButton(
            icon: _isUploading
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.save),
            onPressed: _isUploading ? null : _addRestaurant,
          ),
        ],
      ),
      body: _isUploading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Image Upload Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 50),
                                  SizedBox(height: 8),
                                  Text('Tap to add restaurant photo'),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Form Fields
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Restaurant Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location (e.g., D1)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _hoursController,
                      decoration: InputDecoration(labelText: 'Operating Hours'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter operating hours';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.replaceAll('_', ' ')),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Category'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
