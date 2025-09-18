import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RewardHistoryPage extends StatefulWidget {
  const RewardHistoryPage({super.key});

  @override
  State<RewardHistoryPage> createState() => _RewardHistoryPageState();
}

class _RewardHistoryPageState extends State<RewardHistoryPage> {
  List<dynamic> rewardHistory = [];
  bool isLoading = true;
  String error = '';
  String totalCoins = '';

  @override
  void initState() {
    super.initState();
    fetchRewardHistory();
  }

  Future<void> fetchRewardHistory() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = prefs.getInt('user_id');

      if (token == null || userId == null) {
        setState(() {
          error = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://172.22.173.39:8080/rewards-history/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('d: ${data}');

        setState(() {
          rewardHistory = data['history'] ?? [];

          totalCoins = NumberFormat(
            '#,###',
          ).format(data['total_coins'] ?? 'df');
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load reward history';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String _formatMonthYear(String monthYear) {
    try {
      final parts = monthYear.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return monthYear;
    }
  }

  Widget _buildRewardTile(Map<String, dynamic> reward, int index) {
    final type = reward['type']; // Leaderboard / Admin / Purchase

    // แปลงวันที่
    String formattedDate = '';
    if (reward['awarded_at'] != null) {
      try {
        final dateTime = DateTime.parse(reward['awarded_at']);
        formattedDate = DateFormat('dd MMM yyyy – HH:mm').format(dateTime);
      } catch (_) {
        formattedDate = reward['awarded_at'].toString();
      }
    }

    // เหรียญ (บวกหรือลบ)
    final displayCoins = reward['coins_awarded'];

    // กำหนด UI ตาม type
    String titleText = '';
    String subtitleText = '';
    IconData icon = Icons.stars;
    Color bgColor = Colors.grey[200]!;
    Color borderColor = Colors.grey;
    Color iconBgColor = Colors.grey;

    switch (type) {
      case "Leaderboard":
        titleText = "From Leaderboard";
        subtitleText = "🏆 Rank: ${reward['rank']}   (${reward['month_year']})";
        icon = Icons.emoji_events;
        bgColor = const Color(0xFFFFF8E1);
        borderColor = const Color(0xFFFFB74D);
        iconBgColor = const Color(0xFFFF9800);
        break;
      case "Admin":
        titleText = "From Admin";
        subtitleText = reward['action_type'] == 'ADD'
            ? '🎉 Coins Received'
            : '⚠️ Coins Deducted';
        icon = Icons.verified_user;
        bgColor = const Color(0xFFEDE7F6);
        borderColor = const Color(0xFF9575CD);
        iconBgColor = const Color(0xFF673AB7);
        break;
      case "Purchase":
        titleText = "Profile Purchase";
        subtitleText = '🛒 ${reward['profile_name']}';
        icon = Icons.shopping_cart;
        bgColor = const Color(0xFFE3F2FD);
        borderColor = const Color(0xFF64B5F6);
        iconBgColor = const Color(0xFF2196F3);
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [iconBgColor, iconBgColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: iconBgColor.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        title: Text(
          titleText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.brown[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              subtitleText,
              style: const TextStyle(
                fontSize: 11.9,
                fontWeight: FontWeight.w500,
                color: Colors.deepOrange,
              ),
            ),
            if (formattedDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '📅 $formattedDate',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: iconBgColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: iconBgColor.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on, color: iconBgColor, size: 18),
              const SizedBox(width: 4),
              Text(
                '${displayCoins > 0 ? '+' : ''}$displayCoins',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: iconBgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCoinsSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 115, 115, 115),
            Color.fromARGB(255, 255, 255, 255), // เริ่มต้น
            Color.fromARGB(255, 175, 175, 175),
          ], // สิ้นสุด
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Total Coins',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 89, 88, 88),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Color.fromARGB(255, 0, 0, 0),
                size: 36,
              ),
              const SizedBox(width: 10),
              Text(
                '$totalCoins',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'From ${rewardHistory.length} Activities',
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 102, 101, 101),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: const Color.fromARGB(255, 233, 232, 231),

          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF7F4EF),

              const Color(0xFFF7F4EF),

              const Color(0xFFF7F4EF),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF8B4513), size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Reward History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 57, 56, 56),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${rewardHistory.length} items',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA0522D)),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your rewards...',
              style: TextStyle(color: Colors.brown[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.brown[400]),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchRewardHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA0522D),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (rewardHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Colors.brown[200],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Rewards Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchRewardHistory,
      color: const Color(0xFFA0522D),
      backgroundColor: const Color(0xFFCEBFA3),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: rewardHistory.length,
        itemBuilder: (context, index) =>
            _buildRewardTile(rewardHistory[index], index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 233, 232, 231),
      appBar: AppBar(
        title: Text(
          'Coin History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Color.fromARGB(255, 255, 255, 255),
            shadows: [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 229, 210, 173),
        elevation: 0,
        centerTitle: true,
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
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 233, 232, 231),
              const Color.fromARGB(255, 233, 232, 231),
            ],
          ),
        ),
        child: Column(
          children: [_buildTotalCoinsSection(), _buildHistorySection()],
        ),
      ),
    );
  }
}
