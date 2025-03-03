import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('user').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            userData = doc.data();
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  Future<void> _updateField(String fieldKey, String newValue) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('user').doc(user.uid).update({fieldKey: newValue});
        setState(() {
          userData![fieldKey] = newValue; // Update the local state for immediate UI update
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fieldKey updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update $fieldKey: $e')),
        );
      }
    }
  }

  void _showEditDialog(String fieldKey, String title, String currentValue) {
    final TextEditingController _controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: title,
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newValue = _controller.text.trim();
                if (newValue.isNotEmpty) {
                  await _updateField(fieldKey, newValue);
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, String fieldKey) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Color(0xFF416d6d)),
                  SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Color(0xFF416d6d)),
                onPressed: () {
                  _showEditDialog(fieldKey, title, value);
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF416d6d),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3),
      body: userData == null
          ? Center(child: CircularProgressIndicator(color: Color(0xFF416d6d)))
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            backgroundColor: Color(0xFF416d6d),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF416d6d), Color(0xFF608e8e)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Gap(30),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFc5d0d3),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF416d6d),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      userData!['name'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      userData!['email'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(Icons.phone, 'Phone Number', userData!['mobilenumber'] ?? 'N/A', 'mobilenumber'),
                SizedBox(height: 16),
                _buildInfoCard(Icons.location_on, 'Location', userData!['place'] ?? 'N/A', 'place'),
                SizedBox(height: 50),
                ElevatedButton.icon(
                  onPressed: () {
                    FirebaseAuth.instance.signOut().then((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    });
                  },
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF416d6d),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
