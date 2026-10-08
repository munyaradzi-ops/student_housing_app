// lib/property_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PropertyService {
  final String _propertyUrl ='http://127.0.0.1:8000';
  final String _roomUrl ='http://127.0.0.1:8000';

  Future<bool> createFullListingWithImage({
    required String token,
    required int landlordId,
    required String title,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required double distanceFromCampus,
    required String roomNumber,
    required double rentPrice,
    required bool isAvailable,
    required String amenities,
    required XFile? imageFile, // ◄ Accepts the picked image file
  }) async {
    try {
      // 1. Post the Property data frame
      final propResponse = await http.post(
        Uri.parse('$_propertyUrl/api/properties/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'landlord': landlordId,
          'title': title,
          'description': description,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'distance_from_campus_km': distanceFromCampus,
        }),
      );

      if (propResponse.statusCode != 201) return false;

      final createdProperty = jsonDecode(propResponse.body);
      final int propertyId = createdProperty['id'];

      // 2. Post the Room data frame using a Multipart Request to support image streams
      var request = http.MultipartRequest('POST', Uri.parse('$_roomUrl/api/rooms/'));
      
      // Attach the Authorization Headers
      request.headers['Authorization'] = 'Bearer $token';

      // Attach text form fields
      request.fields['property'] = propertyId.toString();
      request.fields['room_number'] = roomNumber;
      request.fields['rent_price'] = rentPrice.toStringAsFixed(2);
      request.fields['is_available'] = isAvailable.toString();
      request.fields['amenities'] = amenities;

      // 3. If an image was selected, convert it into stream bytes and attach it
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'image', // ◄ Matches the ListField/File field name your DRF expects
          bytes,
          filename: imageFile.name,
        );
        request.files.add(multipartFile);
      }

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Room Image Upload Rejected: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Multi-part request execution error: $e");
      return false;
    }
  }
}
