import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  
  bool _isEditingName = false;

  List<String> dietaryOptions = ['Veg', 'Non-Veg', 'Vegan', 'Jain'];
  List<String> allergyOptions = ['Peanuts', 'Dairy', 'Gluten', 'Soy', 'None'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          
          // Sync controller text only when not actively typing
          if (!_isEditingName) {
            _nameController.text = userData['name'] ?? "";
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(Icons.person, size: 60, color: Colors.orange),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.orange,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            onPressed: () {
                              // Task: Profile Picture upload (Point 2.4)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Storage Setup Required for Upload")),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Name Section (Edit/Save Logic)
                const Text("Full Name", style: TextStyle(color: Colors.grey, fontSize: 14)),
                Row(
                  children: [
                    Expanded(
                      child: _isEditingName
                          ? TextField(controller: _nameController, autofocus: true)
                          : Text(_nameController.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    ),
                    IconButton(
                      icon: Icon(_isEditingName ? Icons.check : Icons.edit, color: Colors.orange),
                      onPressed: () async {
                        if (_isEditingName) {
                          await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                            'name': _nameController.text.trim(),
                          });
                        }
                        setState(() => _isEditingName = !_isEditingName);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                itemDetail("Email", userData['email']),
                itemDetail("Role", userData['role']?.toString().toUpperCase() ?? "STUDENT"),

                const Divider(height: 40),

                // Dietary Preferences (Point 2.2)
                const Text("Dietary Preferences", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: dietaryOptions.map((opt) {
                    List prefs = userData['dietaryPreferences'] ?? [];
                    bool isSelected = prefs.contains(opt);
                    return ChoiceChip(
                      label: Text(opt),
                      selectedColor: Colors.orange.shade200,
                      selected: isSelected,
                      onSelected: (selected) {
                        FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                          'dietaryPreferences': selected 
                              ? FieldValue.arrayUnion([opt]) 
                              : FieldValue.arrayRemove([opt])
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Allergy Information (Point 2.3)
                const Text("Allergies", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: allergyOptions.map((allergy) {
                    List allergies = userData['allergies'] ?? [];
                    bool isSelected = allergies.contains(allergy);
                    return FilterChip(
                      label: Text(allergy),
                      selected: isSelected,
                      onSelected: (selected) {
                        FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                          'allergies': selected 
                              ? FieldValue.arrayUnion([allergy]) 
                              : FieldValue.arrayRemove([allergy])
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget itemDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}