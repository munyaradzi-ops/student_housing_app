import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'auth_service.dart';

class RealTimeChatScreen extends StatefulWidget {
  final Map<String, dynamic> chatRoom;

  const RealTimeChatScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<RealTimeChatScreen> createState() => _RealTimeChatScreenState();
}

class _RealTimeChatScreenState extends State<RealTimeChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  WebSocketChannel? _channel;
  List<dynamic> _messages = [];
  bool _isLoadingMessages = true;

  final String _httpBaseUrl = 'http://127.0.0.1:8000';
  final String _wsBaseUrl = 'ws://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    _fetchMessageHistory(); 
    _connectWebSocket();
  }

  Future<void> _fetchMessageHistory() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final roomId = widget.chatRoom['id'];

    try {
      final response = await http.get(
        Uri.parse('$_httpBaseUrl/api/chats/$roomId/messages/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages = jsonDecode(response.body);
          _isLoadingMessages = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isLoadingMessages = false);
      }
    } catch (e) {
      setState(() => _isLoadingMessages = false);
    }
  }

  void _connectWebSocket() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final roomId = widget.chatRoom['id'];

    _channel = WebSocketChannel.connect(
      Uri.parse('$_wsBaseUrl/ws/chat/$roomId/?token=${auth.token}'),
    );

    _channel!.stream.listen(
      (data) {
        final Map<String, dynamic> incomingMessage = jsonDecode(data);
        setState(() {
          _messages.add(incomingMessage);
        });
        _scrollToBottom();
      },
      onError: (error) {
        debugPrint('WebSocket Error: $error');
      },
      onDone: () {
        debugPrint('WebSocket closed.');
      },
    );
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final auth = Provider.of<AuthService>(context, listen: false);

    final payload = {
      'message': messageText,
      'sender_id': auth.userId ?? 1, 
    };

    _channel?.sink.add(jsonEncode(payload));
    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final String title = widget.chatRoom['title'] ?? 'Chat Session';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingMessages
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3F51B5)))
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hello!', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          
                          // Safe Parsing Layer
                          final dynamic rawSender = msg['sender'] ?? msg['sender_id'];
                          String msgSenderIdStr = '';
                          String msgSenderUsername = (msg['sender_username'] ?? '').toString().trim().toLowerCase();
                          
                          if (rawSender is Map) {
                            msgSenderIdStr = (rawSender['id'] ?? '').toString();
                          } else if (rawSender != null) {
                            msgSenderIdStr = rawSender.toString().trim();
                          }
                          
                          final String currentUserIdStr = auth.userId?.toString().trim() ?? '';
                          final String chatTitleClean = title.trim().toLowerCase();

                          // 🛡️ LEVEL 1: Primary ID Matching Block
                          bool isMyMessage = (msgSenderIdStr == currentUserIdStr && currentUserIdStr.isNotEmpty);
                          
                          // 🛡️ LEVEL 2: String Text Username Fallback Engine
                          // If the message has an explicit text username string parameter attached, check who sent it
                          if (!isMyMessage && msgSenderUsername.isNotEmpty) {
                            if (auth.userRole == 'student') {
                              // If I am logged in as a Student, any message NOT containing the Landlord's name title belongs to ME!
                              isMyMessage = msgSenderUsername != chatTitleClean;
                            } else if (auth.userRole == 'landlord') {
                              // If I am logged in as a Landlord, any message NOT containing the Student's name title belongs to ME!
                              isMyMessage = msgSenderUsername != chatTitleClean;
                            }
                          }

                          // 🛡️ LEVEL 3: WebSocket Live Broadcast Fallback Sorter
                          // For instantaneous WebSocket messages that arrive without a nested object mapping format
                          if (!isMyMessage && msgSenderUsername.isEmpty && currentUserIdStr.isEmpty) {
                            // If you just sent a text, and the payload matches the target fallback ID block structure
                            if (auth.userRole == 'student' && msgSenderIdStr == '1') {
                              isMyMessage = true;
                            } else if (auth.userRole == 'landlord' && msgSenderIdStr == '3') {
                              isMyMessage = true;
                            }
                          }

                          final String textContent = msg['text'] ?? msg['message'] ?? '';

                          return Align(
                            alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMyMessage ? const Color(0xFF3F51B5) : const Color(0xFFE8EAF6),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMyMessage ? 16 : 0),
                                  bottomRight: Radius.circular(isMyMessage ? 0 : 16),
                                ),
                              ),
                              child: Text(
                                textContent,
                                style: TextStyle(
                                  color: isMyMessage ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF3F51B5)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
