import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:law4her/User/chatbot.dart';
import 'lawyerprofile.dart';
import 'lawyerforum.dart';
import 'lawyerrecentchatpage.dart';
import 'package:law4her/User/emergency.dart';

class LawyerHomePage extends StatefulWidget {
  @override
  _LawyerHomePageState createState() => _LawyerHomePageState();
}

class _LawyerHomePageState extends State<LawyerHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  // Stream to get real-time availability updates from Firestore
  Stream<bool> getAvailabilityStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value(false); // Default to false if unauthenticated
    }
    return FirebaseFirestore.instance
        .collection('lawyer')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data()?['availability'] ?? false);
  }

  // Update availability in Firestore
  Future<void> _updateAvailability(bool value) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('lawyer').doc(uid).update({
        'availability': value,
      });
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
        getAvailabilityStream: getAvailabilityStream,
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
        margin: const EdgeInsets.only(bottom: 5),
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
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF416d6d), Color(0xFF608e8e)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
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
                  icon: Icon(Icons.home_rounded, size: 28),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.forum_rounded, size: 28),
                  label: 'Forum',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_rounded, size: 28),
                  label: 'Chats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded, size: 28),
                  label: 'Profile',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: const Color(0xFFc5d0d3),
              unselectedItemColor: const Color(0xFFc5d0d3).withOpacity(0.6),
              selectedLabelStyle: const TextStyle(fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
class LawyerHomeScreen extends StatelessWidget {
  final String title;
  final Stream<bool> Function() getAvailabilityStream;
  final Future<void> Function(bool) updateAvailability;

  LawyerHomeScreen({
    required this.title,
    required this.getAvailabilityStream,
    required this.updateAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFc5d0d3),
      body: Column(
        children: [
          // Fixed curved AppBar
          Stack(
            children: [
              ClipPath(
                clipper: UpwardCurveClipper(),
                child: Container(
                  height: 220,
                  decoration: const BoxDecoration(
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Image.asset(
                    'assets/whitelogo.png',
                    fit: BoxFit.contain,
                    height: 150,
                  ),
                ),
              ),
              Positioned(
                top: 155, // Toggle switch position
                right: 16,
                child: _buildToggleSwitch(),
              ),
            ],
          ),
          // Scrollable content with cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.95,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return ServiceCard(
                    icon: _getIcon(index),
                    title: _getTitle(index),
                    color: index.isEven
                        ? const Color(0xFF416d6d)
                        : const Color(0xFF608e8e),
                    onTap: () {
                      _navigateToPage(index, context);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.forum_rounded;
      case 1:
        return Icons.chat_bubble_rounded;
      case 2:
        return Icons.smart_toy_rounded;
      case 3:
        return Icons.phone_in_talk;
      default:
        return Icons.error;
    }
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Community\nForum';
      case 1:
        return 'Your\nChats';
      case 2:
        return 'AI\nAssistant';
      case 3:
        return 'Emergency\nContacts';
      default:
        return 'Unknown';
    }
  }

  void _navigateToPage(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LawyerForumPage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LawyerRecentChatsPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Chatbot()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EmergencyContactsPage()),
        );
        break;

      default:
        break;
    }
  }

  Widget _buildToggleSwitch() {
    return StreamBuilder<bool>(
      stream: getAvailabilityStream(),
      builder: (context, snapshot) {
        final isAvailable = snapshot.data ?? false; // Default to false if no data
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
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
                style: const TextStyle(
                  color: Color(0xFF416d6d),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: isAvailable,
                onChanged: (value) async {
                  await updateAvailability(value);
                },
                activeColor: const Color(0xFF416d6d),
              ),
            ],
          ),
        );
      },
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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

    final firstControlPoint = Offset(size.width / 4, size.height);
    final firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width - (size.width / 4), size.height - 60);
    final secondEndPoint = Offset(size.width, size.height - 40);
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