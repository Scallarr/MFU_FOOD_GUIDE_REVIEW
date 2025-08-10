import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AddProfilePage extends StatefulWidget {
  @override
  _AddProfilePageState createState() => _AddProfilePageState();
}

class _AddProfilePageState extends State<AddProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _requiredCoinsController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;

  // Cloudinary configuration
  final String _cloudName = 'your_cloud_name';
  final String _uploadPreset = 'your_upload_preset';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Image Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : _imageUrl != null
                      ? Image.network(_imageUrl!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tap to add profile image',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 20),

              // Profile Name Field
              TextFormField(
                controller: _profileNameController,
                decoration: InputDecoration(
                  labelText: 'Profile Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter profile name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),

              // Required Coins Field
              TextFormField(
                controller: _requiredCoinsController,
                decoration: InputDecoration(
                  labelText: 'Required Coins',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.number,
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
                onPressed: _isUploading ? null : _submitForm,
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Add Profile'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select an image')));
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile added successfully!')));

      // Clear form after successful submission
      _formKey.currentState!.reset();
      setState(() {
        _imageFile = null;
        _imageUrl = null;
      });
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
        Uri.parse('https://mfu-food-guide-review.onrender.com/Add/profiles'),
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
