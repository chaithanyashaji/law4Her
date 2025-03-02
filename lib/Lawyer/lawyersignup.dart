import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:law4her/Lawyer/lawyerlogin.dart';
import 'package:gap/gap.dart';

class LawyerSignup extends StatefulWidget {
  const LawyerSignup({Key? key}) : super(key: key);

  @override
  State<LawyerSignup> createState() => _LawyerSignupState();
}

class _LawyerSignupState extends State<LawyerSignup> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _conPasswordController = TextEditingController();
  final _barIdController = TextEditingController();
  final _specializationController = TextEditingController();
  final _placeController = TextEditingController();

  String? _selectedServiceType;
  File? _idProofImage;
  Uint8List? _compressedIdProofBytes;
  File? _profilePhoto;
  Uint8List? _compressedProfilePhotoBytes;
  String _errorText = '';
  bool _isLoading = false;
  double _uploadProgress = 0.0;

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
    _passwordController.dispose();
    _conPasswordController.dispose();
    _barIdController.dispose();
    _specializationController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isProfilePhoto) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        final compressedImage = _compressImage(imageBytes);
        setState(() {
          if (isProfilePhoto) {
            _profilePhoto = File(pickedFile.path);
            _compressedProfilePhotoBytes = compressedImage;
          } else {
            _idProofImage = File(pickedFile.path);
            _compressedIdProofBytes = compressedImage;
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick an image. Please try again.');
    }
  }

  Uint8List _compressImage(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Failed to decode image.');
    final compressed = img.encodeJpg(image, quality: 75);
    return Uint8List.fromList(compressed);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isNumeric = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFC5D0D3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5D0D3).withOpacity(0.1),
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
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF608e8e)),
          prefixIcon: Icon(icon, color: const Color(0xFF608e8e)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          fillColor: const Color(0xFFC5D0D3),
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF416d6d)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF416d6d), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerButton(bool isProfilePhoto) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFC5D0D3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF416d6d)),
      ),
      child: ListTile(
        onTap: () => _pickImage(isProfilePhoto),
        leading: Icon(
          Icons.upload_file,
          color: const Color(0xFF608e8e),
        ),
        title: Text(
          isProfilePhoto ? "Upload Profile Photo" : "Upload ID Proof",
          style: const TextStyle(
            color: Color(0xFF608e8e),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: const Color(0xFF608e8e),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildServiceTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFC5D0D3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5D0D3).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedServiceType,
        decoration: InputDecoration(
          labelText: "Service Type",
          labelStyle: const TextStyle(color: Color(0xFF608e8e)),
          prefixIcon: Icon(Icons.work_outline, color: const Color(0xFF608e8e)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          fillColor: const Color(0xFFC5D0D3),
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF416d6d)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF416d6d), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        style: const TextStyle(color: Color(0xFF416d6d)),
        dropdownColor: const Color(0xFFC5D0D3),
        icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF608e8e)),
        items: ['Free Service', 'Paid Service'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF416d6d),
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedServiceType = value);
        },
        validator: (value) => value == null ? 'Please select a service type' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC5D0D3),
      body: Stack(
        children: [
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
                    child: Form(
                      key: _formKey,
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
                          const Text(
                            "Lawyer Registration",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF416d6d),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Gap(10),
                          const Text(
                            "Join us as a legal professional!",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF608e8e),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Gap(30),
                          _buildTextField(
                            controller: _nameController,
                            label: "Name",
                            icon: Icons.person_outline,
                            validator: (value) => value?.isEmpty ?? true ? "Please enter your name" : null,
                          ),
                          const Gap(20),
                          _buildTextField(
                            controller: _emailController,
                            label: "Email",
                            icon: Icons.email_outlined,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return "Please enter your email";
                              if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}").hasMatch(value!)) {
                                return "Please enter a valid email address";
                              }
                              return null;
                            },
                          ),
                          const Gap(20),
                          _buildTextField(
                            controller: _mobileNumberController,
                            label: "Mobile Number",
                            icon: Icons.phone_outlined,
                            isNumeric: true,
                            validator: (value) => value?.length != 10 ? "Enter a valid 10-digit number" : null,
                          ),
                          const Gap(20),
                          _buildTextField(
                            controller: _barIdController,
                            label: "Bar ID",
                            icon: Icons.badge_outlined,
                            validator: (value) => value?.isEmpty ?? true ? "Please enter your Bar ID" : null,
                          ),
                          const Gap(20),
                          _buildTextField(
                            controller: _specializationController,
                            label: "Specialization",
                            icon: Icons.school_outlined,
                            validator: (value) => value?.isEmpty ?? true ? "Please enter your specialization" : null,
                          ),
                          const Gap(20),
                          _buildTextField(
                            controller: _placeController,
                            label: "Place",
                            icon: Icons.location_on_outlined,
                            validator: (value) => value?.isEmpty ?? true ? "Please enter your place" : null,
                          ),
                          const Gap(20),
                          _buildImagePickerButton(true),
                          if (_compressedProfilePhotoBytes != null) ...[
                            const Gap(10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _compressedProfilePhotoBytes!,
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                          const Gap(20),
                          _buildImagePickerButton(false),
                          if (_compressedIdProofBytes != null) ...[
                            const Gap(10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _compressedIdProofBytes!,
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                          const Gap(20),
                          _buildServiceTypeDropdown(),
                          const Gap(20),
                          _buildTextField(
                            controller: _passwordController,
                            label: "Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (value) => (value?.length ?? 0) < 6 ? "Password must be at least 6 characters" : null,
                          ),
                          const Gap(20),
                          _buildTextField(
                            controller: _conPasswordController,
                            label: "Confirm Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (value) => value != _passwordController.text ? "Passwords do not match" : null,
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
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF416d6d), Color(0xFF608e8e)],
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
                              onPressed: !_isLoading ? _signup : null,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                                  : const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          if (_uploadProgress > 0.0 && _uploadProgress < 1.0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: const Color(0xFFC5D0D3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF416d6d)),
                              ),
                            ),
                          const Gap(20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: Color(0xFF608e8e),
                                  fontSize: 15,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Lawyerlogin()),
                                ),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Color(0xFF416d6d),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(80),
                        ],
                      ),
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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_compressedIdProofBytes == null || _compressedProfilePhotoBytes == null) {
      setState(() => _errorText = 'Please upload both ID proof and profile photo.');
      return;
    }

    if (_selectedServiceType == null) {
      setState(() => _errorText = 'Please select a service type.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;
      final idProofUrl = await _uploadFile(_compressedIdProofBytes!, 'lawyer_id_proofs/$userId.jpg');
      final profilePhotoUrl = await _uploadFile(_compressedProfilePhotoBytes!, 'lawyer_profile_photos/$userId.jpg');

      await FirebaseFirestore.instance.collection('lawyer').doc(userId).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobilenumber': _mobileNumberController.text.trim(),
        'barid': _barIdController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'place': _placeController.text.trim(),
        'idproofurl': idProofUrl,
        'profilephotourl': profilePhotoUrl,
        'status': 'Pending',
        'totalRatings': 0,
        'noOfRatings': 0,
        'avgRating': 0.0,
        'serviceType': _selectedServiceType,
        'availability': 'no',
      });

      _showVerificationDialog();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = e.code == 'email-already-in-use'
            ? 'The email is already registered. Please use a different email.'
            : 'An unexpected error occurred. Please try again.';
      });
    } catch (e) {
      setState(() {
        _errorText = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadFile(Uint8List fileBytes, String filePath) async {
    final storageRef = FirebaseStorage.instance.ref().child(filePath);
    final uploadTask = storageRef.putData(
      fileBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    uploadTask.snapshotEvents.listen((event) {
      setState(() {
        _uploadProgress = event.bytesTransferred / event.totalBytes;
      });
    });

    await uploadTask;
    return await storageRef.getDownloadURL();
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Profile Under Verification",
            style: TextStyle(
              color: Color(0xFF416d6d),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Your profile is under verification. Please wait for a day and try logging in.",
            style: TextStyle(
              color: Color(0xFF608e8e),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Lawyerlogin()),
                );
              },
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Color(0xFF416d6d),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF416d6d),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}