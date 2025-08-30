import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MyHistoryPage extends StatefulWidget {
  @override
  _MyHistoryPageState createState() => _MyHistoryPageState();
}

class _MyHistoryPageState extends State<MyHistoryPage> {
  int? adminId;
  String _selectedType = 'threads'; // 'threads' หรือ 'replies'
  List<dynamic> _historyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminId();
  }

  Future<void> _loadAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adminId = prefs.getInt('user_id');
    });
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (adminId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final endpoint = _selectedType == 'threads'
          ? 'https://mfu-food-guide-review.onrender.com/api/admin_thread_history/$adminId'
          : 'https://mfu-food-guide-review.onrender.com/api/admin_reply_history/$adminId';

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        setState(() {
          _historyData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Approval History'),
        backgroundColor: Color(0xFFCEBFA3),
      ),
      body: Column(
        children: [
          // Dropdown สำหรับเลือกประเภท
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'threads',
                      child: Text('Threads History'),
                    ),
                    DropdownMenuItem(
                      value: 'replies',
                      child: Text('Replies History'),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                      _fetchHistory();
                    }
                  },
                ),
              ),
            ),
          ),

          // รายการประวัติ
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _historyData.isEmpty
                ? Center(child: Text('No history found'))
                : ListView.builder(
                    itemCount: _historyData.length,
                    itemBuilder: (context, index) {
                      final item = _historyData[index];
                      return _buildHistoryItem(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final action = item['admin_action_taken'];
    Color statusColor;
    IconData statusIcon;

    switch (action) {
      case 'Safe':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Banned':
        statusColor = Colors.red;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          item[_selectedType == 'threads' ? 'message' : 'message'] ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Action: $action'),
            if (item['reason_for_taken'] != null)
              Text('Reason: ${item['reason_for_taken']}'),
            Text('Date: ${_formatDate(item['admin_checked_at'])}'),
          ],
        ),
        trailing: Chip(
          label: Text(action, style: TextStyle(color: Colors.white)),
          backgroundColor: statusColor,
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
