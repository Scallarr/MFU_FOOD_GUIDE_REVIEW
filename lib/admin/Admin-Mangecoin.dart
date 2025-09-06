import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdminCoinManagementPage extends StatefulWidget {
  const AdminCoinManagementPage({super.key});

  @override
  State<AdminCoinManagementPage> createState() =>
      _AdminCoinManagementPageState();
}

class _AdminCoinManagementPageState extends State<AdminCoinManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _coinsController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  List<dynamic> _searchResults = [];
  Map<String, dynamic>? _selectedUser;
  bool _isLoading = false;
  String _actionType = 'ADD';

  // Colors
  final Color _primaryColor = Color(0xFF8B5A2B); // Rich brown
  final Color _secondaryColor = Color(0xFFD2B48C); // Tan
  final Color _accentColor = Color(0xFFA67C52); // Medium brown
  final Color _backgroundColor = Color(0xFFF5F0E6); // Cream
  final Color _textColor = Color(0xFF202124);
  final Color _secondaryTextColor = Color(0xFF5F6368);
  final Color _successColor = Color(0xFF34A853); // Green
  final Color _errorColor = Color(0xFFEA4335); // Red

  @override
  void dispose() {
    _searchController.dispose();
    _coinsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('http://10.0.3.201:8080/admin/search-users?query=$query'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['users'] ?? [];
        });
      }
    } catch (e) {
      print('Error searching users: $e');
    }
  }

  Future<void> _manageCoins() async {
    if (_selectedUser == null) {
      _showError('Please select a user');
      return;
    }

    final coinsAmount = int.tryParse(_coinsController.text);
    if (coinsAmount == null || coinsAmount <= 0) {
      _showError('Please enter a valid coins amount');
      return;
    }

    // if (_reasonController.text.isEmpty) {
    //   _showError('Please enter a reason');
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse('http://10.0.3.201:8080/admin/manage-coins'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'targetUserId': _selectedUser!['User_ID'],
          'actionType': _actionType,
          'coinsAmount': coinsAmount,
          'reason': _reasonController.text.isNotEmpty
              ? _reasonController.text
              : '-',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _showSuccess(
          'Coins ${_actionType == 'ADD' ? 'added' : 'subtracted'} successfully',
        );

        // Reset form
        _coinsController.clear();
        _reasonController.clear();
        setState(() {
          _selectedUser = null;
        });
      } else {
        final error = json.decode(response.body);
        _showError(error['message'] ?? 'Failed to manage coins');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Coin Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        toolbarHeight: 70,
        backgroundColor: const Color(0xFFCEBFA3),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Refresh the previous page and go back
            Navigator.pop(
              context,
              true,
            ); // 'true' indicates a refresh is needed
          },
        ),
        elevation: 0,
      ),
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: 25,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Section
              Text(
                'Search User',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by username or email or User ID',
                  labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
                  prefixIcon: Icon(Icons.search, color: _accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accentColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _searchUsers,
              ),
              SizedBox(height: 16),
              if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 48,
                        color: _errorColor.withOpacity(0.8),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'User Not Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _textColor.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try searching with a different username or email.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

              // Search Results
              if (_searchResults.isNotEmpty)
                Container(
                  constraints: BoxConstraints(
                    maxHeight: 620, // สูงสุด ไม่จำเป็นต้องกำหนดค่าคงที่
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryColor.withOpacity(0.1),
                              _secondaryColor.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: _primaryColor,
                            backgroundImage:
                                user['picture_url'] != null &&
                                    user['picture_url'].isNotEmpty
                                ? NetworkImage(user['picture_url'])
                                : null,
                            child:
                                (user['picture_url'] == null ||
                                    user['picture_url'].isEmpty)
                                ? Text(
                                    user['username'][0].toUpperCase(),
                                    style: TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),
                          title: Text(
                            user['username'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                user['email'],
                                style: TextStyle(
                                  color: _textColor.withOpacity(0.8),
                                  fontSize: 11.5,
                                ),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    size: 16,
                                    color: Colors.red.withOpacity(0.9),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${user['coins']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedUser = user;
                              _searchController.clear();
                              _searchResults = [];
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

              // Selected User
              if (_selectedUser != null) ...[
                SizedBox(height: 20),
                Text(
                  'Selected User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 12),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: _primaryColor,
                      backgroundImage:
                          _selectedUser!['picture_url'] != null &&
                              _selectedUser!['picture_url'].isNotEmpty
                          ? NetworkImage(
                              _selectedUser!['picture_url'],
                            ) // ใช้รูปจาก URL
                          : null,
                      child:
                          (_selectedUser!['picture_url'] == null ||
                              _selectedUser!['picture_url'].isEmpty)
                          ? Text(
                              _selectedUser!['username'][0].toUpperCase(),
                              style: TextStyle(color: Colors.white),
                            )
                          : null, // ถ้ามีรูปไม่ต้องแสดงตัวอักษร
                    ),
                    title: Text(
                      _selectedUser!['username'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedUser!['email'],
                          style: TextStyle(fontSize: 10),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 16,
                              color: Colors.red.withOpacity(0.9),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${_selectedUser!['coins']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close, color: _errorColor),
                      onPressed: () {
                        setState(() {
                          _selectedUser = null;
                        });
                      },
                    ),
                  ),
                ),
              ],

              // Action Form
              SizedBox(height: 24),
              Text(
                'Coin Action',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black26,
                      child: Container(
                        height: 70, // เพิ่มความสูงให้ใหญ่ขึ้น
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              _successColor.withOpacity(0.6),
                              _successColor.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: RadioListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),

                          title: Text(
                            'Award ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: 'ADD',
                          groupValue: _actionType,
                          activeColor: _successColor,
                          onChanged: (value) {
                            setState(() {
                              _actionType = value.toString();
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black26,
                      child: Container(
                        height: 70, // เพิ่มความสูงให้เท่ากับฝั่ง Add
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              _errorColor.withOpacity(0.7),
                              _errorColor.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: RadioListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),

                          title: Text(
                            'Deduct ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: 'SUBTRACT',
                          groupValue: _actionType,
                          activeColor: _errorColor,
                          onChanged: (value) {
                            setState(() {
                              _actionType = value.toString();
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 35),
              TextField(
                controller: _coinsController,
                maxLength: 5,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Coins Amount',
                  labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
                  prefixIcon: Icon(Icons.monetization_on, color: _accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accentColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              TextField(
                maxLength: 100,
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason (optional)',

                  labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
                  prefixIcon: Icon(Icons.description, color: _accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accentColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _showAnimatedConfirmationDialog,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: _actionType == 'ADD'
                        ? _successColor.withOpacity(0.8)
                        : _errorColor.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    padding: EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _actionType == 'ADD' ? Icons.add : Icons.remove,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              _actionType == 'ADD'
                                  ? 'Add Coins'
                                  : 'Subtract Coins',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
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
    );
  }

  Future<void> _showAnimatedConfirmationDialog() async {
    if (_selectedUser == null) {
      _showError('Please select a user');
      return;
    }

    final coinsAmount = int.tryParse(_coinsController.text);
    if (coinsAmount == null || coinsAmount <= 0) {
      _showError('Please enter a valid coins amount');
      return;
    }

    final actionText = _actionType == 'ADD' ? 'Add' : 'Subtract';
    final actionColor = _actionType == 'ADD' ? _successColor : _errorColor;

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Confirmation",
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return SizedBox.shrink(); // actual UI built in transitionBuilder
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOut.transform(anim1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0, curvedValue * -50, 0)
            ..scale(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [actionColor.withOpacity(0.8), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _actionType == 'ADD'
                          ? Icons.add_circle
                          : Icons.remove_circle,
                      size: 48,
                      color: actionColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '$actionText ${_coinsController.text} coins to ${_selectedUser!['username']}?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                        decoration:
                            TextDecoration.none, // ลบ underline/highlight
                        backgroundColor:
                            Colors.transparent, // ลบ background highlight
                      ),
                    ),

                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: actionColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Confirm'),
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
      },
    );

    if (result == true) {
      _manageCoins(); // เรียกใช้งานฟังก์ชันจัดการเหรียญจริง
    }
  }
}
