// lib/elegant_login.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'student_feed.dart';
import 'landlord_dashboard.dart';
import 'elegant_register.dart';
import 'landlord_home.dart';


class ElegantLoginScreen extends StatefulWidget {
  const ElegantLoginScreen({super.key});

  @override
  State<ElegantLoginScreen> createState() => _ElegantLoginScreenState();
}

class _ElegantLoginScreenState extends State<ElegantLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleSignIn() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your credentials')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    
    // The login method should return a string (null on success, error message on failure)
    // or you can modify this based on your exact AuthService implementation.
    dynamic loginResult = await auth.login(username, password);

    setState(() => _isLoading = false);

    if (!mounted) return;

    // Check if the login was successful. 
    // This supports both a boolean true or a null error response from auth_service.
    bool isSuccess = (loginResult == true || loginResult == null);

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome back, $username!')),
      );
            // Dynamic Role Routing Logic - Now updated for landlord_home.dart
      if (auth.userRole == 'landlord') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandlordHomeScreen()), // ◄ UPDATE THIS VIEW TARGET
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentFeedScreen()),
        );
      }

    } else {
      // Pull the real error message from the backend if provided, otherwise fall back.
      String errorMessage = 'Access Denied. Check your backend credentials.';
      if (loginResult is String && loginResult.isNotEmpty) {
        errorMessage = loginResult;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.holiday_village_rounded, size: 80, color: Colors.white),
              const SizedBox(height: 12),
              const Text('Campus Stay', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              const Text('Premium Accommodation Engine', style: TextStyle(fontSize: 14, color: Colors.white70)),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome Back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FD),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF3F51B5)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignIn(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FD),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF3F51B5)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3F51B5),
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ElegantRegisterScreen()),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            children: [
                              TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign Up Now',
                                style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
