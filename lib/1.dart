import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Mentions Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MentionDemo(),
    );
  }
}

class MentionDemo extends StatefulWidget {
  const MentionDemo({super.key});

  @override
  State<MentionDemo> createState() => _MentionDemoState();
}

class _MentionDemoState extends State<MentionDemo> {
  final GlobalKey<FlutterMentionsState> _mentionsKey = GlobalKey();

  final List<Map<String, dynamic>> _users = [
    {'id': '1', 'display': 'kasidit', 'full_name': 'Kasidit Kosit'},
    {'id': '2', 'display': 'nattapong', 'full_name': 'Nattapong Thongchai'},
    {'id': '3', 'display': 'supaporn', 'full_name': 'Supaporn Wongyai'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mention Input Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FlutterMentions(
              key: _mentionsKey,
              suggestionPosition: SuggestionPosition.Bottom,
              maxLines: 5,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Type your message with @mention',
                border: OutlineInputBorder(),
              ),
              mentions: [
                Mention(
                  trigger: '@',
                  style: const TextStyle(color: Colors.blue),
                  data: _users,
                  matchAll: false,
                  suggestionBuilder: (data) {
                    return ListTile(
                      title: Text(data['full_name']),
                      subtitle: Text('@${data['display']}'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final text = _mentionsKey.currentState?.controller?.text ?? '';
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Your Message'),
                    content: Text(text),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show Text'),
            ),
          ],
        ),
      ),
    );
  }
}
