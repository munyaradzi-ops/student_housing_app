// lib/elegant_register.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ElegantRegisterScreen extends StatefulWidget {
  const ElegantRegisterScreen({super.key});

  @override
  State<ElegantRegisterScreen> createState() => _ElegantRegisterScreenState();
}

class _ElegantRegisterScreenState extends State<ElegantRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedRole = 'student'; 
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Corrected to hit your explicit Django app routing path with trailing slash
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': _selectedRole,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully! Please sign in.')),
        );
        Navigator.pop(context); 
      } else {
        final errorData = jsonDecode(response.body);
        // Handle array validation responses smoothly from Django REST Framework
        String errorMsg = 'Registration failed. Try again.';
        if (errorData['username'] != null && errorData['username'] is List) {
          errorMsg = errorData['username'][0];
        } else if (errorData['detail'] != null) {
          errorMsg = errorData['detail'];
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Is your Django backend live?')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Join Campus Stay', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 6),
              const Text('Find local student rooms or manage listing contracts.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 28),
              
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('I am a Student')),
                      selected: _selectedRole == 'student',
                      selectedColor: const Color(0xFF3F51B5).withOpacity(0.15),
                      labelStyle: TextStyle(color: _selectedRole == 'student' ? const Color(0xFF3F51B5) : Colors.black87, fontWeight: FontWeight.bold),
                      onSelected: (val) => setState(() => _selectedRole = 'student'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('I am a Landlord')),
                      selected: _selectedRole == 'landlord',
                      selectedColor: const Color(0xFF3F51B5).withOpacity(0.15),
                      labelStyle: TextStyle(color: _selectedRole == 'landlord' ? const Color(0xFF3F51B5) : Colors.black87, fontWeight: FontWeight.bold),
                      onSelected: (val) => setState(() => _selectedRole = 'landlord'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _usernameController,
                validator: (val) => val!.isEmpty ? 'Enter a valid username' : null,
                decoration: InputDecoration(
                  labelText: 'Username',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF3F51B5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address (Optional)',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF3F51B5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF3F51B5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF3F51B5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),

              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3F51B5)))
                  : ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
