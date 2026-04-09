import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Roles")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var userDoc = snapshot.data!.docs[index];
              return ListTile(
                title: Text(userDoc['name']),
                subtitle: Text(userDoc['email']),
                trailing: DropdownButton<String>(
                  value: userDoc['role'],
                  items: ['student', 'staff', 'admin'].map((role) {
                    return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                  }).toList(),
                  onChanged: (newRole) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userDoc.id)
                        .update({'role': newRole});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}