import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Check if user is logged in
        if (snapshot.hasData) {
          // 2. User exists, now check their ROLE in Firestore
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                String role = userSnapshot.data!['role'];

                // 3. Member 1 Logic: Redirect based on Role
                if (role == 'admin') return const AdminDashboard(); // Create these placeholder screens
                if (role == 'staff') return const StaffDashboard();
                return const StudentDashboard(); // Default to Student
              }
              
              return const LoginScreen();
            },
          );
        }
        // 4. No user logged in
        return const LoginScreen();
      },
    );
  }
}

// Placeholder Screens for your teammates (Members 2 & 3)
class AdminDashboard extends StatelessWidget { const AdminDashboard({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Admin Dashboard"))); }
class StaffDashboard extends StatelessWidget { const StaffDashboard({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Staff Dashboard"))); }
class StudentDashboard extends StatelessWidget { const StudentDashboard({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Student Dashboard"))); }