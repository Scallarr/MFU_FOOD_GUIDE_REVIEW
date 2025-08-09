import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:myapp/admin/Home.dart' as home;

class EditRestaurant extends StatefulWidget {
  final int userId;
  final int restaurantId;
  final home.Restaurant currentData;

  const EditRestaurant({
    required this.userId,
    required this.restaurantId,
    required this.currentData,
    Key? key,
  }) : super(key: key);

  @override
  _EditRestaurantPageState createState() => _EditRestaurantPageState();
}

class _EditRestaurantPageState extends State<EditRestaurant> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _hoursController;
  late TextEditingController _phoneController;
  late TextEditingController _categoryController;
  String? _selectedLocation;
  String? _selectedCategory;
  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentData.name);
    _locationController = TextEditingController(
      text: widget.currentData.location,
    );
    _hoursController = TextEditingController(
      text: widget.currentData.operatingHours,
    );
    _phoneController = TextEditingController(
      text: widget.currentData.phoneNumber,
    );
    _categoryController = TextEditingController(
      text: widget.currentData.category,
    );
    _selectedLocation = widget.currentData.location;
    _selectedCategory = widget.currentData.category;
    _imageUrl = widget.currentData.photoUrl;
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

  Future<String?> _uploadImageToImgBB() async {
    if (_imageFile == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      // Read image file and convert to base64
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Upload to ImgBB
      final response = await http.post(
        Uri.parse(
          'https://api.imgbb.com/1/upload?key=762958d4dfc64c8a75fe00a0359c6b05',
        ),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final imageUrl = jsonData['data']['url'];

        setState(() {
          _imageUrl = imageUrl;
          _isUploading = false;
        });

        return imageUrl;
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      return null;
    }
  }

  Future<void> _updateRestaurant() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Upload new image if selected
        if (_imageFile != null) {
          final newImageUrl = await _uploadImageToImgBB();
          if (newImageUrl == null) return;
        }

        // Update restaurant data
        final response = await http.put(
          Uri.parse(
            'https://mfu-food-guide-review.onrender.com/edit/restaurants/${widget.restaurantId}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': widget.userId,
            'restaurant_name': _nameController.text,
            'location': _selectedLocation,
            'operating_hours': _hoursController.text,
            'phone_number': _phoneController.text,
            'category': _selectedCategory,
            'image_url': _imageUrl,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restaurant updated successfully')),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to update restaurant: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationOptions = [
      'D1',
      'E1',
      'E2',
      'C5',
      'S2',
      'M-SQUARE',
      'LAMDUAN',
    ];
    final categoryOptions = ['Main_dish', 'Snack', 'Drinks'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Restaurant'),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: _updateRestaurant),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image display and picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isUploading
                      ? Center(child: CircularProgressIndicator())
                      : _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : _imageUrl != null
                      ? Image.network(_imageUrl!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 50),
                            Text('Tap to select image'),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 16),
              Text('Tap image to change restaurant photo'),
              SizedBox(height: 24),

              // Restaurant name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Restaurant Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter restaurant name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Location dropdown
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: InputDecoration(labelText: 'Location'),
                items: locationOptions.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Operating hours field
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
              SizedBox(height: 16),

              // Phone number field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'Category'),
                items: categoryOptions.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select category';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Restaurant {
  final String name;
  final String location;
  final String operatingHours;
  final String phoneNumber;
  final String category;
  final String? photoUrl;

  Restaurant({
    required this.name,
    required this.location,
    required this.operatingHours,
    required this.phoneNumber,
    required this.category,
    this.photoUrl,
  });
}
