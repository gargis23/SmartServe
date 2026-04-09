import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart'; // FIXED: Missing import for RegisterScreen

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

    if (!mounted) return; // FIXED: Handles the async gap warning
    setState(() => _isLoading = false);

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful!")),
      );
      // Navigation happens automatically if you updated main.dart with StreamBuilder
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Failed. Check your credentials.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SmartServe Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController, 
              decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController, 
              decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()), 
              obscureText: true
            ),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _handleLogin,
                  child: const Text("Login"),
                ),
            const SizedBox(height: 10), // FIXED: Now correctly placed inside the Column list
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text("Don't have an account? Register here"),
            ),
          ], // End of Column children list
        ),
      ),
    );
  }
}