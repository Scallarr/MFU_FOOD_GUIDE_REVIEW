import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  Map<String, dynamic>? _selectedUser;
  bool _isLoading = false;

  // Colors
  final Color _primaryColor = Color(0xFF8B5A2B);
  final Color _secondaryColor = Color(0xFFD2B48C);
  final Color _accentColor = Color(0xFFA67C52);
  final Color _backgroundColor = Color(0xFFF5F0E6);
  final Color _textColor = Color(0xFF202124);
  final Color _secondaryTextColor = Color(0xFF5F6368);
  final Color _successColor = Color(0xFF34A853);
  final Color _errorColor = Color(0xFFEA4335);
  final Color _warningColor = Color(0xFFFBBC05);

  @override
  void dispose() {
    _searchController.dispose();
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
        Uri.parse('http://10.0.3.201:8080/admin/search2-users?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ตรวจสอบโครงสร้าง response
        print('API Response: $data');

        if (data['success'] == true) {
          // ใช้ data['users'] ซึ่งเป็น List
          setState(() {
            _searchResults = data['users'] ?? [];
          });

          print('Found ${_searchResults.length} users');
        } else {
          _showError(data['message'] ?? 'Failed to search users');
          setState(() {
            _searchResults = [];
          });
        }
      } else {
        _showError('Failed to search users: ${response.statusCode}');
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      print('Error searching users: $e');
      _showError('Error searching users: $e');
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _showBanDialog() async {
    if (_selectedUser == null) {
      _showError('Please select a user');
      return;
    }

    int? selectedDuration;
    final reasonController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Ban User: ${_selectedUser!['username']}'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason for ban*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a reason';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Text('Ban Duration:'),
                    DropdownButtonFormField<int>(
                      value: selectedDuration,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Permanent Ban'),
                        ),
                        DropdownMenuItem(value: 1, child: Text('1 Day')),
                        DropdownMenuItem(value: 3, child: Text('3 Days')),
                        DropdownMenuItem(value: 7, child: Text('7 Days')),
                        DropdownMenuItem(value: 30, child: Text('30 Days')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedDuration = value;
                        });
                      },
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                    if (selectedDuration != null)
                      Text(
                        'User will be automatically unbanned after $selectedDuration days',
                      ),
                    if (selectedDuration == null)
                      Text('User will be permanently banned'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text('Ban User'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _banUser(selectedDuration, reasonController.text);
    }
  }

  Future<void> _banUser(int? durationDays, String reason) async {
    if (_selectedUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final adminId = prefs.getInt('user_id');

      // ตรวจสอบว่ามี token และ adminId
      if (token == null || adminId == null) {
        _showError('Authentication required. Please login again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.put(
        Uri.parse(
          'http://10.0.3.201:8080/admin/users/${_selectedUser!['User_ID']}/ban',
        ),

        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'adminId': adminId,
          'reason': reason,
          'durationDays': durationDays,
        }),
      );

      // ตรวจสอบว่า response เป็น JSON
      final contentType = response.headers['content-type'];
      if (contentType != null && !contentType.contains('application/json')) {
        throw FormatException(
          'Server returned non-JSON response: $contentType',
        );
      }

      if (response.statusCode == 200) {
        final responseBody = response.body;

        // Debug print
        print('Ban response: $responseBody');

        try {
          final result = json.decode(responseBody);
          _showSuccess(result['message'] ?? 'User banned successfully');

          // Refresh the user list
          await _searchUsers(_searchController.text);

          // Clear selection
          setState(() {
            _selectedUser = null;
          });
        } catch (e) {
          _showError('Failed to parse server response: $e');
        }
      } else {
        // ตรวจสอบว่า server return JSON error หรือ HTML
        try {
          final error = json.decode(response.body);
          _showError(
            error['error'] ?? 'Failed to ban user: ${response.statusCode}',
          );
        } catch (e) {
          _showError(
            'Server error: ${response.statusCode}. Please check server logs.',
          );
        }
      }
    } catch (e) {
      print('Ban error: $e');
      if (e is FormatException) {
        _showError(
          'Server returned invalid response. Please check if the server is running correctly.',
        );
      } else {
        _showError('Error: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _unbanUser() async {
    if (_selectedUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final adminId = prefs.getInt('user_id');

      if (token == null || adminId == null) {
        _showError('Authentication required. Please login again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.put(
        Uri.parse(
          'http://10.0.3.201:8080/admin/users/${_selectedUser!['User_ID']}/unban',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'adminId': adminId}),
      );

      // ตรวจสอบ content type
      final contentType = response.headers['content-type'];
      if (contentType != null && !contentType.contains('application/json')) {
        throw FormatException(
          'Server returned non-JSON response: $contentType',
        );
      }

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('Unban response: $responseBody');

        try {
          final result = json.decode(responseBody);
          _showSuccess(result['message'] ?? 'User unbanned successfully');

          await _searchUsers(_searchController.text);
          setState(() {
            _selectedUser = null;
          });
        } catch (e) {
          _showError('Failed to parse server response: $e');
        }
      } else {
        try {
          final error = json.decode(response.body);
          _showError(
            error['error'] ?? 'Failed to unban user: ${response.statusCode}',
          );
        } catch (e) {
          _showError('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Unban error: $e');
      if (e is FormatException) {
        _showError(
          'Server returned invalid response. Please check server configuration.',
        );
      } else {
        _showError('Error: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showStatusConfirmationDialog() async {
    if (_selectedUser == null) {
      _showError('Please select a user');
      return;
    }

    final isBanned = _selectedUser!['status'] == 'Banned';
    final actionText = isBanned ? 'Unban' : 'Ban';
    final actionColor = isBanned ? _successColor : _errorColor;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$actionText User'),
          content: Text(
            'Are you sure you want to ${actionText.toLowerCase()} ${_selectedUser!['username']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: actionColor),
              onPressed: () => Navigator.pop(context, true),
              child: Text(actionText),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (isBanned) {
        await _unbanUser();
      } else {
        await _showBanDialog();
      }
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
        backgroundColor: _successColor,
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
          'User Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        toolbarHeight: 70,
        backgroundColor: const Color(0xFFCEBFA3),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, true);
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

              // No results message
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
                  constraints: BoxConstraints(maxHeight: 620),
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
                        child: // ในส่วนของ ListTile ใน ListView.builder
                        ListTile(
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
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user['status'] == 'Active'
                                          ? _successColor.withOpacity(0.2)
                                          : _errorColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      user['status'],
                                      style: TextStyle(
                                        color: user['status'] == 'Active'
                                            ? _successColor
                                            : _errorColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
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
                              // แสดงข้อมูลการแบนถ้ามี
                              if (user['ban_info'] != null &&
                                  user['ban_info'].isNotEmpty)
                                SizedBox(height: 4),
                              if (user['ban_info'] != null &&
                                  user['ban_info'].isNotEmpty)
                                Text(
                                  user['ban_info'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _warningColor,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                          ? NetworkImage(_selectedUser!['picture_url'])
                          : null,
                      child:
                          (_selectedUser!['picture_url'] == null ||
                              _selectedUser!['picture_url'].isEmpty)
                          ? Text(
                              _selectedUser!['username'][0].toUpperCase(),
                              style: TextStyle(color: Colors.white),
                            )
                          : null,
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
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedUser!['status'] == 'Active'
                                    ? _successColor.withOpacity(0.2)
                                    : _errorColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedUser!['status'],
                                style: TextStyle(
                                  color: _selectedUser!['status'] == 'Active'
                                      ? _successColor
                                      : _errorColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
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
                        if (_selectedUser!['ban_info'] != null &&
                            _selectedUser!['ban_info'].isNotEmpty)
                          SizedBox(height: 4),
                        if (_selectedUser!['ban_info'] != null &&
                            _selectedUser!['ban_info'].isNotEmpty)
                          Text(
                            _selectedUser!['ban_info'],
                            style: TextStyle(
                              fontSize: 11,
                              color: _warningColor,
                              fontWeight: FontWeight.w500,
                            ),
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

                // Action Button
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _showStatusConfirmationDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUser!['status'] == 'Active'
                          ? _errorColor.withOpacity(0.8)
                          : _successColor.withOpacity(0.8),
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
                                _selectedUser!['status'] == 'Active'
                                    ? Icons.block
                                    : Icons.check_circle,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _selectedUser!['status'] == 'Active'
                                    ? 'Ban User'
                                    : 'Unban User',
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
            ],
          ),
        ),
      ),
    );
  }
}
