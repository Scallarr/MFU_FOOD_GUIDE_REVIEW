import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/admin/Admin-profile-info.dart';
import 'package:myapp/admin/system_active_admin.dart';
import 'package:myapp/admin/system_active_user.dart';
import 'package:myapp/admin/system_ban_admin.dart';
import 'package:myapp/admin/system_ban_user.dart';
import 'package:myapp/admin/system_totalAll_user.dart';
import 'package:myapp/admin/system_total_admin.dart';
import 'package:myapp/admin/system_total_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _allUsersSearchController =
      TextEditingController();

  List<dynamic> _searchResults = [];
  List<dynamic> _allUsers = [];
  Map<String, dynamic>? _allUsers2;
  int _totalUsersCount = 0;
  int _totalAdminsCount = 0;
  int _activeUsersCount = 0;
  int _banned_Admin_count = 0;
  int _Total_User = 0;
  int _bannedUsersCount = 0;
  int _active_Admin_count = 0;
  Map<String, dynamic>? _selectedUser;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  int? userId;
  int _totalCoins = 0;
  bool _hasSearched = false;
  List<dynamic> _filteredAllUsers =
      []; // เพิ่ม List สำหรับเก็บข้อมูลที่กรองแล้ว

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
  final Color _infoColor = Color(0xFF4285F4);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _isInitialLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final storedUserId = prefs.getInt('user_id');

      final response = await http.post(
        Uri.parse('http://172.22.173.39:8080/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('All users API Response: $data');

        if (data['success'] == true) {
          setState(() {
            userId = storedUserId;
            _allUsers = data['users'] ?? [];
            _allUsers2 = data['counts'] ?? {};

            // อัปเดตค่าทั้งหมด
            _totalUsersCount = int.tryParse(_allUsers2!['user_count']) ?? 0;
            _totalAdminsCount = int.tryParse(_allUsers2!['admin_count']) ?? 0;
            _activeUsersCount =
                int.tryParse(_allUsers2!['active_user_count']) ?? 0;
            _bannedUsersCount =
                int.tryParse(_allUsers2!['banned_user_count']) ?? 0;
            _active_Admin_count =
                int.tryParse(_allUsers2!['active_Admin_count']) ?? 0;
            _banned_Admin_count =
                int.tryParse(_allUsers2!['banned_Admin_count']) ?? 0;
            _Total_User = (_allUsers2!['total_users']) ?? 0;
          });
        } else {
          _showError(data['message'] ?? 'Failed to load users');
        }
      } else {
        _showError('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading users: $e');
      _showError('Error loading users: $e');
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }
  // void _calculateStats() {
  //   // สมมติ _allUsers2 เป็น Map<String, dynamic>
  //   final userCountValue = _allUsers2['user_count']; // dynamic

  //   int totalUsersCount;

  //   // ถ้าเป็น int อยู่แล้ว
  //   if (userCountValue is int) {
  //     totalUsersCount = userCountValue;
  //   }
  //   // ถ้าเป็น String
  //   else if (userCountValue is String) {
  //     totalUsersCount = int.tryParse(userCountValue) ?? 0;
  //   }
  //   // ถ้าเป็น double
  //   else if (userCountValue is double) {
  //     totalUsersCount = userCountValue.toInt();
  //   }
  //   // กรณีอื่น ๆ
  //   else {
  //     totalUsersCount = 0;
  //   }

  //   // เมื่อโหลดข้อมูลทั้งหมดเสร็จ ให้ตั้งค่า filtered list
  //   setState(() {
  //     _filteredAllUsers = _allUsers;
  //   });
  // }

  void _filterAllUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredAllUsers = _allUsers;
      });
      return;
    }

    final filtered = _allUsers.where((user) {
      final username = user['username']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final userId = user['User_ID']?.toString().toLowerCase() ?? '';
      final searchTerm = query.toLowerCase();

      return username.contains(searchTerm) ||
          email.contains(searchTerm) ||
          userId.contains(searchTerm);
    }).toList();

    setState(() {
      _filteredAllUsers = filtered;
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('http://172.22.173.39:8080/admin/search2-users?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data');

        if (data['success'] == true) {
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
      } else if (response.statusCode == 400) {
        return;
      } else {
        // _showError('Failed to search users: ${response.statusCode}');
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, size: 60, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        'Ban ${_selectedUser!['username']}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // เหตุผลการแบน
                      TextFormField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          labelText: 'Reason for ban *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a reason';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 35),

                      // ระยะเวลาการแบน
                      DropdownButtonFormField<int>(
                        value: selectedDuration,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Permanent Ban'),
                          ),
                          const DropdownMenuItem(
                            value: 1,
                            child: Text('1 Day'),
                          ),
                          const DropdownMenuItem(
                            value: 3,
                            child: Text('3 Days'),
                          ),
                          const DropdownMenuItem(
                            value: 7,
                            child: Text('7 Days'),
                          ),
                          const DropdownMenuItem(
                            value: 30,
                            child: Text('30 Days'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedDuration = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Ban Duration',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ข้อความบอกสถานะ
                      if (selectedDuration != null)
                        Text(
                          'User will be automatically unbanned after $selectedDuration days',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      if (selectedDuration == null)
                        const Text(
                          'User will be permanently banned',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),

                      const SizedBox(height: 20),

                      // ปุ่ม Cancel / Confirm
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(221, 255, 255, 255),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pop(context, true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Ban User',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
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
            );
          },
        );
      },
    );

    if (result == true) {
      await _banUser(selectedDuration, reasonController.text.trim());
    }
  }

  Future<void> _banUser(int? durationDays, String reason) async {
    if (_selectedUser == null) return;

    // ตรวจสอบก่อนอัปเดต state
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final adminId = prefs.getInt('user_id');

      if (token == null || adminId == null) {
        if (!mounted) return; // ตรวจสอบอีกครั้ง
        _showError('ต้องล็อกอินใหม่');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.put(
        Uri.parse(
          'http://172.22.173.39:8080/admin/users/${_selectedUser!['User_ID']}/ban',
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

      final contentType = response.headers['content-type'];
      if (contentType != null && !contentType.contains('application/json')) {
        throw FormatException('Server ตอบกลับมาไม่ใช่ JSON');
      }

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('Ban response: $responseBody');

        try {
          final result = json.decode(responseBody);

          // ตรวจสอบก่อนแสดงผล
          if (!mounted) return;
          _showSuccess(result['message'] ?? 'แบนผู้ใช้สำเร็จ');

          // ตรวจสอบก่อนโหลดข้อมูลใหม่
          if (mounted) {
            await _loadAllUsers();
            if (_searchController.text.isNotEmpty) {
              await _searchUsers(_searchController.text);
            }

            setState(() {
              _selectedUser = null;
            });
          }
        } catch (e) {
          if (!mounted) return;
          _showError('Ban User fail: $e');
        }
      } else {
        try {
          final error = json.decode(response.body);
          if (!mounted) return;
          _showError(
            error['error'] ?? 'Ban User Syccessfull: ${response.statusCode}',
          );
        } catch (e) {
          if (!mounted) return;
          _showError('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Ban error: $e');
      if (!mounted) return;

      if (e is FormatException) {
        _showError('Server not responding');
      } else {
        _showError('Have a Problem: $e');
      }
    } finally {
      // ตรวจสอบก่อนอัปเดต state สุดท้าย
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          'http://172.22.173.39:8080/admin/users/${_selectedUser!['User_ID']}/unban',
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

          await _loadAllUsers();
          if (_searchController.text.isNotEmpty) {
            await _searchUsers(_searchController.text);
          }
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
    if (_selectedUser!['User_ID'] == userId) {
      _showError('You cannot ban/unban yourself.');
      return;
    }

    final isBanned = _selectedUser!['status'] == 'Banned';
    final actionText = isBanned ? 'Unban' : 'Ban';
    final actionColor = isBanned ? _successColor : _errorColor;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  actionText == 'Ban' ? Icons.block : Icons.lock_open,
                  size: 60,
                  color: actionColor,
                ),
                const SizedBox(height: 16),
                Text(
                  '$actionText User',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: actionColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to ${actionText.toLowerCase()} ${_selectedUser!['username']}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(221, 235, 235, 235),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          actionText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        duration: Duration(seconds: 1),
        content: Text(message),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String formatCoins(dynamic coins) {
    if (coins == null) return '0';
    int value = 0;

    if (coins is int) {
      value = coins;
    } else if (coins is double) {
      value = coins.toInt();
    } else if (coins is String) {
      value = int.tryParse(coins) ?? 0;
    }

    // ใช้ NumberFormat เพิ่ม comma
    return NumberFormat('#,###').format(value);
  }

  Widget _buildUserCard(user) {
    String coinsText = formatCoins(user['coins']);
    final isSelected =
        _selectedUser != null && _selectedUser!['User_ID'] == user['User_ID'];

    return AnimatedContainer(
      duration: Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isSelected
            ? LinearGradient(
                colors: [_primaryColor.withOpacity(0.15), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(colors: [Colors.white, Colors.white]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.12 : 0.05),
            blurRadius: isSelected ? 16 : 6,
            offset: Offset(0, isSelected ? 8 : 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 6,
            offset: Offset(-2, -2),
            spreadRadius: 1,
          ),
        ],
        border: isSelected
            ? Border.all(color: _primaryColor.withOpacity(0.9), width: 1.5)
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            if (_selectedUser != null &&
                _selectedUser!['User_ID'] == user['User_ID']) {
              _selectedUser = null;
            } else {
              _selectedUser = user;
            }
          });
        },
        child: Row(
          children: [
            Column(
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 35,
                  backgroundColor: _primaryColor.withOpacity(0.2),
                  backgroundImage:
                      (user['picture_url'] != null &&
                          user['picture_url'].isNotEmpty)
                      ? NetworkImage(user['picture_url'])
                      : null,
                  child:
                      (user['picture_url'] == null ||
                          user['picture_url'].isEmpty)
                      ? Text(
                          user['username'][0].toUpperCase(),
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  Text(
                    user['username'],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isSelected ? _primaryColor : _textColor,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  // Email
                  Text(
                    user['email'],
                    style: TextStyle(
                      fontSize: 11,
                      color: _textColor.withOpacity(0.65),
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: user['status'] == 'Active'
                              ? LinearGradient(
                                  colors: [Colors.greenAccent, _successColor],
                                )
                              : LinearGradient(
                                  colors: [Colors.redAccent, _errorColor],
                                ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          user['status'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Coins
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber[700]!, Colors.amber[400]!],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 14,
                              color: Colors.yellow[900],
                            ),
                            SizedBox(width: 2),
                            Text(
                              coinsText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: const Color.fromARGB(255, 103, 98, 94),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Ban info
                  if (user['ban_info'] != null && user['ban_info'].isNotEmpty)
                    SizedBox(height: 6),
                  if (user['ban_info'] != null && user['ban_info'].isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orangeAccent.withOpacity(0.2),
                            Colors.orangeAccent.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user['ban_info'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orangeAccent[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Arrow
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: isSelected
                    ? _primaryColor
                    : _secondaryTextColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.75), color.withOpacity(0.1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 10,
            offset: Offset(-4, -4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.05),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                Spacer(),
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [color, _darkenColor(color, 0.3)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds);
                  },
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _secondaryTextColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to darken color
  Color _darkenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - factor).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    final baseColor = color ?? Colors.blue;

    return Container(
      width: 120, // ให้ขนาดเท่ากัน
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withOpacity(0.95),
            const Color.fromARGB(255, 174, 174, 174).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 3, 3, 3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 220, 216, 216),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results (${_searchResults.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 24),
          padding: EdgeInsets.symmetric(vertical: 48, horizontal: 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 230, 11, 8).withOpacity(0.8), // Deep red
                Color.fromARGB(
                  255,
                  205,
                  202,
                  202,
                ).withOpacity(0.1), // Vibrant red
                Color(0xFFFF5252), // Light red
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 30,
                offset: Offset(0, 12),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.2),
                blurRadius: 50,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Icon with 3D effect
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.4),
                      Colors.white.withOpacity(0.1),
                    ],
                    center: Alignment.center,
                    radius: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(-4, -4),
                    ),
                    BoxShadow(
                      color: Colors.red[900]!.withOpacity(0.6),
                      blurRadius: 20,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_off_rounded,
                  size: 64,
                  color: Color(0xFFB71C1C), // Deep red
                ),
              ),
              SizedBox(height: 28),

              // Premium title with text shadow
              Text(
                'USER NOT FOUND',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Elegant description
              Text(
                'No user matches your search criteria.\nTry different keywords or filters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 28),

              // Premium suggestion chips
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySearchCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results (${_searchResults.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 24),
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 40, 41, 42).withOpacity(0.9),
                const Color.fromARGB(
                  255,
                  215,
                  211,
                  211,
                ).withOpacity(0.8), // สดใสฟ้า
                Color.fromARGB(255, 90, 90, 90).withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 25,
                offset: Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.1),
                blurRadius: 50,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 12),
              // Icon Circle
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.4),
                      Colors.white.withOpacity(0.1),
                    ],
                    center: Alignment.center,
                    radius: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(-4, -4),
                    ),
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        8,
                        8,
                        8,
                      )!.withOpacity(0.6),
                      blurRadius: 20,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 64,
                  color: Color.fromARGB(255, 112, 127, 149),
                ),
              ),
              SizedBox(height: 28),
              // Title
              Text(
                'DISCOVER USERS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28),
              // Tips card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      const Color.fromARGB(
                        255,
                        243,
                        240,
                        240,
                      ).withOpacity(0.15),
                      const Color.fromARGB(255, 245, 245, 245).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(-3, -3),
                    ),
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        235,
                        235,
                        235,
                      )!.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: Colors.black87.withOpacity(0.9),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'SEARCH STRATEGIES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildPremiumTipItem('• Partial username matching'),
                    _buildPremiumTipItem('• Exact email address search'),
                    _buildPremiumTipItem('• User ID for precise results'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumChip(String text, Color baseColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [baseColor.withOpacity(0.9), baseColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.4),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPremiumTipItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: const Color.fromARGB(255, 69, 68, 68).withOpacity(0.95),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserBanner(String? imageUrl) {
    final placeholder =
        "https://via.placeholder.com/400x200.png?text=No+Image"; // fallback

    return Container(
      width: double.infinity,
      height: 270,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              (imageUrl != null && imageUrl.isNotEmpty)
                  ? imageUrl
                  : placeholder,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[600],
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            // gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedUser != null
          ? AppBar(
              title: Text(
                '',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              toolbarHeight: 70,
              backgroundColor: const Color.fromARGB(255, 116, 115, 113),

              elevation: 0,
            )
          : AppBar(
              title: Text(
                'User Management',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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
              // bottom: TabBar(
              //   controller: _tabController,
              //   indicatorColor: Colors.white,
              //   labelColor: Colors.white,
              //   unselectedLabelColor: Colors.white.withOpacity(0.7),
              //   tabs: [
              //     Tab(text: 'All Users'),
              //     Tab(text: 'Search'),
              //   ],
              // ),
            ),
      backgroundColor: _backgroundColor,
      body: _selectedUser != null
          ? Container(
              color: const Color.fromARGB(
                255,
                18,
                17,
                17,
              ).withOpacity(0.5), // ความเข้มของดำ
              child: Center(
                child: Text(
                  "",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 127, 45, 45),
                    fontSize: 18,
                  ),
                ),
              ),
            )
          :
            // TabBarView(
            //     controller: _tabController,
            //     children: [
            // Tab 1: All Users
            _isInitialLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  // Statistics Section
                  Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Row: Total All Users
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final shouldRefresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllUsersPage(),
                              ),
                            );
                            if (shouldRefresh == true) {
                              setState(() {
                                _loadAllUsers();
                              });
                            }
                          },
                          child: _buildStatsCard(
                            'All Accounts',
                            '$_Total_User',
                            const Color.fromARGB(
                              255,
                              108,
                              102,
                              159,
                            ).withOpacity(1),
                            Icons.people_alt_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Row 1: Total Users & Total Admins
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final shouldRefresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoleUsersPage(),
                              ),
                            );
                            if (shouldRefresh == true) {
                              setState(() {
                                _loadAllUsers();
                              });
                            }
                          },
                          child: _buildStatsCard(
                            'Total Users',
                            '$_totalUsersCount',
                            const Color.fromARGB(
                              255,
                              174,
                              164,
                              144,
                            ).withOpacity(1),
                            Icons.people_alt_rounded,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final shouldRefresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoleAdminPage(),
                              ),
                            );
                            if (shouldRefresh == true) {
                              setState(() {
                                _loadAllUsers();
                              });
                            }
                          },
                          child: _buildStatsCard(
                            'Total Admins',
                            '$_totalAdminsCount',
                            const Color.fromARGB(255, 101, 116, 125),
                            Icons.admin_panel_settings_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Row 2: Active Users & Active Admins
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final shouldRefresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActiveUserPage(),
                              ),
                            );
                            if (shouldRefresh == true) {
                              setState(() {
                                _loadAllUsers();
                              });
                            }
                          },
                          child: _buildStatsCard(
                            'Active Users',
                            '$_activeUsersCount',
                            const Color.fromARGB(
                              255,
                              174,
                              164,
                              144,
                            ).withOpacity(1),
                            Icons.verified_user_rounded,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final shouldRefresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActiveAdminPage(),
                              ),
                            );
                            if (shouldRefresh == true) {
                              setState(() {
                                _loadAllUsers();
                              });
                            }
                          },
                          child: _buildStatsCard(
                            'Active Admins',
                            '$_active_Admin_count',
                            const Color.fromARGB(255, 101, 116, 125),
                            Icons.verified_user_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Row 3: Banned Users & Banned Admins
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final shouldRefresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BanUserPage(),
                              ),
                            );
                            if (shouldRefresh == true) {
                              setState(() {
                                _loadAllUsers();
                              });
                            }
                          },
                          child: _buildStatsCard(
                            'Banned Users',
                            '$_bannedUsersCount',
                            const Color.fromARGB(
                              255,
                              174,
                              164,
                              144,
                            ).withOpacity(1),
                            Icons.block_rounded,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final shouldRefresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BanAdminPage(),
                              ),
                            );
                            if (shouldRefresh == true) {
                              setState(() {
                                _loadAllUsers();
                              });
                            }
                          },
                          child: _buildStatsCard(
                            'Banned Admins',
                            '$_banned_Admin_count',
                            const Color.fromARGB(255, 101, 116, 125),
                            Icons.block_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),

      // // Tab 2: Search
      // SingleChildScrollView(
      //   padding: EdgeInsets.all(16),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       // Search Section
      //       Text(
      //         'Search User',
      //         style: TextStyle(
      //           fontSize: 18,
      //           fontWeight: FontWeight.w600,
      //           color: _textColor,
      //         ),
      //       ),
      //       SizedBox(height: 12),
      //       TextField(
      //         controller: _searchController,
      //         decoration: InputDecoration(
      //           labelText: 'Search by username, email or User ID',
      //           labelStyle: TextStyle(
      //             color: _textColor.withOpacity(0.7),
      //           ),
      //           prefixIcon: Icon(Icons.search, color: _accentColor),
      //           suffixIcon: _searchController.text.isNotEmpty
      //               ? IconButton(
      //                   icon: Icon(Icons.clear, color: _accentColor),
      //                   onPressed: () {
      //                     _searchController.clear();
      //                     _searchUsers('');
      //                     setState(() => _hasSearched = false);
      //                   },
      //                 )
      //               : null,
      //           border: OutlineInputBorder(
      //             borderRadius: BorderRadius.circular(12),
      //           ),
      //           filled: true,
      //           fillColor: Colors.white,
      //         ),
      //         onChanged: (value) {
      //           _searchUsers(value);
      //           setState(() => _hasSearched = value.isNotEmpty);
      //         },
      //       ),
      //       SizedBox(height: 16),

      //       // Search Results
      //       if (_searchResults.isNotEmpty)
      //         Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             Text(
      //               'Search Results (${_searchResults.length})',
      //               style: TextStyle(
      //                 fontSize: 16,
      //                 fontWeight: FontWeight.w600,
      //                 color: _textColor,
      //               ),
      //             ),
      //             SizedBox(height: 12),
      //             Container(
      //               decoration: BoxDecoration(
      //                 color: Colors.white,
      //                 borderRadius: BorderRadius.circular(12),
      //                 boxShadow: [
      //                   BoxShadow(
      //                     color: Colors.black.withOpacity(0.05),
      //                     blurRadius: 8,
      //                     offset: Offset(0, 4),
      //                   ),
      //                 ],
      //               ),
      //               child: ListView.builder(
      //                 shrinkWrap:
      //                     true, // ให้ ListView ย่อขนาดตามเนื้อหา
      //                 physics:
      //                     NeverScrollableScrollPhysics(), // ป้องกัน scroll ภายใน
      //                 itemCount: _searchResults.length,
      //                 itemBuilder: (context, index) {
      //                   final user = _searchResults[index];
      //                   return _buildUserCard(user);
      //                 },
      //               ),
      //             ),
      //           ],
      //         )
      //       else
      //         // ถ้า search แล้วแต่ไม่เจอ
      //         (_hasSearched
      //             ? _buildNoResultsCard()
      //             // ยังไม่ได้ search
      //             : _buildEmptySearchCard()),
      //     ],
      //   ),
      // ),
      //   ],
      // ),
      bottomSheet: _selectedUser != null
          ? Container(
              padding: EdgeInsets.only(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromARGB(255, 46, 45, 45), // เทาเข้มด้านล่าง
                    const Color.fromARGB(255, 136, 133, 133), // เทาอ่อนด้านบน
                    const Color.fromARGB(255, 46, 45, 45), // เทาเข้มด้านล่าง
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ดราก์อินดิเคเตอร์
                    Container(
                      width: 40,
                      height: 0,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // ส่วนหัว

                    // Container สำหรับ Banner และ Avatar ที่ซ้อนกัน
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Banner
                        Container(
                          margin: EdgeInsets.only(
                            bottom: 40,
                          ), // ระยะห่างสำหรับ Avatar
                          child: buildUserBanner(_selectedUser?['picture_url']),
                        ),
                        Positioned(
                          top: 290,
                          right: -60,
                          child: Icon(
                            Icons.lock_outlined,
                            size: 120,
                            color: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.1),
                          ),
                        ),
                        Positioned(
                          bottom: -550,
                          left: 40,
                          child: Icon(
                            Icons.group,
                            size: 340,
                            color: const Color.fromARGB(
                              255,
                              9,
                              9,
                              9,
                            ).withOpacity(0.4),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedUser = null;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(
                                8,
                              ), // ทำให้ Icon มีพื้นที่รอบ ๆ
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.redAccent.shade100,
                                    Colors.red.shade700,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Avatar (วางซ้อนลงบน Banner)
                        Positioned(
                          bottom: 0, // ทำให้ Avatar ยื่นออกมาจาก Banner
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blue[100],
                              backgroundImage:
                                  (_selectedUser!['picture_url'] != null &&
                                      _selectedUser!['picture_url'].isNotEmpty)
                                  ? NetworkImage(_selectedUser!['picture_url'])
                                  : null,
                              child:
                                  (_selectedUser!['picture_url'] == null ||
                                      _selectedUser!['picture_url'].isEmpty)
                                  ? Text(
                                      _selectedUser!['username'][0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ชื่อและ email (ลดระยะห่างจาก Avatar)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 7,
                        bottom: 16,
                      ), // ลดจาก 60 เป็น 50
                      child: Column(
                        children: [
                          Text(
                            _selectedUser!['username'],
                            style: TextStyle(
                              fontSize: 22, // เพิ่มขนาดฟอนต์
                              fontWeight: FontWeight.w800, // ตัวหนากว่าเดิม
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          _selectedUser!['User_ID'] == userId
                              ? // เพิ่มระยะห่างเล็กน้อย
                                Text(
                                  _selectedUser!['email'],
                                  style: TextStyle(
                                    fontSize: 15, // เพิ่มขนาดฟอนต์เล็กน้อย
                                    color: const Color.fromARGB(
                                      255,
                                      233,
                                      227,
                                      227,
                                    ),
                                    fontWeight:
                                        FontWeight.w500, // ตัวหนาปานกลาง
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              : Text(
                                  _selectedUser!['email'],
                                  style: TextStyle(
                                    fontSize: 15, // เพิ่มขนาดฟอนต์เล็กน้อย
                                    color: const Color.fromARGB(
                                      255,
                                      233,
                                      227,
                                      227,
                                    ),
                                    fontWeight:
                                        FontWeight.w500, // ตัวหนาปานกลาง
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ชิปข้อมูล
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildInfoChip(
                                Icons.badge_outlined,
                                "User ID",
                                "${_selectedUser!['User_ID']}",
                                color: Colors.blue,
                              ),
                              if (_selectedUser!['role'] != null &&
                                  _selectedUser!['role'].isNotEmpty)
                                _buildInfoChip(
                                  Icons.manage_accounts,
                                  "Role",
                                  "${_selectedUser!['role']}",
                                  color: Colors.teal,
                                ),
                              _buildInfoChip(
                                _selectedUser!['status'] == "Active"
                                    ? Icons.verified_user_outlined
                                    : Icons.block_outlined,
                                "Status",
                                _selectedUser!['status'],
                                color: _selectedUser!['status'] == "Active"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              _buildInfoChip(
                                Icons.monetization_on_outlined,
                                "Coins",
                                "${formatCoins(_selectedUser!['coins'])}",
                                color: Colors.orange,
                              ),
                              if (_selectedUser!['total_likes'] != null)
                                _buildInfoChip(
                                  Icons.favorite_outline,
                                  "Likes",
                                  "${_selectedUser!['total_likes']}",
                                  color: Colors.pink,
                                ),
                              if (_selectedUser!['total_reviews'] != null)
                                _buildInfoChip(
                                  Icons.reviews_outlined,
                                  "Reviews",
                                  "${_selectedUser!['total_reviews']}",
                                  color: Colors.blue,
                                ),
                            ],
                          ),

                          if (_selectedUser!['ban_info'] != null &&
                              _selectedUser!['ban_info'].isNotEmpty) ...[
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange[700],
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Ban Info: ${_selectedUser!['ban_info']}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: 20),

                          // ปุ่มดำเนินการ
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _showStatusConfirmationDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _selectedUser!['status'] == 'Active'
                                    ? Colors.red[500]
                                    : Colors.green[500],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                                padding: EdgeInsets.symmetric(horizontal: 20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoading)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      _selectedUser!['status'] == 'Active'
                                          ? Icons.block
                                          : Icons.check_circle,
                                      size: 20,
                                    ),
                                  SizedBox(width: 8),
                                  Text(
                                    _selectedUser!['status'] == 'Active'
                                        ? "Ban User"
                                        : "Unban User",
                                    style: TextStyle(
                                      fontSize: 16,
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
                  ],
                ),
              ),
            )
          : null,
    );
  }

  String obfuscateEmail(String email) {
    if (email.endsWith('@lamduan.mfu.ac.th')) {
      final domain = '@lamduan.mfu.ac.th';
      if (email.length > domain.length + 2) {
        final prefix = email.substring(0, 2);
        return '$prefix********$domain';
      }
    } else if (email.endsWith('@mfu.ac.th')) {
      final domain = '@mfu.ac.th';
      if (email.length > domain.length + 2) {
        final prefix = email.substring(0, 2);
        return '$prefix********$domain';
      }
    } else {
      // สำหรับเมลปกติ
      final atIndex = email.indexOf('@');
      if (atIndex > 3) {
        final prefix = email.substring(0, 3);
        final domain = email.substring(atIndex);
        return '$prefix********$domain';
      }
    }
    return email; // กรณีอื่น ๆ
  }
}
