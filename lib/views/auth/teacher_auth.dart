import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:virtualhelp_chat/services/constants.dart';
import 'package:virtualhelp_chat/services/validator.dart';
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
          color: Theme.of(context).colorScheme.surface,
          image: _image != null
              ? DecorationImage(
                  image: FileImage(_image!),
                  fit: BoxFit.contain, // Ensures the image covers the circle properly
                )
              : null,
        ),
        child: _image == null ? Icon(Icons.camera_alt, size: 50, color: Theme.of(context).colorScheme.onSurface) : null,
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
    if (_image == null) {
      debugPrint('No image selected for upload');
      return null;
    }

    try {
      // Define valid roles to prevent typos and make maintenance easier
      const validRoles = {'student', 'teacher'};
      final String role = (_selectedRole?.toLowerCase() ?? 'unknown');
      final String collection = validRoles.contains(role) ? '${role}s' : 'users';

      // Create a reference to the image location
      final ref = _storage
          .ref()
          .child(collection)
          .child('profile_images')
          .child('$userId-${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Add specific metadata for better image handling
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'userRole': role,
          'uploadDate': DateTime.now().toIso8601String(),
          'fileName': ref.name,
        },
      );

      // Upload file with metadata and track progress if needed
      final uploadTask = ref.putFile(_image!, metadata);

      // Optional: Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: $progress%');
      });

      // Wait for upload completion
      await uploadTask;

      // Get and return download URL if upload was successful
      if (uploadTask.snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('Image uploaded successfully: ${ref.name}');
        return downloadUrl;
      }

      debugPrint('Upload completed but state was not success');
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error uploading image: ${e.message}');
      // You might want to throw the error instead of returning null
      // throw Exception('Failed to upload image: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      // You might want to throw the error instead of returning null
      // throw Exception('Failed to upload image: $e');
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
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        final String? imageUrl = await _uploadImage(userCredential.user!.uid);
        final String collection = _selectedRole?.toLowerCase() == 'student' ? 'students' : 'teachers';

        final userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'username': username.text.trim(),
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userCredential.user!.uid,
          'svg': imageUrl,
        };

        await _firestore.collection(collection).doc(userCredential.user!.uid).set(userData);

        // Store locally for immediate use
        Constants.localUserId = userCredential.user!.uid;
        Constants.localRole = _selectedRole ?? '';
        Constants.localSvg = imageUrl ?? '';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created successfully!')));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "New Account",
          style: GoogleFonts.archivo(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
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
                    color: colorScheme.onSurface,
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
                      style: TextStyle(color: colorScheme.error),
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
                    ? Center(
                        child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ))
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
