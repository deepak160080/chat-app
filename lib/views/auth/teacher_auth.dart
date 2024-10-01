import 'package:chat_app/services/validator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/views/widgets/app_buttons.dart';
import 'package:chat_app/views/widgets/app_textfield.dart';
import 'package:chat_app/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referNumberController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
   bool _showOtpField = false;
  String _verificationId = '';
 bool _isFirstTeacher = true;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    _checkIfFirstTeacher();
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _referNumberController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    if (_phoneController.text.length >= 12) {  
      _sendOtp();
    }
  }

  Future<void> _checkIfFirstTeacher() async {
    var teachersSnapshot = await _firestore.collection('teachers').get();
    setState(() {
      _isFirstTeacher = teachersSnapshot.docs.isEmpty;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "New Teacher's Account",
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
                _buildNameField(),
                _buildEmailField(),
                _buildPhoneField(),
                if (_showOtpField) _buildOtpField(),
                _buildPasswordField(),
                _buildSchoolField(),
                _buildClassField(),
                _buildReferNumberField(),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AppButton(
                        onPressed: _handleSubmit,
                        text: _showOtpField ? 'Verify OTP' : 'Create Account',
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
      hintText: "Teacher's Name",
      validator: Validators.validateName);
  }

  Widget _buildEmailField() {
    return AppTextfield(
      controller: _emailController,
      icon: Icons.email,
      hintText: "Email",
      keyboardType: TextInputType.emailAddress,
      validator: Validators.validateEmailOrPhone
    );
  }

  Widget _buildPhoneField() {
    return AppTextfield(
      controller: _phoneController,
      icon: Icons.phone,
      hintText: "Phone Number (with country code)",
      keyboardType: TextInputType.phone,
      validator: Validators.validateMobile
    );
  }

  Widget _buildOtpField() {
    return AppTextfield(
      controller: _otpController,
      icon: Icons.security,
      hintText: "Enter OTP",
      keyboardType: TextInputType.number,
      validator: Validators.validateOTP
    );
  }

  Widget _buildPasswordField() {
    return AppTextfield(
      controller: _passwordController,
      icon: Icons.lock,
      hintText: "Password",
      obscureText: true,
      validator: Validators.validatePassword
    );
  }

  Widget _buildSchoolField() {
    return AppTextfield(
      controller: _schoolController,
      icon: Icons.school,
      hintText: "School Name",
      validator: Validators.validateSchool
    );
  }

  Widget _buildClassField() {
    return AppTextfield(
      controller: _classController,
      icon: Icons.class_,
      hintText: "Class Name",
      validator: Validators.validateClass
    );
  }
  Widget _buildReferNumberField() {
    return AppTextfield(
      controller: _referNumberController,
      icon: Icons.group_add,
      hintText: _isFirstTeacher ? "Create Unique Refer Number" : "Enter Refer Number",
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a refer number';
        }
        return null;
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (_showOtpField) {
          await _verifyOtpAndCreateAccount();
        } else {
          await _createAccountWithEmail();
        }
      } catch (e) {
        _showErrorSnackBar('Error: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createAccountWithEmail() async {
    if (!_isFirstTeacher) {
      bool referExists = await _checkReferNumber(_referNumberController.text);
      if (!referExists) {
        _showErrorSnackBar('Invalid refer number');
        return;
      }
    }

    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    await _addTeacherToFirestore(userCredential.user!.uid);
    _showSuccessSnackBar('Account created successfully');
  }

  Future<void> _verifyOtpAndCreateAccount() async {
    if (!_isFirstTeacher) {
      bool referExists = await _checkReferNumber(_referNumberController.text);
      if (!referExists) {
        _showErrorSnackBar('Invalid refer number');
        return;
      }
    }

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: _otpController.text,
    );

    UserCredential userCredential = await _auth.signInWithCredential(credential);
    await _addTeacherToFirestore(userCredential.user!.uid);
    _showSuccessSnackBar('Account created successfully');
  }

  Future<void> _addTeacherToFirestore(String uid) async {
    await _firestore.collection('teachers').doc(uid).set({
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'school': _schoolController.text,
      'class': _classController.text,
      'referNumber': _referNumberController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
   Future<void> _sendOtp() async {
    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await _addTeacherToFirestore(_auth.currentUser!.uid);
          _showSuccessSnackBar('Account created successfully');
        },
        verificationFailed: (FirebaseAuthException e) {
          _showErrorSnackBar('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _showOtpField = true;
          });
          _showSuccessSnackBar('OTP sent successfully');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkReferNumber(String referNumber) async {
    var querySnapshot = await _firestore
        .collection('teachers')
        .where('referNumber', isEqualTo: referNumber)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }
}