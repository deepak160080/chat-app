

class Validators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email or phone number';
    }
    bool isEmail = !RegExp(r'^[0-9]{10}$').hasMatch(value);
    if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
    
   
  }

static String? validateMobile(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your mobile number';
  }
  // Regular expression to match country code (optional) and 10-digit mobile number
  if (!RegExp(r'^\+?[0-9]{1,3}?[-. ]?[0-9]{10}$').hasMatch(value)) {
    return 'Please enter a valid mobile number with country code';
  }
  return null;
}

  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits long';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$').hasMatch(value)) {
      return 'Password must contain upper, lower, digit, and special char';
    }
    return null;
  }

  static String? validateSchool(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your school name';
    }
    if (value.length < 3) {
      return 'School name must be at least 3 characters long';
    }
    return null;
  }

  static String? validateClass(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your class name';
    }
    return null;
  }
}