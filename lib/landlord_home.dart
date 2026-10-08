// lib/landlord_home.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'landlord_dashboard.dart';
import 'realtime_chat.dart';

class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _myChats = [];
  List<dynamic> _myProperties = [];

  bool _isLoadingChats = true;
  bool _isLoadingProperties = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _fetchInitialData();
  }

  void _fetchInitialData() {
    _fetchLandlordChats();
    _fetchLandlordProperties();
  }

  // 📥 FETCH INCOMING CHAT SESSIONS FROM DB
  Future<void> _fetchLandlordChats() async {
    final auth = Provider.of<AuthService>(
      context,
      listen: false,
    );

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
          _myChats = jsonDecode(response.body);
          _isLoadingChats = false;
        });
      } else {
        setState(() => _isLoadingChats = false);
      }
    } catch (e) {
      setState(() => _isLoadingChats = false);
    }
  }

  // 📥 FETCH ALL PROPERTIES UPLOADED BY THIS LOGGED-IN LANDLORD
  Future<void> _fetchLandlordProperties() async {
    final auth = Provider.of<AuthService>(
      context,
      listen: false,
    );

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/properties/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> allProperties = jsonDecode(response.body);

        // Filter elements locally down to entries belonging
        // to this landlord's ID.
        setState(() {
          _myProperties = allProperties
              .where(
                (element) =>
                    element['landlord'].toString() ==
                    auth.userId.toString(),
              )
              .toList();

          _isLoadingProperties = false;
        });
      } else {
        setState(() => _isLoadingProperties = false);
      }
    } catch (e) {
      setState(() => _isLoadingProperties = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Landlord Console',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchInitialData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();

              if (context.mounted) {
                Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                );
              }
            },
          ),
        ],

        // 🗂️ PREALS TAB SWITCHER GATEWAYS
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              text: 'Enquiries',
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
              ),
            ),
            Tab(
              text: 'My Properties',
              icon: Icon(
                Icons.domain_rounded,
                size: 20,
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Action Card: Post a New Listing
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1A237E),
                    Color(0xFF3F51B5),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need to list another property?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Expand Your Complex Catalog',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LandlordDashboardScreen(),
                        ),
                      ).then(
                        (_) => _fetchInitialData(),
                      );
                    },
                    icon: const Icon(
                      Icons.add_home_work_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Add Room Listing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF3F51B5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🗂️ MAIN TAB CONTENT VIEW DISPLAY STREAM
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // VIEW TAB 1: INCOMING STUDENT CHATS LIST
                  _isLoadingChats
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3F51B5),
                          ),
                        )
                      : _myChats.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.maps_ugc_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No student enquiries yet.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _myChats.length,
                              itemBuilder: (context, index) {
                                final chat = _myChats[index];

                                final String studentName =
                                    chat['student_username'] ?? 'Student';

                                final String propertyTitle =
                                    chat['property_title'] ??
                                        'Accommodation Unit';

                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.01),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          const Color(0xFF3F51B5)
                                              .withOpacity(0.1),
                                      child: const Icon(
                                        Icons.person,
                                        color: Color(0xFF3F51B5),
                                      ),
                                    ),
                                    title: Text(
                                      studentName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Inquiring about: $propertyTitle',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RealTimeChatScreen(
                                            chatRoom: {
                                              'id': chat['id'],
                                              'title': studentName,
                                            },
                                          ),
                                        ),
                                      ).then(
                                        (_) => _fetchInitialData(),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),

                  // VIEW TAB 2: MY UPLOADED PROPERTY LIST CATALOG
                  _isLoadingProperties
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3F51B5),
                          ),
                        )
                      : _myProperties.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.home_work_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "You haven't listed any properties yet.",
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _myProperties.length,
                              itemBuilder: (context, index) {
                                final prop = _myProperties[index];

                                final List rooms =
                                    prop['rooms'] ?? [];

                                String priceTag = 'No Rooms';
                                String? imageUrl;

                                if (rooms.isNotEmpty) {
                                  priceTag =
                                      '\$${rooms.first['rent_price']}/mo';

                                  List imgs =
                                      rooms.first['images'] ?? [];

                                  if (imgs.isNotEmpty) {
                                    imageUrl = imgs.first['image_url'] ??
                                        imgs.first['image'];

                                    if (imageUrl != null &&
                                        imageUrl.startsWith('/')) {
                                      imageUrl =
                                          'http://127.0.0.1:8000' +
                                              imageUrl;
                                    }
                                  }
                                }

                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.01),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.all(12),
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color:
                                            const Color(0xFFE8EAF6),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: imageUrl != null
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (c, e, s) =>
                                                        const Icon(
                                                  Icons.home_work,
                                                  color: Color(
                                                    0xFF3F51B5,
                                                  ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.home_work,
                                                color: Color(
                                                  0xFF3F51B5,
                                                ),
                                              ),
                                      ),
                                    ),
                                    title: Text(
                                      prop['title'] ?? 'Property',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${prop['distance_from_campus_km']} km to Campus • $priceTag',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Live',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}