import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'realtime_chat.dart';

class StudentChatsInboxScreen extends StatefulWidget {
  const StudentChatsInboxScreen({super.key});

  @override
  State<StudentChatsInboxScreen> createState() => _StudentChatsInboxScreenState();
}

class _StudentChatsInboxScreenState extends State<StudentChatsInboxScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentConversations();
  }

  Future<void> _fetchStudentConversations() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _conversations = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('My Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchStudentConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3F51B5)))
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No active conversations yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final chat = _conversations[index];
                    
                    // 🔍 MATCHES YOUR DJANGO SERIALIZER FIELDS EXACTLY
                    final String landlordName = chat['landlord_username'] ?? 'Landlord Manager';
                    final String propertyTitle = chat['property_title'] ?? 'Accommodation';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF3F51B5).withOpacity(0.1),
                          child: const Icon(Icons.business_rounded, color: Color(0xFF3F51B5)),
                        ),
                        title: Text(landlordName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Housing re: $propertyTitle', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RealTimeChatScreen(
                                chatRoom: {
                                  'id': chat['id'], // ◄ Passes the real ChatRoom ID (e.g. 2) perfectly!
                                  'title': landlordName,
                                },
                              ),
                            ),
                          ).then((_) => _fetchStudentConversations());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
