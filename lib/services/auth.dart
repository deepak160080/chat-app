import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthMethods{

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPassword(String email, String password) async{
    try{
      UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    }
    on FirebaseAuthException catch(e){
      print(e.message);
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async{
    try{
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    }
    on FirebaseAuthException catch(e){
      print(e.message);
    }
    return null;
  }

  Future resetPassword(String email) async{
    try{
      return await _auth.sendPasswordResetEmail(email: email);
    }
    on FirebaseAuthException catch(e){
      print(e.message);
    }
    return null;
  }


  Future signOut() async{
    try{
      return await _auth.signOut();
    }
    on FirebaseAuthException catch(e){
      print(e.message);
    }
    return null;
  }

  Future sendResetPasswordEmail(String email) async{
    try{
      return await _auth.sendPasswordResetEmail(email: email);
    }
    on FirebaseAuthException catch(e){
      print(e.message);
    }
    return null;
  }
}






class AuthFunctions {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> createAccountWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendOtp(String phoneNumber, Function(String) onCodeSent, Function(String) onError) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+1$phoneNumber',  // Adjust country code as needed
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> verifyOtpAndCreateAccount(String verificationId, String otp) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> addTeacherToFirestore(String uid, Map<String, dynamic> teacherData) async {
    await _firestore.collection('teachers').doc(uid).set({
      ...teacherData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }
}