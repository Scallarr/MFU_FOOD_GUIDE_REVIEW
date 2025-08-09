import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/admin/Home.dart';

class EditRestaurant extends StatefulWidget {
  final int userId;
  final int restaurantId;
  final Restaurant currentData;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _hoursController.dispose();
    _phoneController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _updateRestaurant() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.put(
          Uri.parse(
            'https://mfu-food-guide-review.onrender.com/restaurants/${widget.restaurantId}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': widget.userId,
            'restaurant_name': _nameController.text,
            'location': _selectedLocation,
            'operating_hours': _hoursController.text,
            'phone_number': _phoneController.text,
            'category': _selectedCategory,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('อัพเดทร้านอาหารสำเร็จ')));
          Navigator.pop(context, true); // ส่งค่า true กลับเพื่ออัพเดทหน้าเดิม
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.body}')),
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
        title: Text('แก้ไขร้านอาหาร'),
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'ชื่อร้าน'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อร้าน';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: InputDecoration(labelText: 'สถานที่'),
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
                    return 'กรุณาเลือกสถานที่';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _hoursController,
                decoration: InputDecoration(labelText: 'เวลาทำการ'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเวลาทำการ';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'เบอร์โทรศัพท์'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเบอร์โทรศัพท์';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'ประเภทอาหาร'),
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
                    return 'กรุณาเลือกประเภทอาหาร';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              // ปุ่มอัพโหลดรูปภาพ (สามารถเพิ่มได้ในอนาคต)
            ],
          ),
        ),
      ),
    );
  }
}
