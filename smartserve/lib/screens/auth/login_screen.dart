import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    
    // loginUser usually expects positional arguments based on our previous setup
    var user = await _authService.loginUser(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return; // Handles the async gap warning
    setState(() => _isLoading = false);

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green),
      );
      // Navigation happens automatically if you updated main.dart with StreamBuilder
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Failed. Check your credentials."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Logo
                Row(
                  children: [
                    const Icon(Icons.restaurant, color: Color(0xFFFF6B6B), size: 40),
                    const SizedBox(width: 12),
                    Text(
                      'SmartServe',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFF6B6B), 
                        fontWeight: FontWeight.w900, 
                        fontSize: 36, 
                        letterSpacing: -1
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Welcome back,', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('Sign in to continue ordering.', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 48),

                // Email Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'College Email', 
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey), 
                      border: InputBorder.none, 
                      contentPadding: const EdgeInsets.all(16)
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password', 
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey), 
                      border: InputBorder.none, 
                      contentPadding: const EdgeInsets.all(16)
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Login', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24), 
                
                // Register Redirect
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      "Don't have an account? Register here",
                      style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ], 
            ),
          ),
        ),
      ),
    );
  }
}