
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'property_service.dart';

class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  State<LandlordDashboardScreen> createState() =>
      _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState
    extends State<LandlordDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _distanceController = TextEditingController();

  final _roomNumberController = TextEditingController();
  final _priceController = TextEditingController();
  final _amenitiesController = TextEditingController();

  bool _isAvailable = true;
  XFile? _selectedImage;
  bool _isPublishing = false;

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  void _handlePublishListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);

    final auth = Provider.of<AuthService>(
      context,
      listen: false,
    );

    final propService = Provider.of<PropertyService>(
      context,
      listen: false,
    );

    double distanceMetric = double.parse(
      _distanceController.text.trim().replaceAll(',', '.'),
    );

    double rentPriceMetric = double.parse(
      _priceController.text.trim().replaceAll(',', '.'),
    );

    bool success = await propService.createFullListingWithImage(
      token: auth.token ?? '',
      landlordId: auth.userId ?? 1,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      address: _addressController.text.trim(),
      latitude: -19.4593,
      longitude: 29.8510,
      distanceFromCampus: distanceMetric,
      roomNumber: _roomNumberController.text.trim(),
      rentPrice: rentPriceMetric,
      isAvailable: _isAvailable,
      amenities: _amenitiesController.text.trim(),
      imageFile: _selectedImage,
    );

    setState(() => _isPublishing = false);

    if (success) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✨ Complete House, Room, & Image Published Live!',
          ),
        ),
      );

      _titleController.clear();
      _descController.clear();
      _addressController.clear();
      _distanceController.clear();
      _roomNumberController.clear();
      _priceController.clear();
      _amenitiesController.clear();

      setState(() {
        _selectedImage = null;
        _isAvailable = true;
      });
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Submission failed. Check your validation formats.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _distanceController.dispose();
    _roomNumberController.dispose();
    _priceController.dispose();
    _amenitiesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),

      appBar: AppBar(
        title: const Text(
          'Landlord Console Manager',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complex Specifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                validator: (val) => val!.isEmpty
                    ? 'Enter property complex title name'
                    : null,
                decoration: InputDecoration(
                  labelText: 'Property Complex Name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                validator: (val) => val!.isEmpty
                    ? 'Enter a physical location address'
                    : null,
                decoration: InputDecoration(
                  labelText: 'Physical Street Address',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) => val!.isEmpty
                    ? 'Specify distance mapping index metrics'
                    : null,
                decoration: InputDecoration(
                  labelText: 'Distance from Campus Gate (km)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                validator: (val) => val!.isEmpty
                    ? 'Describe the main residential property settings'
                    : null,
                decoration: InputDecoration(
                  labelText: 'Property Summary Profile Description',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(),
              ),

              const Text(
                'Individual Room Specifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roomNumberController,
                      validator: (val) => val!.isEmpty
                          ? 'Room No. Required'
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Room Number',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) => val!.isEmpty
                          ? 'Price Required'
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Rent Fee (\$/Month)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _amenitiesController,
                decoration: InputDecoration(
                  labelText:
                      'Amenities (e.g., WiFi, Bed, Wardrobe, AC)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickImage,

                child: Container(
                  width: double.infinity,
                  height: 120,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3F51B5)
                          .withOpacity(0.25),
                      style: BorderStyle.solid,
                    ),
                  ),

                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: Color(0xFF3F51B5),
                              size: 32,
                            ),

                            SizedBox(height: 8),

                            Text(
                              'Select Room Picture',
                              style: TextStyle(
                                color: Color(0xFF3F51B5),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.all(16),
                          color: const Color(0xFFE8EAF6),

                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.file_present_rounded,
                                color: Colors.green,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  _selectedImage!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [
                    const Text(
                      'Mark Room Available for Booking Now',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    Switch(
                      value: _isAvailable,
                      activeColor: const Color(0xFF3F51B5),
                      onChanged: (val) =>
                          setState(() => _isAvailable = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              _isPublishing
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3F51B5),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _handlePublishListing,

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF3F51B5),
                        minimumSize:
                            const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),

                      child: const Text(
                        'Publish Entire Housing Record',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}