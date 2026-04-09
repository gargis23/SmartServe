import 'package:flutter/material.dart';
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
      
      // FIXED: Using positional arguments to match your AuthService definition
      final user = await _authService.registerUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _selectedRole,
      );

      // FIXED: Added mounted check before using BuildContext across async gap
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully! Please Login.")),
        );
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed. Please check your details.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join SmartServe")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Create an Account",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? "Enter your name" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email Address", border: OutlineInputBorder()),
                  validator: (val) => val!.contains("@") ? null : "Enter a valid email",
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                  validator: (val) => val!.length < 6 ? "Minimum 6 characters" : null,
                ),
                const SizedBox(height: 20),
                // FIXED: Changed 'value' to 'initialValue' for modern Flutter versions
                DropdownButtonFormField(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(labelText: "I am a...", border: OutlineInputBorder()),
                  items: _roles.map((role) => DropdownMenuItem(
                    value: role, 
                    child: Text(role.toUpperCase()))
                  ).toList(),
                  onChanged: (val) => setState(() => _selectedRole = val as String),
                ),
                const SizedBox(height: 30),
                _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _handleRegister,
                      child: const Text("REGISTER", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}