
// lib/student_feed.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'realtime_chat.dart';
import 'student_chats_inbox.dart';

class StudentFeedScreen extends StatefulWidget {
  const StudentFeedScreen({super.key});

  @override
  State<StudentFeedScreen> createState() => _StudentFeedScreenState();
}

class _StudentFeedScreenState extends State<StudentFeedScreen> {
  List<dynamic> _properties = [];
  bool _isLoading = true;

  // 🏃 FILTER STATES
  double? _selectedMaxDistance;
  double _selectedMaxPrice = 500.0;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthService>(
      context,
      listen: false,
    );

    const String baseUrl = 'http://127.0.0.1:8000';

    final List<String> queryParams = [];

    if (_selectedMaxDistance != null) {
      queryParams.add(
        'max_distance=$_selectedMaxDistance',
      );
    }

    queryParams.add(
      'max_price=$_selectedMaxPrice',
    );

    String urlPath = '$baseUrl/api/properties/';

    if (queryParams.isNotEmpty) {
      urlPath += '?${queryParams.join('&')}';
    }

    try {
      final response = await http.get(
        Uri.parse(urlPath),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _properties = jsonDecode(response.body);
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
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Available Housing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'My Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const StudentChatsInboxScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Logout',
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
      ),
      body: Column(
        children: [
          // MULTI-FILTER DASHBOARD PANEL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF3F51B5),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // DISTANCE FILTER
                Row(
                  children: [
                    const Icon(
                      Icons.directions_walk_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Distance:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double?>(
                            value: _selectedMaxDistance,
                            hint: const Text(
                              'Show All Distances',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Color(0xFF3F51B5),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'All Distances',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 0.5,
                                child: Text(
                                  'Within 0.5 km (Very Close)',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 1.0,
                                child: Text(
                                  'Within 1.0 km',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 2.0,
                                child: Text(
                                  'Within 2.0 km',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 5.0,
                                child: Text(
                                  'Within 5.0 km',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                            onChanged: (double? newValue) {
                              setState(() {
                                _selectedMaxDistance = newValue;
                              });

                              _fetchProperties();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // MAXIMUM BUDGET PRICE SLIDER
                Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Max Price: \$${_selectedMaxPrice.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _selectedMaxPrice,
                        min: 50.0,
                        max: 500.0,
                        divisions: 9,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                        label:
                            '\$${_selectedMaxPrice.toInt()}',
                        onChanged: (double newValue) {
                          setState(() {
                            _selectedMaxPrice = newValue;
                          });
                        },
                        onChangeEnd: (double finalValue) {
                          _fetchProperties();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Feed ListView
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3F51B5),
                    ),
                  )
                : _properties.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list_off_rounded,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No listings fit these filter boundaries.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _properties.length,
                        itemBuilder: (context, index) {
                          final Map<String, dynamic> item =
                              Map<String, dynamic>.from(
                            _properties[index],
                          );

                          final List<dynamic> roomsList =
                              item['rooms'] ?? [];

                          String displayedPrice = 'N/A';
                          String? roomImageUrl;
                          String rawAmenities = '';

                          if (roomsList.isNotEmpty) {
                            final firstRoom = roomsList.first;

                            if (firstRoom['rent_price'] != null) {
                              displayedPrice =
                                  '\$${firstRoom['rent_price']}';
                            }

                            // Capture amenities string from database.
                            rawAmenities =
                                firstRoom['amenities'] ?? '';

                            final List<dynamic> imagesList =
                                firstRoom['images'] ?? [];

                            if (imagesList.isNotEmpty) {
                              final firstImageObj =
                                  imagesList.first;

                              roomImageUrl =
                                  firstImageObj['image_url'] ??
                                      firstImageObj['image'];

                              if (roomImageUrl != null &&
                                  roomImageUrl.startsWith('/')) {
                                roomImageUrl =
                                    'http://127.0.0.1:8000'
                                    '$roomImageUrl';
                              }
                            }
                          }

                          // Split comma-separated amenities
                          // into a list for displaying badges.
                          final List<String> parsedAmenities =
                              rawAmenities
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where(
                                    (e) => e.isNotEmpty,
                                  )
                                  .toList();

                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.03),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // PROPERTY IMAGE
                                Container(
                                  height: 180,
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8EAF6),
                                    borderRadius:
                                        BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius:
                                        const BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                    child: roomImageUrl != null &&
                                            roomImageUrl.isNotEmpty
                                        ? Image.network(
                                            roomImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Center(
                                                child: Icon(
                                                  Icons
                                                      .broken_image_outlined,
                                                  size: 48,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons
                                                  .holiday_village_outlined,
                                              size: 48,
                                              color:
                                                  Color(0xFF3F51B5),
                                            ),
                                          ),
                                  ),
                                ),

                                // PROPERTY DETAILS
                                Padding(
                                  padding:
                                      const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // TITLE AND PRICE
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['title'] ??
                                                  'Listing',
                                              style:
                                                  const TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color:
                                                    Color(0xFF1E293B),
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                30,
                                              ),
                                            ),
                                            child: Text(
                                              displayedPrice,
                                              style:
                                                  const TextStyle(
                                                color: Colors.green,
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      // ADDRESS
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item['address'] ??
                                                  'Near Campus',
                                              style:
                                                  const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // DESCRIPTION
                                      Text(
                                        item['description'] ??
                                            'No description provided.',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),

                                      // 🏷️ DYNAMIC AMENITIES
                                      if (parsedAmenities.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: parsedAmenities
                                              .map(
                                                (amenity) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: const Color(
                                                        0xFF3F51B5,
                                                      ).withOpacity(0.06),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                        8,
                                                      ),
                                                      border:
                                                          Border.all(
                                                        color: const Color(
                                                          0xFF3F51B5,
                                                        ).withOpacity(0.12),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      amenity,
                                                      style:
                                                          const TextStyle(
                                                        color: Color(
                                                          0xFF3F51B5,
                                                        ),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                              .toList(),
                                        ),
                                      ],

                                      const Divider(height: 28),

                                      // DISTANCE AND CONTACT
                                      Row(
                                        children: [
                                          const Text(
                                            '🏃 ',
                                            style: TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '${item['distance_from_campus_km']} '
                                            'km to Campus',
                                            style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              color:
                                                  Color(0xFF3F51B5),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const Spacer(),
                                          ElevatedButton(
                                            style: ElevatedButton
                                                .styleFrom(
                                              backgroundColor:
                                                  const Color(
                                                0xFF3F51B5,
                                              ),
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 20,
                                                vertical: 12,
                                              ),
                                              shape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(12),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      RealTimeChatScreen(
                                                    chatRoom: {
                                                      'id':
                                                          item['id'] ??
                                                              1,
                                                      'title':
                                                          item['title'] ??
                                                              'Chat with Landlord',
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'Contact',
                                              style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
