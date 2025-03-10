import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';
import 'package:law4her/Lawyer/lawyerlogin.dart';
import 'package:law4her/Lawyer/earnings.dart'; // Import the Earnings page

class LawyerProfilePage extends StatefulWidget {
  @override
  _LawyerProfilePageState createState() => _LawyerProfilePageState();
}

class _LawyerProfilePageState extends State<LawyerProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? lawyerData;
  String serviceType = 'Free Service';
  TextEditingController rateController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _fetchLawyerData();
  }

  Future<void> _fetchLawyerData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('lawyer').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            lawyerData = doc.data();
            serviceType = lawyerData?['serviceType'] ?? 'Free Service'; // Default to Free Service
            rateController.text = lawyerData?['rate']?.toString() ?? '0'; // Default to 0
          });
        }
      } catch (e) {
        print("Error fetching lawyer data: $e");
      }
    }
  }



  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF416d6d)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF416d6d),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3), // Light background
      body: lawyerData == null
          ? Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF416d6d), // Dark green accent
        ),
      )
          : CustomScrollView(
        slivers: [
          // App Bar with Profile Information
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            backgroundColor: const Color(0xFF416d6d), // Dark green
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
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
                      backgroundColor: const Color(0xFFc5d0d3),
                      backgroundImage: lawyerData!['profilephotourl'] != null
                          ? NetworkImage(lawyerData!['profilephotourl'])
                          : null,
                      child: lawyerData!['profilephotourl'] == null
                          ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF416d6d),
                      )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lawyerData!['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lawyerData!['email'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Info Cards
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildInfoCard(Icons.phone, 'Phone Number',
                      lawyerData!['mobilenumber'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.work, 'Specialization',
                      lawyerData!['specialization'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.location_city, 'City',
                      lawyerData!['place'] ?? 'N/A'),
                  const SizedBox(height: 16),

// Free/Paid Service Dropdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business_center, color: const Color(0xFF416d6d)), // Briefcase Icon
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service Type',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: serviceType,
                                  items: ['Free Service', 'Paid Service']
                                      .map((String value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF416d6d),
                                      ),
                                    ),
                                  ))
                                      .toList(),
                                  onChanged: (newValue) async {
                                    setState(() {
                                      serviceType = newValue!;
                                      if (serviceType == 'Free Service') {
                                        rateController.text = '0'; // Reset rate if Free Service
                                      }
                                    });

                                    // Auto-update Firestore when the value changes
                                    final user = _auth.currentUser;
                                    if (user != null) {
                                      try {
                                        await _firestore.collection('lawyer').doc(user.uid).update({
                                          'serviceType': serviceType,
                                          'rate': serviceType == 'Paid Service' ? int.parse(rateController.text) : 0,
                                        });
                                      } catch (e) {
                                        print("Error updating service type: $e");
                                      }
                                    }
                                  },
                                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF416d6d)), // Dropdown arrow
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),



                  const SizedBox(height: 16),

// Rate Field (Only Visible if Paid Service)
                  if (serviceType == 'Paid Service')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.monetization_on, color: const Color(0xFF416d6d)), // Money Icon
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rate',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${rateController.text} INR',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF416d6d),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Color(0xFF416d6d)), // Edit button inside card
                            onPressed: () => _showEditRateDialog(),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 16,),





                  // Earnings Info Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LawyerEarningsPage()),
                      );
                    },
                    child: _buildInfoCard(
                      Icons.monetization_on,
                      'Earnings',
                      'View Details',
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: () {
                      FirebaseAuth.instance.signOut().then((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Lawyerlogin()),
                        );
                      });
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF416d6d),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showEditRateDialog() {
    TextEditingController newRateController = TextEditingController(text: rateController.text);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Rate"),
          content: TextField(
            controller: newRateController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Enter new rate",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close Dialog
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final user = _auth.currentUser;
                if (user != null) {
                  try {
                    int newRate = int.tryParse(newRateController.text) ?? 0;
                    await _firestore.collection('lawyer').doc(user.uid).update({
                      'rate': newRate,
                    });

                    setState(() {
                      rateController.text = newRate.toString(); // Update UI
                    });

                    Navigator.pop(context); // Close Dialog
                  } catch (e) {
                    print("Error updating rate: $e");
                  }
                }
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

}
