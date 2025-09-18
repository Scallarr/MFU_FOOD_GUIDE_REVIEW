import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AllUsersPage extends StatefulWidget {
  @override
  _AllUsersPageState createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  Map<String, dynamic>? _selectedUser;
  bool _isLoading = false;
  int? userId;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Color _accentColor = Color(0xFFA67C52);
  final Color _backgroundColor = Color(0xFFF5F0E6);
  final Color _textColor = Color(0xFF202124);
  final Color _primaryColor = Color(0xFF8B5A2B);
  final Color _secondaryColor = Color(0xFFD2B48C);

  final Color _secondaryTextColor = Color(0xFF5F6368);
  final Color _successColor = Color(0xFF34A853);
  final Color _errorColor = Color(0xFFEA4335);
  final Color _warningColor = Color(0xFFFBBC05);
  final Color _infoColor = Color(0xFF4285F4);

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterUsers();
    });
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_users);
      return;
    }

    final query = _searchQuery.toLowerCase();
    _filteredUsers = _users.where((user) {
      final username = user['username']?.toString().toLowerCase() ?? '';
      final userId = user['User_ID']?.toString().toLowerCase() ?? '';

      return username.contains(query) || userId.contains(query);
    }).toList();
  }

  Future<void> _fetchAllUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://172.22.173.39:8080/Usermanagement/users'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _users = data.map((e) => e as Map<String, dynamic>).toList();
          _filteredUsers = List.from(_users);
          _isLoading = false;
        });
      } else {
        print("❌ API Error: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("❌ Network Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _selectedUser == null
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 244, 242, 238),
                    Color.fromARGB(255, 255, 255, 255),
                    Color(0xFFF7F4EF),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      48,
                      47,
                      47,
                    ).withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    toolbarHeight: 80,
                    pinned: false,
                    floating: true,
                    snap: true,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        // ส่งค่า true กลับไปเพื่อบอกให้ refresh ข้อมูล
                        Navigator.pop(context, true);
                      },
                    ),
                    elevation: 6,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    flexibleSpace: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFCEBFA3), Color(0xFFCEBFA3)],
                        ),
                      ),
                    ),
                    title: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 73),
                          Center(
                            child: Text(
                              'All User',

                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: const Color.fromARGB(255, 35, 34, 34),
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search by username or User ID',
                            labelStyle: TextStyle(
                              color: _textColor.withOpacity(0.7),
                            ),
                            prefixIcon: Icon(Icons.search, color: _accentColor),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _filterUsers();
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          // onChanged: (value) {
                          //   _searchUsers(value);
                          //   setState(() => _hasSearched = value.isNotEmpty);
                          // },
                        ),
                      ),
                    ),
                  ),

                  // Search Results Info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total (${_filteredUsers.length})  Accounts ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            Expanded(
                              // <-- ใช้ Expanded แทน Flexible+Column
                              child: Text(
                                'Search results for "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow:
                                    TextOverflow.ellipsis, // ตัดข้อความถ้าเกิน
                                textAlign: TextAlign.end, // จัดชิดขวา
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Users List
                  _filteredUsers.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No users found'
                                      : 'No users found for "$_searchQuery"',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Try refreshing the page'
                                      : 'Try a different search term',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final user = _filteredUsers[index];
                            return _buildUserCard(user);
                          }, childCount: _filteredUsers.length),
                        ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
                ],
              ),
            )
          : Container(
              color: Color.fromARGB(255, 116, 115, 113).withOpacity(1),
              child: Center(
                child: Text(
                  "",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 127, 45, 45),
                    fontSize: 18,
                  ),
                ),
              ),
            ),
      bottomSheet: _selectedUser != null ? _buildUserBottomSheet() : null,
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isSelected =
        _selectedUser != null && _selectedUser!['User_ID'] == user['User_ID'];
    String coinsText = formatCoins(user['coins']);

    return AnimatedContainer(
      duration: Duration(milliseconds: 350),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isSelected
            ? LinearGradient(
                colors: [Colors.blue.withOpacity(0.15), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(colors: [Colors.white, Colors.white]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.15 : 0.05),
            blurRadius: isSelected ? 18 : 8,
            offset: Offset(0, isSelected ? 10 : 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 6,
            offset: Offset(-2, -2),
            spreadRadius: 1,
          ),
        ],
        border: isSelected
            ? Border.all(color: Colors.blue.withOpacity(0.9), width: 1.5)
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
              _selectedUser = {
                ...user,
                'coins': user['coins'] ?? 0,
                'formattedCoins': NumberFormat(
                  '#,###',
                ).format(int.tryParse(user['coins'].toString()) ?? 0),
              };
            }
          });
        },
        splashColor: Colors.blue.withOpacity(0.1),
        highlightColor: Colors.blue.withOpacity(0.05),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.blue[100],
                backgroundImage:
                    (user['picture_url'] != null &&
                        user['picture_url'].isNotEmpty)
                    ? NetworkImage(user['picture_url'])
                    : null,
                child:
                    (user['picture_url'] == null || user['picture_url'].isEmpty)
                    ? Text(
                        user['username'][0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username and ID
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['username'],
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: isSelected ? Colors.blue : Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${user['User_ID']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  user['User_ID'] == userId
                      ? Text(
                          user['email'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )
                      : Text(
                          obfuscateEmail(user['email']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: user['status'] == 'Active'
                              ? LinearGradient(
                                  colors: [Colors.greenAccent, Colors.green],
                                )
                              : LinearGradient(
                                  colors: [Colors.redAccent, Colors.red],
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
                      SizedBox(width: 7),

                      // Coins Badge
                      if (user['ban_info'] != null &&
                          user['ban_info'].isNotEmpty)
                        SizedBox(height: 6),
                      if (user['ban_info'] != null &&
                          user['ban_info'].isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7,
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
                              fontSize: 10,
                              color: Colors.orangeAccent[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
                color: isSelected ? Colors.blue : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Keep the rest of the methods unchanged: _buildUserBottomSheet, _buildInfoChip, obfuscateEmail, formatCoins, buildUserBanner)

  Widget _buildUserBottomSheet() {
    final user = _selectedUser!;
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.only(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 46, 45, 45),
              const Color.fromARGB(255, 136, 133, 133),
              const Color.fromARGB(255, 46, 45, 45),
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
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 40),
                    child: buildUserBanner(
                      _selectedUser?['picture_url'],
                      _selectedUser?['status'],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
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
                                _selectedUser!['username'][0].toUpperCase(),
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
                        padding: EdgeInsets.all(8),
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
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 7, bottom: 16),
                child: Column(
                  children: [
                    Text(
                      _selectedUser!['username'],
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    (_selectedUser!['User_ID'] == userId)
                        ? Text(
                            (_selectedUser!['email']),
                            style: TextStyle(
                              fontSize: 15,
                              color: const Color.fromARGB(255, 222, 220, 220),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Text(
                            obfuscateEmail(_selectedUser!['email']),
                            style: TextStyle(
                              fontSize: 15,
                              color: const Color.fromARGB(255, 222, 220, 220),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                          "${_selectedUser!['formattedCoins']}",
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
                            color: const Color.fromARGB(255, 183, 52, 222),
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
                    SizedBox(height: 15),

                    // ปุ่มดำเนินการ
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _showStatusConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedUser!['status'] == 'Active'
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
      ),
    );
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
      final result2 = await showDialog<bool>(
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
                  Icon(Icons.block, size: 60, color: _errorColor),
                  const SizedBox(height: 16),
                  Text(
                    'Ban User',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _errorColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selectedDuration != null
                        ? 'Are you sure you want to Ban ${_selectedUser!['username']} for $selectedDuration Day'
                        : 'Are you sure you want to permanently ban ${_selectedUser!['username']}?',
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
                            backgroundColor: _errorColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            'Ban',
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
      if (result2 == true) {
        await _banUser(selectedDuration, reasonController.text.trim());
      }
      ;
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
            await _fetchAllUsers();
            // if (_searchController.text.isNotEmpty) {
            //   await _searchUsers(_searchController.text);
            // }

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

          await _fetchAllUsers();
          // if (_searchController.text.isNotEmpty) {
          //   await _searchUsers(_searchController.text);
          // }
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

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    final baseColor = color ?? Colors.blue;
    return Container(
      width: 120,
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
      final atIndex = email.indexOf('@');
      if (atIndex > 3) {
        final prefix = email.substring(0, 3);
        final domain = email.substring(atIndex);
        return '$prefix********$domain';
      }
    }
    return email;
  }

  String formatCoins(int coins) => coins.toString();

  Widget buildUserBanner(String? pictureUrl, String baninfo) {
    return Container(
      height: baninfo == 'Banned' ? 350 : 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        image: (pictureUrl != null && pictureUrl.isNotEmpty)
            ? DecorationImage(
                image: NetworkImage(pictureUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
    );
  }
}
