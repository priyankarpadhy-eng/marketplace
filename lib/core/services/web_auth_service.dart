import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to handle Web Phone Authentication
class WebAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Checks if the current platform is Web
  bool get isWeb => kIsWeb;

  /// Sends OTP to the provided phone number.
  ///
  /// On Web, this triggers the reCAPTCHA verifier automatically.
  /// Returns a [ConfirmationResult] which is used to verify the code later.
  Future<ConfirmationResult> signInWithPhoneNumber(String phoneNumber) async {
    if (!isWeb) {
      throw Exception('WebAuthService should only be used on Web platforms.');
    }

    try {
      // The reCAPTCHA verification is handled automatically by the Firebase SDK
      // when no RecaptchaVerifier is passed. It defaults to an invisible reCAPTCHA
      // or a widget if verification is required.
      final ConfirmationResult result = await _auth.signInWithPhoneNumber(
        phoneNumber,
      );
      return result;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verifies the OTP using the [ConfirmationResult] obtained from signInWithPhoneNumber.
  Future<UserCredential> verifyOTP({
    required ConfirmationResult confirmationResult,
    required String otp,
  }) async {
    if (!isWeb) {
      throw Exception('WebAuthService should only be used on Web platforms.');
    }

    try {
      final UserCredential userCredential = await confirmationResult.confirm(
        otp,
      );
      return userCredential;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }
}
