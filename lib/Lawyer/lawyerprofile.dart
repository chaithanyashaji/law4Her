import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:law4her/User/login.dart';

class LawyerProfilePage extends StatefulWidget {
  @override
  _LawyerProfilePageState createState() => _LawyerProfilePageState();
}

class _LawyerProfilePageState extends State<LawyerProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? lawyerData;

  @override
  void initState() {
    super.initState();
    _fetchLawyerData();
  }

  Future<void> _fetchLawyerData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('lawyer').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          lawyerData = doc.data();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e1e2a), // Dark background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1e1e2a),
        elevation: 0,
      ),
      body: lawyerData == null
          ? Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF44404d), // Accent color
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Display Profile Photo
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF44404d),
                      backgroundImage: lawyerData!['profilephotourl'] != null
                          ? NetworkImage(lawyerData!['profilephotourl'])
                          : null,
                      child: lawyerData!['profilephotourl'] == null
                          ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    // Lawyer's Name
                    Text(
                      lawyerData!['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Lawyer's Email
                    Text(
                      lawyerData!['email'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Information Section
                    _buildInfoCard(Icons.phone, lawyerData!['mobilenumber'] ?? 'N/A'),
                    const SizedBox(height: 20),
                    _buildInfoCard(Icons.email, lawyerData!['email'] ?? 'N/A'),
                    const SizedBox(height: 20),
                    _buildInfoCard(Icons.work, lawyerData!['specialization'] ?? 'N/A'),
                    const SizedBox(height: 40),
                    // Edit Profile Button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Add edit functionality
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        "Edit Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF44404d),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Logout Button at the Bottom
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: () {
                FirebaseAuth.instance.signOut().then((value) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                });
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF44404d), // Button background
                padding: const EdgeInsets.symmetric(
                    vertical: 15, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to create the info card with an icon and text
  Widget _buildInfoCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF44404d), // Card background
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
