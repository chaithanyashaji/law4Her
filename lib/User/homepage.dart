import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:law4her/User/emergency.dart';
import 'chatbot.dart';
import 'forum.dart';
import 'package:law4her/User/lawyerconsultation.dart';
import 'package:law4her/User/profile.dart';
import 'package:law4her/User/userchat.dart';
import 'package:law4her/User/wallet.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    UserHomeScreen(),
    ForumPage(),
    LawyerConsultation(),
    UserChat(),
    ProfilePage(),
  ];

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
        margin: const EdgeInsets.only(bottom: 5), // Increased margin for proper spacing
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
          height: 70, // Reduced height to avoid overflow
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjusted margins
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
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.forum_rounded),
                  label: 'Forum',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.gavel_rounded),
                  label: 'Lawyer',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.message_rounded),
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

class UserHomeScreen extends StatelessWidget {
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
                top: 155, // Wallet position
                right: 16,
                child: WalletDisplay(),
              ),
            ],
          ),
          // Scrollable content
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
                itemCount: 5,
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
        return Icons.gavel_rounded;
      case 2:
        return Icons.message_rounded;
      case 3:
        return Icons.smart_toy_rounded;
      case 4:
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
        return 'Consult\nLawyer';
      case 2:
        return 'Your\nChats';
      case 3:
        return 'AI\nAssistant';
      case 4:
        return 'Emergency\nContacts';
      default:
        return 'Unknown';
    }
  }

  void _navigateToPage(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => ForumPage()));
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => LawyerConsultation()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => UserChat()));
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Chatbot()));
        break;
      case 4:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => EmergencyContactsPage()));
        break;
      default:
        break;
    }
  }
}





class WalletDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildWalletContainer("₹0", context);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('user').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildWalletContainer("Loading...", context);
        }

        if (snapshot.hasError) {
          return _buildWalletContainer("Error", context);
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final walletAmount = data['wallet'] ?? 0;
          return _buildWalletContainer("₹$walletAmount", context);
        }

        return _buildWalletContainer("₹0", context);
      },
    );
  }

  Widget _buildWalletContainer(String walletBalance, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WalletPage()),
        );
      },
      child: Container(
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
            Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF416d6d),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              walletBalance,
              style: TextStyle(
                color: Color(0xFF416d6d),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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