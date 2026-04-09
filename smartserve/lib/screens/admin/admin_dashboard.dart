import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_management_screen.dart'; // We will create this next

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "System Overview",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Member 1 - Task 4: User Management Entry
            Card(
              child: ListTile(
                leading: const Icon(Icons.group, color: Colors.orange),
                title: const Text("Manage Users"),
                subtitle: const Text("Update roles and permissions"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                  );
                },
              ),
            ),
            // Placeholder for Member 4's Analytics
            const Card(
              child: ListTile(
                leading: Icon(Icons.analytics, color: Colors.blue),
                title: Text("Canteen Analytics"),
                subtitle: Text("Coming soon (Member 4 task)"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}