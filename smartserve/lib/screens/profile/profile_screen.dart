import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFF8F9FA), // Premium background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("My Profile", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B6B)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("User data not found", style: GoogleFonts.inter()));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          
          // Sync controller text only when not actively typing
          if (!_isEditingName) {
            _nameController.text = userData['name'] ?? "";
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.2),
                        child: const Icon(Icons.person, size: 60, color: Color(0xFFFF6B6B)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFFF6B6B),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
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
                const SizedBox(height: 32),

                // Name Section (Edit/Save Logic preserved in Premium UI)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, color: Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Full Name", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                            _isEditingName
                              ? TextField(
                                  controller: _nameController, 
                                  autofocus: true,
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                                )
                              : Text(_nameController.text, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isEditingName ? Icons.check : Icons.edit, color: const Color(0xFFFF6B6B)),
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
                ),
                const SizedBox(height: 16),

                // Email & Role Details
                _buildInfoTile("Email", userData['email'] ?? "", Icons.email_outlined),
                const SizedBox(height: 16),
                _buildInfoTile("Role", userData['role']?.toString().toUpperCase() ?? "STUDENT", Icons.admin_panel_settings_outlined),

                const SizedBox(height: 32),

                // Dietary Preferences (Functionality preserved)
                Text("Dietary Preferences", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: dietaryOptions.map((opt) {
                    List prefs = userData['dietaryPreferences'] ?? [];
                    bool isSelected = prefs.contains(opt);
                    return ChoiceChip(
                      label: Text(opt, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFFFF6B6B) : Colors.black87)),
                      selectedColor: const Color(0xFFFF6B6B).withOpacity(0.1),
                      backgroundColor: Colors.white,
                      selected: isSelected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[300]!)
                      ),
                      showCheckmark: false,
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

                const SizedBox(height: 24),

                // Allergy Information (Functionality preserved)
                Text("Allergies", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: allergyOptions.map((allergy) {
                    List allergies = userData['allergies'] ?? [];
                    bool isSelected = allergies.contains(allergy);
                    return FilterChip(
                      label: Text(allergy, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFFFF6B6B) : Colors.black87)),
                      selectedColor: const Color(0xFFFF6B6B).withOpacity(0.1),
                      backgroundColor: Colors.white,
                      selected: isSelected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[300]!)
                      ),
                      showCheckmark: false,
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
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // Premium Info Tile for static items
  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }
}