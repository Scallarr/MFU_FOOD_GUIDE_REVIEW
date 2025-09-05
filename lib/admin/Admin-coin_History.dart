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
  int totalCoins = 0;

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
        Uri.parse('http://10.0.3.201:8080/rewards-history/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('d: ${data}');

        setState(() {
          rewardHistory = data['history'] ?? [];
          totalCoins = data['total_coins'] ?? 0;
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
    final isLeaderboard = reward.containsKey('rank');
    // กำหนดค่า coins display
    final displayCoins = isLeaderboard
        ? reward['coins_awarded']
        : (reward['action_type'] == 'SUBTRACT'
              ? -reward['coins_awarded']
              : reward['coins_awarded']);

    final subtitle = isLeaderboard
        ? 'Rank: ${reward['rank']}'
        : '${reward['action_type']} by ${reward['admin_username']}';

    // สี
    Color bgColor = isLeaderboard ? const Color(0xFFF5EBD9) : Color(0xFFEDE7F6);
    Color borderColor = isLeaderboard
        ? const Color(0xFFD2B48C)
        : const Color(0xFFDEB887);
    Color iconBgColor = isLeaderboard
        ? const Color(0xFFA0522D)
        : const Color(0xFF512DA8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                iconBgColor,
                Color.alphaBlend(iconBgColor.withOpacity(0.7), Colors.white),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: iconBgColor.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isLeaderboard ? Icons.emoji_events : Icons.verified_user,
            color: Colors.white,
            size: 26,
          ),
        ),
        title: Text(
          _formatMonthYear(reward['month_year']),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.brown[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.brown[600]),
            ),
            if (!isLeaderboard && reward['reason'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Reason: ${reward['reason']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.brown[400],
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
            border: Border.all(color: iconBgColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on, color: iconBgColor, size: 18),
              const SizedBox(width: 4),
              Text(
                '${displayCoins > 0 ? '+' : ''}$displayCoins', // เพิ่ม + หน้าเลขบวก
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
        color: const Color.fromARGB(
          255,
          233,
          229,
          226,
        ), // Dark brown background
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 236, 232, 231),
            Color.fromARGB(255, 142, 142, 142),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.4),
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
              color: Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,

              // gradient: const LinearGradient(
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              //   colors: [Color(0xFFFFD54F), Color(0xFFFFB300)], // Gold gradient
              // ),
              // boxShadow: [
              //   BoxShadow(
              //     color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.4),
              //     blurRadius: 10,
              //     offset: const Offset(0, 5),
              //   ),
              // ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Color.fromARGB(255, 26, 25, 25),
                  size: 36,
                ),
                SizedBox(width: 10),
                const SizedBox(height: 8),
                Text(
                  '$totalCoins',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ],
            ),
          ),

          Text(
            'From ${rewardHistory.length} rewards',
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontSize: 14,
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
          color: Color(0xFFCEBFA3),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
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
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2B48C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${rewardHistory.length} items',
                      style: TextStyle(
                        color: Colors.brown[800],
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
      backgroundColor: const Color(0xFFCEBFA3),
      appBar: AppBar(
        title: const Text(
          'Coin History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B4513),
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFCEBFA3),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF8B4513)),
      ),
      body: Column(
        children: [_buildTotalCoinsSection(), _buildHistorySection()],
      ),
    );
  }
}
