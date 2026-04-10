import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Import your existing screens
import 'screens/auth/login_screen.dart';
import 'screens/profile/profile_screen.dart';
// Import your new Role-Based screens
import 'screens/admin/admin_dashboard.dart'; 
import 'screens/staff/staff_dashboard.dart';
// Add the import for your new Menu Home Screen!
import 'screens/menu/menu_home_screen.dart'; 
import 'screens/home/student_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartServeApp());
}

class SmartServeApp extends StatelessWidget {
  const SmartServeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartServe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          // FIX: Updated from Colors.orange to our brand color
          seedColor: const Color(0xFFFF6B6B),
          primary: const Color(0xFFFF6B6B),
        ),
        useMaterial3: true,
        // Global styling for buttons to match the PRD branding
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            // FIX: Updated to brand color
            backgroundColor: const Color(0xFFFF6B6B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// MEMBER 1: AuthGate handles Session Management & RBAC
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData) {
          final String uid = authSnapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                
                // FIX: Add .toLowerCase() to handle "STUDENT", "Student", or "student"
                final String role = (userData['role'] ?? 'student').toString().toLowerCase();

                switch (role) {
                  case 'admin':
                    return const AdminDashboard();
                  case 'staff':
                    return const StaffDashboard();
                  case 'student':
                  default:
                    // FIX: Route to the new Bottom Nav screen!
                    return const StudentMainScreen(); 
                }
              }

              return const LoginScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}