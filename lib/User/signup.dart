import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:law4her/User/login.dart';

class UserSignup extends StatefulWidget {
  const UserSignup({Key? key}) : super(key: key);

  @override
  State<UserSignup> createState() => _UserSignupState();
}

class _UserSignupState extends State<UserSignup> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _conPasswordController = TextEditingController();

  String _errorText = '';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _placeController.dispose();
    _passwordController.dispose();
    _conPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC5D0D3),
      body: Stack(
        children: [
          // Background design elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF608e8e).withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF416d6d).withOpacity(0.15),
              ),
            ),
          ),

          SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const Gap(20),
                        Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/whitelogo.png',
                            height: 120,
                            width: 120,
                          ),
                        ),
                        const Gap(20),
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF416d6d),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Gap(10),
                        Text(
                          "Join us to get started!",
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF608e8e),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(30),

                        _buildTextField(
                          controller: _nameController,
                          label: "Name",
                          icon: Icons.person_outline,
                        ),
                        const Gap(20),
                        _buildTextField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                        ),
                        const Gap(20),
                        _buildTextField(
                          controller: _mobileNumberController,
                          label: "Mobile Number",
                          icon: Icons.phone_outlined,
                          isNumeric: true,
                        ),
                        const Gap(20),

                        _buildTextField(
                          controller: _placeController,
                          label: "Place",
                          icon: Icons.location_on_outlined,
                        ),
                        const Gap(20),
                        _buildTextField(
                          controller: _passwordController,
                          label: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const Gap(20),
                        _buildTextField(
                          controller: _conPasswordController,
                          label: "Confirm Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const Gap(30),

                        if (_errorText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _errorText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const Gap(20),

                        _buildSignupButton(),
                        const Gap(20),

                        _buildSignInSection(),
                        const Gap(40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const CircularProgressIndicator(
                    color: Color(0xFF416d6d),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isNumeric = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffc5d0d3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFc5d0d3).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Color(0xFF416d6d)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: const Color(0xFF608e8e)),
          prefixIcon: Icon(icon, color: const Color(0xFF608e8e)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          fillColor: Color(0xffc5d0d3),
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xff416d6d)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF416d6d), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF416d6d),
            const Color(0xFF608e8e),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF416d6d).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _signup,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Create Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(
            color: const Color(0xFF608e8e),
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          ),
          child: Text(
            'Sign In',
            style: TextStyle(
              color: const Color(0xFF416d6d),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _signup() async {
    _validateForm();
    if (_errorText.isEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance.collection('user').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'mobilenumber': _mobileNumberController.text.trim(),
          'place': _placeController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': 'user',
          'wallet': 0,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorText = e.message ?? 'An error occurred during signup';
        });
      } catch (e) {
        setState(() {
          _errorText = 'An unexpected error occurred. Please try again.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _validateForm() {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String mobileNumber = _mobileNumberController.text.trim();
    String place = _placeController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _conPasswordController.text.trim();

    // Regular expression to enforce password rules:
    // - At least 8 characters
    // - At least one uppercase letter
    // - At least one special character
    RegExp passwordRegExp = RegExp(r'^(?=.*[A-Z])(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$');

    if (name.isEmpty || email.isEmpty || mobileNumber.isEmpty || place.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorText = 'All fields are required';
      });
      return;
    }

    if (!passwordRegExp.hasMatch(password)) {
      setState(() {
        _errorText = 'Password must be at least 8 characters long, include one uppercase letter, and one special character';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorText = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _errorText = '';
    });
  }


}