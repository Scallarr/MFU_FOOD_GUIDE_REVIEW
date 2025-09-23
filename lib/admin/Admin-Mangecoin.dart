import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

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
  Map<String, dynamic>? _selectedUser2;
  bool _isLoading = false;
  String _actionType = 'ADD';
  bool _hasSearched = false;
  int? userId;

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

      setState(() {
        userId = prefs.getInt('user_id');
        print('userId: $userId');
      });

      final response = await http.get(
        Uri.parse('http://172.27.112.167:8080/admin/search-users?query=$query'),
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

  Future<void> _fetchCurrentUserInfo(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final uri = Uri.parse('http://172.27.112.167:8080/user/info/$userId');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _selectedUser2 = {
            'User_ID': userId,
            'username': userData['username'] ?? '',
            'email': userData['email'] ?? '',
            'total_likes': userData['total_likes'] ?? 0,
            'total_reviews': userData['total_reviews'] ?? 0,
            'coins': userData['coins'] ?? 0,
            'formattedCoins': NumberFormat(
              '#,###',
            ).format(int.tryParse(userData['coins'].toString()) ?? 0),
            'status': userData['status'] ?? '',
            'picture_url': userData['picture_url'] ?? '',
            'role': userData['role'] ?? '',
          };
        });
        print(' Udfdfdfpgfgplfgpfplg $_selectedUser');
      } else {
        print('Failed to fetch user info. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  Future<void> _manageCoins() async {
    final selectedUser = _selectedUser;
    final coinsText = _coinsController.text;
    final reasonText = _reasonController.text;

    if (selectedUser == null) {
      _showError('Please select a user');
      return;
    }

    final coinsAmount = int.tryParse(coinsText ?? '');
    if (coinsAmount == null || coinsAmount <= 0) {
      _showError('Please enter a valid coins amount');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.isEmpty) {
        _showError('Token not found');
        return;
      }

      final response = await http.post(
        Uri.parse('http://172.27.112.167:8080/admin/manage-coins'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'targetUserId': selectedUser['User_ID'] ?? 0,
          'actionType': _actionType,
          'coinsAmount': coinsAmount,
          'reason': reasonText.isNotEmpty ? reasonText : '-',
        }),
      );

      if (response.statusCode == 200) {
        _showSuccess(
          'Coins ${_actionType == 'ADD' ? 'added' : 'subtracted'} successfully',
        );

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

  Widget buildUserBanner(String? imageUrl) {
    final placeholder =
        "https://via.placeholder.com/400x200.png?text=No+Image"; // fallback

    return Container(
      width: double.infinity,
      height: 420,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Coin Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        toolbarHeight: 50,
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
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: _accentColor),
                          onPressed: () {
                            _searchController.clear();
                            _searchUsers('');
                            setState(() => _hasSearched = false);
                          },
                        )
                      : null,
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
                onChanged: (value) {
                  _searchUsers(value);
                  setState(() => _hasSearched = value.isNotEmpty);
                },
              ),
              SizedBox(height: 16),

              // แก้ไขส่วนของการแสดงผล Search Results
              (!_hasSearched && _selectedUser == null)
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 16,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: 48,
                            color: _errorColor.withOpacity(0.8),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start Search Now',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _textColor.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Can searching with a username or email Or User ID with Active Status.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : (_searchResults.isNotEmpty)
                  ? Container(
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
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_selectedUser2 != null &&
                                      _selectedUser2!['User_ID'] ==
                                          user['User_ID']) {
                                    _selectedUser2 = null;
                                  } else {
                                    // _selectedUser2 = user;
                                    _fetchCurrentUserInfo(user['user_ID']);
                                  }
                                });
                              },
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
                                    _hasSearched = false; // Reset search state
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : (_searchController.text.isNotEmpty && _selectedUser == null)
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 16,
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
                            'Try searching with a different username  or email or User ID with Active Status.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(), // Hide when user is selected
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
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedUser2 != null &&
                          _selectedUser2!['User_ID'] ==
                              _selectedUser!['User_ID']) {
                        _selectedUser = null;
                      } else {
                        // _selectedUser2 = _selectedUser;
                        _fetchCurrentUserInfo(_selectedUser!['User_ID']);
                      }
                    });
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedUser2 != null &&
                                _selectedUser2!['User_ID'] ==
                                    _selectedUser!['User_ID']) {
                              _selectedUser = null;
                            } else {
                              // _selectedUser2 = _selectedUser;
                              _fetchCurrentUserInfo(_selectedUser!['User_ID']);
                            }
                          });
                        },
                        child: CircleAvatar(
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
                maxLength: 7,
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
                  onPressed: _isLoading ? null : _showCoinConfirmationDialog,

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
      bottomSheet: _selectedUser2 != null
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
                                _selectedUser2 = null;
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
                                "${_selectedUser2!['User_ID']}",
                                color: Colors.blue,
                              ),
                              if (_selectedUser2!['role'] != null &&
                                  _selectedUser2!['role'].isNotEmpty)
                                _buildInfoChip(
                                  Icons.manage_accounts,
                                  "Role",
                                  "${_selectedUser2!['role']}",
                                  color: Colors.teal,
                                ),
                              _buildInfoChip(
                                _selectedUser2!['status'] == "Active"
                                    ? Icons.verified_user_outlined
                                    : Icons.block_outlined,
                                "Status",
                                _selectedUser2!['status'],
                                color: _selectedUser2!['status'] == "Active"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              _buildInfoChip(
                                Icons.monetization_on_outlined,
                                "Coins",
                                "${formatCoins(_selectedUser2!['coins'])}",
                                color: Colors.orange,
                              ),
                              if (_selectedUser2!['total_likes'] != null)
                                _buildInfoChip(
                                  Icons.favorite_outline,
                                  "Likes",
                                  "${_selectedUser2!['total_likes']}",
                                  color: Colors.pink,
                                ),
                              if (_selectedUser2!['total_reviews'] != null)
                                _buildInfoChip(
                                  Icons.reviews_outlined,
                                  "Reviews",
                                  "${_selectedUser2!['total_reviews']}",
                                  color: Colors.blue,
                                ),
                            ],
                          ),

                          if (_selectedUser2!['ban_info'] != null &&
                              _selectedUser2!['ban_info'].isNotEmpty) ...[
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
                                      "Ban Info: ${_selectedUser2!['ban_info']}",
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

  Future<void> _showCoinConfirmationDialog() async {
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
    final actionColor = _actionType == 'ADD' ? Colors.green : Colors.red;
    final username = _selectedUser?['username'] ?? 'user';

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _actionType == 'ADD' ? Icons.add_circle : Icons.remove_circle,
                  size: 60,
                  color: actionColor,
                ),
                const SizedBox(height: 20),
                Text(
                  '$actionText Coins',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: actionColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to $actionText $coinsAmount coins to $username?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor.withOpacity(0.85),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'Confirm',
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

    if (confirmed != true) return;

    // เรียกฟังก์ชันจัดการ coins หลังผู้ใช้ยืนยัน
    await _manageCoins();
  }

  // if (result == true) {
  //   _manageCoins(); // เรียกใช้งานฟังก์ชันจัดการเหรียญจริง
  // }
}
