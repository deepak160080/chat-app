import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:virtualhelp_chat/services/validator.dart';
import 'package:virtualhelp_chat/utils/app_colors.dart';
import 'package:virtualhelp_chat/views/widgets/app_buttons.dart';
import 'package:virtualhelp_chat/views/widgets/app_textfield.dart';

class TeacherAuth extends StatefulWidget {
  const TeacherAuth({super.key});

  @override
  State<TeacherAuth> createState() => _TeacherAuthState();
}

class _TeacherAuthState extends State<TeacherAuth> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController username = TextEditingController();

  bool _isLoading = false;
  String? _selectedRole;
  String? _errorMessage;
  File? _image;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100, // Adjust the size of the circle as needed
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          image: _image != null
              ? DecorationImage(
                  image: FileImage(_image!),
                  fit: BoxFit.contain, // Ensures the image covers the circle properly
                )
              : null,
        ),
        child: _image == null
            ? Icon(
                Icons.camera_alt,
                size: 50,
                color: Colors.grey[800],
              )
            : null,
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_image == null) return null;

    try {
      // Create a reference to the file location
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');

      // Upload the file with specific metadata to maintain quality
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': _image!.path},
      );

      await ref.putFile(_image!, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _createAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        // Upload image and get URL
        final String? imageUrl = await _uploadImage(userCredential.user!.uid);

        // Prepare user data
        final userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'username': username.text.trim(),
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userCredential.user!.uid,
          'svg': imageUrl,
        };

        // Determine collection based on role
        final String collection = _selectedRole?.toLowerCase() == 'student' ? 'students' : 'teachers';

        // Save user data to Firestore
        await _firestore.collection(collection).doc(userCredential.user!.uid).set(userData);

        // Update display name
        await userCredential.user!.updateDisplayName(_nameController.text.trim());

        // Show success message and navigate
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Or navigate to your desired screen
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'An error occurred during registration.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "New Account",
          style: GoogleFonts.archivo(
            color: AppColors.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style: GoogleFonts.archivo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildImagePicker(),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildSchoolField(),
                const SizedBox(height: 16),
                _buildRoleDropdownField(),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AppButton(
                        onPressed: _createAccount,
                        text: 'Create Account',
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return AppTextfield(
      controller: _nameController,
      icon: Icons.person,
      hintText: "Full Name",
      validator: Validators.validateName,
    );
  }

  Widget _buildEmailField() {
    return AppTextfield(
      controller: _emailController,
      icon: Icons.email,
      hintText: "Email",
      keyboardType: TextInputType.emailAddress,
      validator: Validators.validateEmailOrPhone,
    );
  }

  Widget _buildPasswordField() {
    return AppTextfield(
      controller: _passwordController,
      icon: Icons.lock,
      hintText: "Password",
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        return null; // All passwords are now acceptable
      },
    );
  }

  Widget _buildSchoolField() {
    return AppTextfield(
      controller: username,
      icon: Icons.person,
      hintText: "Username",
      validator: Validators.validateSchool,
    );
  }

  Widget _buildRoleDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      icon: const Icon(Icons.arrow_downward),
      decoration: const InputDecoration(
        labelText: "Select Role",
        border: OutlineInputBorder(),
      ),
      items: ['Student', 'Teacher'].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: _isLoading
          ? null
          : (String? newValue) {
              setState(() {
                _selectedRole = newValue;
              });
            },
      validator: (value) => value == null ? 'Please select a role' : null,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    username.dispose();
    super.dispose();
  }
}