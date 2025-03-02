import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:law4her/User/chatbot.dart';
import 'lawyerprofile.dart';
import 'package:law4her/Lawyer/lawyerforum.dart';
import 'package:law4her/Lawyer/lawyerrecentchatpage.dart';

class LawyerHomePage extends StatefulWidget {
  @override
  _LawyerHomePageState createState() => _LawyerHomePageState();
}

class _LawyerHomePageState extends State<LawyerHomePage> {
  int _selectedIndex = 0;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  // Fetch availability from Firebase
  Future<void> _fetchAvailability() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print("User is not authenticated.");
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('lawyer').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _isAvailable = doc['availability'] ?? false;
        });
      } else {
        print("Lawyer document does not exist.");
      }
    } catch (e) {
      print("Error fetching availability: $e");
    }
  }

  // Update availability in Firebase
  Future<void> _updateAvailability(bool value) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print("User is not authenticated.");
        return;
      }
      await FirebaseFirestore.instance.collection('lawyer').doc(uid).update({
        'availability': value,
      });
      setState(() {
        _isAvailable = value;
      });
      print("Availability updated to: $value");
    } catch (e) {
      print("Error updating availability: $e");
    }
  }

  final List<Widget> _pages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages.addAll([
      LawyerHomeScreen(
        title: 'Lawyer Home',
        isAvailable: _isAvailable,
        updateAvailability: _updateAvailability,
      ),
      LawyerForumPage(),
      LawyerRecentChatsPage(),
      LawyerProfilePage(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Chatbot()),
            );
          },
          backgroundColor: const Color(0xFF416d6d),
          child: const Icon(Icons.smart_toy, color: Color(0xFFc5d0d3)),
        ),
      ),
      bottomNavigationBar: Container(
        height: 74,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF416d6d), Color(0xFF608e8e)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum_rounded),
                label: 'Forum',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFFc5d0d3),
            unselectedItemColor: const Color(0xFFc5d0d3).withOpacity(0.6),
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}


class LawyerHomeScreen extends StatelessWidget {
  final String title;
  final bool isAvailable;
  final ValueChanged<bool> updateAvailability;

  LawyerHomeScreen({
    required this.title,
    required this.isAvailable,
    required this.updateAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipPath(
                        clipper: UpwardCurveClipper(),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF416d6d),
                                Color(0xFF608e8e),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 40, top: 40),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Image.asset(
                                'assets/whitelogo.png',
                                fit: BoxFit.contain,
                                height: 150,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 16), // Added top padding to account for wallet
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildListDelegate(
                    [
                      ServiceCard(
                        icon: Icons.forum_rounded,
                        title: 'Community\nForum',
                        color: Color(0xFF416d6d),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LawyerForumPage()),
                        ),
                      ),

                      ServiceCard(
                        icon: Icons.message_rounded,
                        title: 'Your\nChats',
                        color: Color(0xFF608e8e),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LawyerRecentChatsPage()),
                        ),
                      ),
                      ServiceCard(
                        icon: Icons.smart_toy_rounded,
                        title: 'AI\nAssistant',
                        color: Color(0xFF416d6d),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Chatbot()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 200,
            right: 16,
            child: _buildToggleSwitch(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAvailable ? "Available" : "Not Available",
            style: TextStyle(
              color: Color(0xFF416d6d),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isAvailable,
            onChanged: updateAvailability,
            activeColor: Color(0xFF416d6d),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const ServiceCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UpwardCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}