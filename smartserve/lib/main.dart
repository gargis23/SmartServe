import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Import your existing screens
import 'screens/auth/login_screen.dart';
import 'screens/profile/profile_screen.dart';
// Import your new Role-Based screens (Create these files next)
import 'screens/admin/admin_dashboard.dart'; 
import 'screens/staff/staff_dashboard.dart';

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
          seedColor: Colors.orange,
          primary: Colors.orange,
        ),
        useMaterial3: true,
        // Global styling for buttons to match the PRD branding
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
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
        // 1. Initial connection check
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Check if the user is authenticated
        if (authSnapshot.hasData) {
          final String uid = authSnapshot.data!.uid;

          // 3. Fetch Role from Firestore (Point 3: RBAC)
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final String role = userData['role'] ?? 'student';

                // Point 3.3: Permission management via Navigation
                switch (role) {
                  case 'admin':
                    return const AdminDashboard();
                  case 'staff':
                    return const StaffDashboard();
                  default:
                    return const ProfileScreen();
                }
              }

              // Fallback if document is missing (log out and retry)
              return const LoginScreen();
            },
          );
        }

        // 4. Not authenticated
        return const LoginScreen();
      },
    );
  }
}