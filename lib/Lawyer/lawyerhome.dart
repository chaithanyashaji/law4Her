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

class _LawyerHomePageState extends State<LawyerHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  final List<String> _titles = ['Home', 'Forum', 'Chats', 'Profile'];
  bool _isReady = false;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Add a delay before starting animations to prevent red flashes
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
        _animationController.forward();
      }
    });
  }

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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start with a plain container to prevent red flash
    if (!_isReady) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7F9),
        body: Container(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          );
        },
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF416d6d), Color(0xFF608e8e)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF416d6d).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => Chatbot(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: (1.0 - value) * 1.0,
                  child: child,
                );
              },
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return InkWell(
                onTap: () => _onItemTapped(index),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _selectedIndex == index
                        ? const Color(0xFF416d6d).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        decoration: BoxDecoration(
                          boxShadow: _selectedIndex == index
                              ? [
                            BoxShadow(
                              color: const Color(0xFF416d6d).withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                              : [],
                        ),
                        child: Icon(
                          _getIcon(index),
                          color: _selectedIndex == index
                              ? const Color(0xFF416d6d)
                              : Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0.8,
                          end: _selectedIndex == index ? 1.0 : 0.8,
                        ),
                        duration: const Duration(milliseconds: 200),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Text(
                          _titles[index],
                          style: TextStyle(
                            color: _selectedIndex == index
                                ? const Color(0xFF416d6d)
                                : Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: _selectedIndex == index
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.forum_rounded;
      case 2:
        return Icons.chat_bubble_rounded;
      case 3:
        return Icons.person_rounded;
      default:
        return Icons.error;
    }
  }
}

class LawyerHomeScreen extends StatefulWidget {
  final String title;
  final Stream<bool> Function() getAvailabilityStream;
  final Future<void> Function(bool) updateAvailability;

  LawyerHomeScreen({
    required this.title,
    required this.getAvailabilityStream,
    required this.updateAvailability,
  });

  @override
  _LawyerHomeScreenState createState() => _LawyerHomeScreenState();
}

class _LawyerHomeScreenState extends State<LawyerHomeScreen> {
  bool _animationsReady = false;

  @override
  void initState() {
    super.initState();
    // Delay animations to prevent red flash on initial render
    Future.delayed(Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _animationsReady = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          // Modern app bar with subtle curves
          Container(
            height: 260,
            child: Stack(
              children: [
                // Background gradient with soft wave
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: _animationsReady ? 0.0 : 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutQuint,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: _animationsReady ? (1.0 - (1.0 - value) * 0.05) : 1.0,
                      child: Opacity(
                        opacity: _animationsReady ? value : 1.0,
                        child: child,
                      ),
                    );
                  },
                  child: ClipPath(
                    clipper: GentleWaveClipper(),
                    child: Container(
                      height: 260,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF416d6d),
                            Color(0xFF608e8e),
                          ],
                          stops: [0.3, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Logo overlay with drop shadow
                Positioned(
                  top: 60,  // Move slightly lower for better visibility
                  left: 0,
                  right: 0,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: _animationsReady ? 0.0 : 1.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutQuint,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: _animationsReady
                            ? Offset(0, (1.0 - value) * 30)
                            : Offset.zero,
                        child: Opacity(
                          opacity: _animationsReady ? value : 1.0,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      height: 140,  // Slightly smaller for better proportion
                      padding: EdgeInsets.symmetric(horizontal: 40),  // Add padding for better containment
                      child: Image.asset(
                        'assets/whitelogo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Welcome message
                Positioned(
                  top: 50,
                  left: 20,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('lawyer')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String name = "Lawyer";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        name = data['name'] ?? "Lawyer";
                         // Get first name only
                      }
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: _animationsReady ? 0.0 : 1.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: _animationsReady
                                ? Offset((1.0 - value) * -30, 0)
                                : Offset.zero,
                            child: Opacity(
                              opacity: _animationsReady ? value : 1.0,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          "Hello, $name!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Availability toggle with modern design
                Positioned(
                  top: 185,
                  right: 20,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: _animationsReady ? 0.0 : 1.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: _animationsReady
                            ? Offset((1.0 - value) * 50, 0)
                            : Offset.zero,
                        child: Opacity(
                          opacity: _animationsReady ? value : 1.0,
                          child: child,
                        ),
                      );
                    },
                    child: _buildAvailabilityToggle(),
                  ),
                ),
              ],
            ),
          ),
          // Services section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: _animationsReady ? 0.0 : 1.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: _animationsReady
                      ? Offset(0, (1.0 - value) * 20)
                      : Offset.zero,
                  child: Opacity(
                    opacity: _animationsReady ? value : 1.0,
                    child: child,
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF416d6d),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Quick Access",
                    style: TextStyle(
                      color: const Color(0xFF416d6d),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scrollable services grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                physics: BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 10, bottom: 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  // Staggered animation for grid items
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: _animationsReady ? 0.0 : 1.0, end: 1.0),
                    duration: Duration(milliseconds: 600 + (index * 100)),
                    curve: Curves.easeOutQuint,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: _animationsReady
                            ? Offset(0, (1.0 - value) * 50)
                            : Offset.zero,
                        child: Opacity(
                          opacity: _animationsReady ? value : 1.0,
                          child: child,
                        ),
                      );
                    },
                    child: ServiceCard(
                      icon: _getIconForService(index),
                      title: _getTitleForService(index),
                      description: _getDescriptionForService(index),
                      color: index == 0
                          ? const Color(0xFF416d6d)
                          : index == 1
                          ? const Color(0xFF608e8e)
                          : index == 2
                          ? const Color(0xFF265557)
                          : const Color(0xFF6da6a6),
                      onTap: () {
                        _navigateToService(index, context);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return StreamBuilder<bool>(
      stream: widget.getAvailabilityStream(),
      builder: (context, snapshot) {
        final isAvailable = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFF416d6d).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAvailable ? Icons.check_circle : Icons.timelapse,
                  color: isAvailable ? Color(0xFF416d6d) : Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Status",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    isAvailable ? "Available" : "Unavailable",
                    style: TextStyle(
                      color: isAvailable ? Color(0xFF416d6d) : Colors.grey.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Switch(
                value: isAvailable,
                onChanged: (value) async {
                  await widget.updateAvailability(value);
                },
                activeColor: Color(0xFF416d6d),
                activeTrackColor: Color(0xFF416d6d).withOpacity(0.3),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForService(int index) {
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

  String _getTitleForService(int index) {
    switch (index) {
      case 0:
        return 'Community Forum';
      case 1:
        return 'Your Chats';
      case 2:
        return 'AI Assistant';
      case 3:
        return 'Emergency';
      default:
        return 'Unknown';
    }
  }

  String _getDescriptionForService(int index) {
    switch (index) {
      case 0:
        return 'Answer questions';
      case 1:
        return 'Your conversations';
      case 2:
        return 'Get legal insights';
      case 3:
        return 'Emergency contacts';
      default:
        return '';
    }
  }

  void _navigateToService(int index, BuildContext context) {
    final destinations = [
      LawyerForumPage(),
      LawyerRecentChatsPage(),
      Chatbot(),
      EmergencyContactsPage(),
    ];

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destinations[index],
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuint,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class GentleWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);

    final firstControlPoint = Offset(size.width * 0.25, size.height - 30);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 45);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, size.height - 60);
    final secondEndPoint = Offset(size.width, size.height - 30);
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

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const ServiceCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                ),
                Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
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