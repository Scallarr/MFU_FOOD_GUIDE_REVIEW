import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:myapp/admin/Admin-Home.dart' as home;

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
  final Color _primaryColor = Color(0xFF8B5A2B);
  final Color _secondaryColor = Color(0xFFD2B48C);
  final Color _accentColor = Color(0xFFA67C52);
  final Color _backgroundColor = Color(0xFFF5F0E6);
  final Color _textColor = Color(0xFF5D4037);

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _selectedCategory = 'Main_dish';
  String _selectedLocation = 'D1';
  String _selectedCuisine = 'OTHER';
  String? _selectedRegion;
  String _selectedDietType = 'GENERAL';
  String _selectedRestaurantType = 'Restaurant';
  String _selectedServiceType = 'Dine-in';
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;

  final List<String> _categories = ['Main_dish', 'Snack', 'Drinks'];
  final List<String> _locations = [
    'D1',
    'E1',
    'E2',
    'C5',
    'S2',
    'M-SQUARE',
    'LAMDUAN',
  ];
  final List<String> _cuisines = [
    'THAI',
    'CHINESE',
    'JAPANESE',
    'KOREAN',
    'INDIAN',
    'ITALIAN',
    'FRENCH',
    'MEXICAN',
    'AMERICAN',
    'VIETNAMESE',
    'OTHER',
  ];
  final List<String> _regions = [
    'NORTH',
    'CENTRAL',
    'NORTHEAST',
    'SOUTH',
    'EAST',
    'WEST',
  ];
  final List<String> _dietTypes = ['HALAL', 'VEGETARIAN', 'GENERAL'];
  final List<String> _restaurantTypes = [
    'Cafeteria',
    'Mini-Mart',
    'Cafe',
    'Restaurant',
  ];
  final List<String> _serviceTypes = ['Delivery', 'Dine-in', 'All'];

  final ImagePicker _picker = ImagePicker();
  final String _cloudName = 'doyeaento';
  final String _uploadPreset = 'flutter_upload';

  // ไอคอนสำหรับแต่ละประเทศ
  final Map<String, String> _cuisineFlagAssets = {
    'THAI': 'assets/icons/flags/th.png',
    'CHINESE': 'assets/icons/flags/ch.png',
    'JAPANESE': 'assets/icons/flags/jp.png',
    'KOREAN': 'assets/icons/flags/kr.png',
    'INDIAN': 'assets/icons/flags/in.png',
    'ITALIAN': 'assets/icons/flags/it.png',
    'FRENCH': 'assets/icons/flags/fr.png',
    'MEXICAN': 'assets/icons/flags/mx.png',
    'AMERICAN': 'assets/icons/flags/us.png',
    'VIETNAMESE': 'assets/icons/flags/vn.png',
    'OTHER': 'assets/icons/flags/world.png',
  };

  // ไอคอนสำหรับแต่ละภูมิภาคไทย
  final Map<String, IconData> _regionIcons = {
    'NORTH': Icons.terrain,
    'CENTRAL': Icons.location_city,
    'NORTHEAST': Icons.agriculture,
    'SOUTH': Icons.beach_access,
    'EAST': Icons.waves,
    'WEST': Icons.forest,
  };

  // ไอคอนสำหรับประเภทอาหาร
  final Map<String, IconData> _dietTypeIcons = {
    'HALAL': Icons.mosque_outlined,
    'VEGETARIAN': Icons.eco_outlined,
    'GENERAL': Icons.restaurant_outlined,
  };

  // ไอคอนสำหรับประเภทร้านอาหาร
  final Map<String, IconData> _restaurantTypeIcons = {
    'Cafeteria': Icons.school_outlined,
    'Mini-Mart': Icons.store_mall_directory_outlined,
    'Cafe': Icons.local_cafe_outlined,
    'Restaurant': Icons.restaurant_menu_outlined,
  };

  // ไอคอนสำหรับประเภทบริการ
  final Map<String, IconData> _serviceTypeIcons = {
    'Delivery': Icons.delivery_dining,
    'Dine-in': Icons.chair_outlined,
    'All': Icons.all_inclusive_outlined,
  };

  // ไอคอนสำหรับประเภทอาหาร
  final Map<String, IconData> _categoryIcons = {
    'Main_dish': Icons.lunch_dining_outlined,
    'Snack': Icons.local_cafe_outlined,
    'Drinks': Icons.local_bar_outlined,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentData.name);
    _phoneController = TextEditingController(
      text: widget.currentData.phoneNumber,
    );
    _selectedCategory = widget.currentData.category;
    _selectedLocation = widget.currentData.location;
    _imageUrl = widget.currentData.photoUrl;

    // Parse ข้อมูลเพิ่มเติมจาก currentData (หากมี)
    _selectedCuisine = widget.currentData.cuisineByNation ?? 'OTHER';
    _selectedRegion = widget.currentData.region;
    _selectedDietType = widget.currentData.dietType ?? 'GENERAL';
    _selectedRestaurantType = widget.currentData.restaurantType ?? 'Restaurant';
    _selectedServiceType = widget.currentData.serviceType ?? 'Dine-in';

    // Parse operating hours
    if (widget.currentData.operatingHours.contains('-')) {
      final hours = widget.currentData.operatingHours.split('-');
      if (hours.length == 2) {
        _openingTime = _parseTime(hours[0]);
        _closingTime = _parseTime(hours[1]);
      }
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final format = DateFormat('HH:mm');
      final dateTime = format.parse(timeStr);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      return TimeOfDay(hour: 8, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      await _uploadToCloudinary();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image uploaded successfully')));
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

  Future<void> _selectOpeningTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _openingTime ?? TimeOfDay(hour: 8, minute: 0),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: _primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (_closingTime != null &&
          (picked.hour > _closingTime!.hour ||
              (picked.hour == _closingTime!.hour &&
                  picked.minute >= _closingTime!.minute))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Closing time must be after opening time')),
        );
        return;
      }

      setState(() {
        _openingTime = picked;
      });
    }
  }

  Future<void> _selectClosingTime() async {
    if (_openingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select opening time first')),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          _closingTime ??
          TimeOfDay(hour: _openingTime!.hour + 4, minute: _openingTime!.minute),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: _primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (picked.hour < _openingTime!.hour ||
          (picked.hour == _openingTime!.hour &&
              picked.minute <= _openingTime!.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Closing time must be after opening time')),
        );
        return;
      }

      setState(() {
        _closingTime = picked;
      });
    }
  }

  Future<void> _updateRestaurant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_openingTime == null || _closingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select opening and closing times')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryColor, width: 2),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      color: _primaryColor,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Confirm Restaurant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _secondaryColor, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        Icons.badge,
                        'Name',
                        _nameController.text,
                      ),
                      _buildDetailRow(
                        Icons.location_on,
                        'Location',
                        _selectedLocation,
                      ),
                      _buildDetailRow(
                        Icons.category,
                        'Category',
                        _selectedCategory.replaceAll('_', ' '),
                      ),
                      _buildDetailRow(
                        Icons.restaurant_menu,
                        'Cuisine',
                        _selectedCuisine,
                      ),
                      if (_selectedRegion != null)
                        _buildDetailRow(Icons.map, 'Region', _selectedRegion!),
                      _buildDetailRow(
                        Icons.food_bank,
                        'Diet Type',
                        _selectedDietType,
                      ),
                      _buildDetailRow(
                        Icons.store,
                        'Restaurant Type',
                        _selectedRestaurantType,
                      ),
                      _buildDetailRow(
                        Icons.delivery_dining,
                        'Service Type',
                        _selectedServiceType,
                      ),
                      _buildDetailRow(
                        Icons.access_time,
                        'Hours',
                        _formatTimeRange(),
                      ),
                      _buildDetailRow(
                        Icons.phone,
                        'Phone',
                        _phoneController.text,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: _primaryColor),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Update',
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
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
          'http://172.22.173.39:8080/edit/restaurants/${widget.restaurantId}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'restaurant_name': _nameController.text,
          'location': _selectedLocation,
          'operating_hours': _formatTimeRange(),
          'phone_number': _phoneController.text,
          'category': _selectedCategory,
          'cuisine_by_nation': _selectedCuisine,
          'region': _selectedRegion,
          'diet_type': _selectedDietType,
          'restaurant_type': _selectedRestaurantType,
          'service_type': _selectedServiceType,
          'image_url': _imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restaurant updated successfully!'),
            backgroundColor: const Color.fromARGB(255, 13, 13, 13),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update restaurant: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  String _formatTimeRange() {
    final opening = _openingTime!;
    final closing = _closingTime!;
    return '${_formatTime(opening)}-${_formatTime(closing)}';
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF8B5A2B), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Restaurant', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFCEBFA3),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isUploading
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.save),
            onPressed: _isUploading ? null : _updateRestaurant,
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
                    Text(
                      'Restaurant Image',
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit
                                        .expand, // ทำให้ child ทั้งหมดเต็ม container
                                    children: [
                                      // รูปภาพ
                                      if (_imageFile != null)
                                        Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        )
                                      else if (_imageUrl != null)
                                        Image.network(
                                          _imageUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      else
                                        Container(
                                          color: _secondaryColor.withOpacity(
                                            0.3,
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.add_a_photo,
                                                  size: 50,
                                                  color: _accentColor,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Tap to add restaurant photo',
                                                  style: TextStyle(
                                                    color: _textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // Overlay
                                      Container(
                                        color: Colors.black.withOpacity(0.3),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.camera_alt,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Tap to change photo',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 25),
                    _buildSectionTitle('Basic Information'),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Restaurant Name*',
                      icon: Icons.restaurant,
                      maxLength: 20,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter a name';
                        if (value.length > 20)
                          return 'Name must be 20 characters or less';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedLocation,
                      items: _locations,
                      label: 'Location *',
                      icon: Icons.location_on,
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value!;
                        });
                      },
                      itemBuilder: (item) => Text(item),
                    ),
                    SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedCategory,
                      items: _categories,
                      label: 'Category *',
                      icon: Icons.category,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                      itemBuilder: (item) => Row(
                        children: [
                          Icon(
                            _categoryIcons[item] ?? Icons.category,
                            size: 20,
                            color: _accentColor,
                          ),
                          SizedBox(width: 8),
                          Text(item.replaceAll('_', ' ')),
                        ],
                      ),
                      selectedItemBuilder: (item) =>
                          Text(item.replaceAll('_', ' ')),
                    ),
                    SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedCuisine,
                      items: _cuisines,
                      label: 'Cuisine',
                      icon: Icons.restaurant_menu,
                      onChanged: (value) {
                        setState(() {
                          _selectedCuisine = value!;
                          if (value != 'THAI') {
                            _selectedRegion = null;
                          }
                        });
                      },
                      itemBuilder: (item) => Row(
                        children: [
                          Image.asset(
                            _cuisineFlagAssets[item] ??
                                'assets/icons/flags/world.png',
                            width: 24,
                            height: 16,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.flag_outlined,
                              size: 20,
                              color: _accentColor,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(item),
                        ],
                      ),
                      selectedItemBuilder: (item) => Row(
                        children: [
                          Image.asset(
                            _cuisineFlagAssets[item] ??
                                'assets/icons/flags/world.png',
                            width: 24,
                            height: 16,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.flag_outlined,
                              size: 20,
                              color: _accentColor,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(item),
                        ],
                      ),
                    ),
                    if (_selectedCuisine == 'THAI') ...[
                      SizedBox(height: 16),
                      _buildDropdown(
                        value: _selectedRegion,
                        items: _regions,
                        label: 'Region (Only for Thai Cuisine)',
                        icon: Icons.map,
                        onChanged: (value) {
                          setState(() {
                            _selectedRegion = value;
                          });
                        },
                        isRequired: false, // ตั้งค่าเป็น false เพราะไม่บังคับ
                        itemBuilder: (item) => Row(
                          children: [
                            Icon(
                              _regionIcons[item] ?? Icons.map,
                              size: 20,
                              color: _accentColor,
                            ),
                            SizedBox(width: 8),
                            Text(item),
                          ],
                        ),
                        selectedItemBuilder: (item) => Text(item),
                      ),
                    ],
                    SizedBox(height: 24),
                    _buildSectionTitle('Additional Information'),
                    SizedBox(height: 12),
                    _buildDropdown(
                      value: _selectedDietType,
                      items: _dietTypes,
                      label: 'Diet Type',
                      icon: Icons.food_bank,
                      onChanged: (value) {
                        setState(() {
                          _selectedDietType = value!;
                        });
                      },
                      itemBuilder: (item) => Row(
                        children: [
                          Icon(
                            _dietTypeIcons[item] ?? Icons.food_bank,
                            size: 20,
                            color: _accentColor,
                          ),
                          SizedBox(width: 8),
                          Text(item),
                        ],
                      ),
                      selectedItemBuilder: (item) => Text(item),
                    ),
                    SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedRestaurantType,
                      items: _restaurantTypes,
                      label: 'Restaurant Type',
                      icon: Icons.store,
                      onChanged: (value) {
                        setState(() {
                          _selectedRestaurantType = value!;
                        });
                      },
                      itemBuilder: (item) => Row(
                        children: [
                          Icon(
                            _restaurantTypeIcons[item] ?? Icons.store,
                            size: 20,
                            color: _accentColor,
                          ),
                          SizedBox(width: 8),
                          Text(item),
                        ],
                      ),
                      selectedItemBuilder: (item) => Text(item),
                    ),
                    SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedServiceType,
                      items: _serviceTypes,
                      label: 'Service Type',
                      icon: Icons.delivery_dining,
                      onChanged: (value) {
                        setState(() {
                          _selectedServiceType = value!;
                        });
                      },
                      itemBuilder: (item) => Row(
                        children: [
                          Icon(
                            _serviceTypeIcons[item] ?? Icons.delivery_dining,
                            size: 20,
                            color: _accentColor,
                          ),
                          SizedBox(width: 8),
                          Text(item),
                        ],
                      ),
                      selectedItemBuilder: (item) => Text(item),
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      label: 'Phone Number*',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter a phone number';
                        if (value.length > 10 || value.length < 9)
                          return 'Phone number must be 9-10 digits';
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    _buildSectionTitle('Operating Hours'),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeButton(
                            text: _openingTime != null
                                ? 'Open: ${_formatTime(_openingTime!)}'
                                : 'Opening Time',
                            onPressed: _selectOpeningTime,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeButton(
                            text: _closingTime != null
                                ? 'Close: ${_formatTime(_closingTime!)}'
                                : 'Closing Time',
                            onPressed: _selectClosingTime,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _updateRestaurant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 77, 76, 75),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        'Update Restaurant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    int? maxLength,
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
      maxLength: maxLength,
      style: TextStyle(color: _textColor),
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildDropdown({
    required dynamic value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
    Widget Function(String)? itemBuilder,
    Widget Function(String)? selectedItemBuilder,
    bool isRequired = true,
  }) {
    // ตรวจสอบและจัดการค่า value ที่เป็น null หรือ empty string
    String? currentValue;
    if (value != null && value.toString().isNotEmpty && items.contains(value)) {
      currentValue = value;
    } else if (isRequired && items.isNotEmpty) {
      currentValue = items.first;
    } else {
      currentValue = null;
    }

    return DropdownButtonFormField<String>(
      value: currentValue,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: itemBuilder != null ? itemBuilder(item) : Text(item),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return items.map((item) {
          if (selectedItemBuilder != null) return selectedItemBuilder(item);
          return Text(item);
        }).toList();
      },
      onChanged: onChanged,
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
      style: TextStyle(color: _textColor),
      dropdownColor: _backgroundColor,
      icon: Icon(Icons.arrow_drop_down, color: _accentColor),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) return 'กรุณาเลือก $label';
              return null;
            }
          : null,
    );
  }

  Widget _buildTimeButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: _accentColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white,
      ),
      child: Text(text, style: TextStyle(color: _textColor, fontSize: 15)),
    );
  }
}
