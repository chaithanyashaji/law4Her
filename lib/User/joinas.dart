import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:law4her/User/login.dart';
import 'package:law4her/Lawyer/lawyerlogin.dart';

class Joinas extends StatefulWidget {
  const Joinas({super.key});

  @override
  State<Joinas> createState() => _JoinasState();
}

class _JoinasState extends State<Joinas> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient with pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFC5D0D3),
                  const Color(0xFF608e8e).withOpacity(0.3),
                ],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: const Color(0xFF416d6d).withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: CircleAvatar(
              radius: 75,
              backgroundColor: const Color(0xFF608e8e).withOpacity(0.1),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Gap(30),
                    Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'assets/whitelogo.png',
                        width: 200,
                        height: 200,
                      ),
                    ),
                    const Gap(20),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Column(
                          children: [
                            const Text(
                              "Welcome!",
                              style: TextStyle(
                                color: Color(0xFF416d6d),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Gap(15),
                            const Text(
                              "Please select your role",
                              style: TextStyle(
                                color: Color(0xFF416d6d),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(90),
                    _buildOptionButton(
                      context,
                      title: "User",
                      icon: Icons.person_outline,
                      onPressed: () => _navigateToNextScreen(context, LoginPage()),
                      delay: 400,
                    ),
                    const Gap(24),
                    _buildOptionButton(
                      context,
                      title: "Lawyer",
                      icon: Icons.gavel,
                      onPressed: () => _navigateToNextScreen(context, Lawyerlogin()),
                      delay: 600,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onPressed,
        required int delay,
      }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        height: 85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF416d6d).withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(25),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFF5F7F7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF608e8e).withOpacity(0.2),
                            const Color(0xFF416d6d).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF416d6d).withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF416d6d),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF416d6d),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF608e8e).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF608e8e),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  void _navigateToNextScreen(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}