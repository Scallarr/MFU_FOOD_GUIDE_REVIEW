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

    if (_reasonController.text.isEmpty) {
      _showError('Please enter a reason');
      return;
    }

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
          'reason': _reasonController.text,
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Management'),
        backgroundColor: const Color(0xFFCEBFA3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Section
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 16),

            // Search Results
            if (_searchResults.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user['username'][0].toUpperCase()),
                      ),
                      title: Text(user['username']),
                      subtitle: Text(user['email']),
                      trailing: Text('${user['coins']} coins'),
                      onTap: () {
                        setState(() {
                          _selectedUser = user;
                          _searchController.clear();
                          _searchResults = [];
                        });
                      },
                    );
                  },
                ),
              ),

            // Selected User
            if (_selectedUser != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(_selectedUser!['username'][0].toUpperCase()),
                  ),
                  title: Text(_selectedUser!['username']),
                  subtitle: Text('Current coins: ${_selectedUser!['coins']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text('Add Coins'),
                    value: 'ADD',
                    groupValue: _actionType,
                    onChanged: (value) {
                      setState(() {
                        _actionType = value.toString();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text('Subtract Coins'),
                    value: 'SUBTRACT',
                    groupValue: _actionType,
                    onChanged: (value) {
                      setState(() {
                        _actionType = value.toString();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _coinsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Coins Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _manageCoins,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _actionType == 'ADD'
                      ? Colors.green
                      : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        _actionType == 'ADD' ? 'Add Coins' : 'Subtract Coins',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
