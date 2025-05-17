import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/io_client.dart';

class ChatbotTab extends StatefulWidget {
  const ChatbotTab({Key? key}) : super(key: key);

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _lastFailedMessage;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const ChatMessage(
        text: "Hello! I'm your Banana Farming Assistant. How can I help you today?",
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitted(String text, {bool isRetry = false}) async {
    if (text.trim().isEmpty) return;

    if (!isRetry) {
      _messageController.clear();
      setState(() {
        _messages.add(
          ChatMessage(
            text: text,
            isUser: true,
          ),
        );
      });
    }

    setState(() {
      _isLoading = true;
      _lastFailedMessage = text;
    });

    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);
      final client = IOClient(httpClient);

      final uri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/chat');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      final body = <String, String>{'message': text}; // Only send the message

      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        String botMessage;
        if (responseData.isNotEmpty) {
          botMessage = responseData.values.first.toString().replaceAll(RegExp(r'\\boxed\{|\}'), '');
        } else {
          botMessage = 'Sorry, I couldn’t process your request.';
        }

        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: botMessage,
                isUser: false,
              ),
            );
          });
        }
      } else {
        throw Exception('Failed to get response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      String errorMessage = 'Error: Could not connect to the server. Please check your internet connection or try again.';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'Error: Server connection timed out. Tap to retry or try again later.';
      } else if (e.toString().contains('HttpException')) {
        errorMessage = 'Error: Invalid server address. Please contact support.';
      }
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: errorMessage,
              isUser: false,
              onRetry: e.toString().contains('SocketException')
                  ? () => _handleSubmitted(text, isRetry: true)
                  : null,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.green[800]),
                const SizedBox(height: 20),
                Text(
                  'Banana Assist',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Ask me anything about our products and services!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(8.0),
            reverse: true,
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (_, index) {
              if (_isLoading && index == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text('BA'),
                      ),
                      SizedBox(width: 8.0),
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Processing...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final messageIndex = _isLoading ? index - 1 : index;
              return _messages[_messages.length - messageIndex - 1];
            },
          ),
        ),
        const Divider(height: 1.0),
        Container(
          decoration: BoxDecoration(color: Theme.of(context).cardColor),
          child: _buildTextComposer(),
        ),
      ],
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Send a message',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12.0),
              ),
              onSubmitted: _isLoading ? null : _handleSubmitted,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.green[800]),
            onPressed: _isLoading ? null : () => _handleSubmitted(_messageController.text),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final VoidCallback? onRetry;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              CircleAvatar(
                backgroundColor: Colors.green[800],
                child: const Text('BA'),
              ),
            const SizedBox(width: 8.0),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isUser
                      ? Colors.green[100]
                      : (onRetry != null ? Colors.red[100] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isUser ? Colors.green[900] : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            if (isUser)
              CircleAvatar(
                backgroundColor: Colors.green[600],
                child: const Icon(Icons.person, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}