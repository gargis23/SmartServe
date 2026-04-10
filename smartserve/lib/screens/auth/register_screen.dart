import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  String _selectedRole = 'student';
  final List<String> _roles = ['student', 'staff', 'admin'];

  bool _isLoading = false;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Using positional arguments to match your AuthService definition
      final user = await _authService.registerUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _selectedRole,
      );

      // Added mounted check before using BuildContext across async gap
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully! Please Login."), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed. Please check your details."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Logo
                Row(
                  children: [
                    const Icon(Icons.restaurant, color: Color(0xFFFF6B6B), size: 40),
                    const SizedBox(width: 12),
                    Text(
                      'SmartServe',
                      style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.w900, fontSize: 36, letterSpacing: -1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Join Us,', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('Create an account to start ordering.', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 40),

                // Name Field
                _buildPremiumTextField(
                  controller: _nameController,
                  hintText: "Full Name",
                  icon: Icons.person_outline,
                  validator: (val) => val!.isEmpty ? "Enter your name" : null,
                ),
                const SizedBox(height: 16),

                // Email Field
                _buildPremiumTextField(
                  controller: _emailController,
                  hintText: "College Email",
                  icon: Icons.email_outlined,
                  validator: (val) => val!.contains("@") ? null : "Enter a valid email",
                ),
                const SizedBox(height: 16),

                // Password Field
                _buildPremiumTextField(
                  controller: _passwordController,
                  hintText: "Password",
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (val) => val!.length < 6 ? "Minimum 6 characters" : null,
                ),
                const SizedBox(height: 16),

                // Role Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: Colors.grey),
                      border: InputBorder.none, 
                      contentPadding: EdgeInsets.all(16),
                    ),
                    items: _roles.map((role) => DropdownMenuItem(
                      value: role, 
                      child: Text(role.toUpperCase(), style: GoogleFonts.inter(color: Colors.black87))
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val as String),
                  ),
                ),
                const SizedBox(height: 40),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text("REGISTER", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),

                // Back to Login Link
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Already have an account? Login here",
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

  // Helper widget to keep code clean
  Widget _buildPremiumTextField({
    required TextEditingController controller, 
    required String hintText, 
    required IconData icon, 
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText, 
          hintStyle: GoogleFonts.inter(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey), 
          border: InputBorder.none, 
          contentPadding: const EdgeInsets.all(16)
        ),
      ),
    );
  }
}