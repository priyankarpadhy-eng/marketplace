import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/uber_money_theme.dart';
import '../auth_controller.dart';
import 'package:firebase_core/firebase_core.dart';

class PhoneVerificationSheet extends ConsumerStatefulWidget {
  const PhoneVerificationSheet({super.key});

  @override
  ConsumerState<PhoneVerificationSheet> createState() =>
      _PhoneVerificationSheetState();
}

class _PhoneVerificationSheetState
    extends ConsumerState<PhoneVerificationSheet> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
    final number = _phoneController.text.trim();
    if (number.isEmpty || number.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number')),
      );
      return;
    }

    // Basic formatting - assuming India for now as per other code context
    final formattedNumber = number.startsWith('+') ? number : '+91$number';

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _finalizeVerification(credential, formattedNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification Failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          _showOtpDialog(verificationId, formattedNumber);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showOtpDialog(String verificationId, String number) async {
    final otpController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the code sent to $number'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '123456',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final smsCode = otpController.text.trim();
              if (smsCode.isNotEmpty) {
                final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: smsCode,
                );
                Navigator.pop(context);
                await _finalizeVerification(credential, number);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeVerification(
    PhoneAuthCredential credential,
    String number,
  ) async {
    setState(() => _isLoading = true);
    try {
      // Use secondary app to verify without logging out main user
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryVerify');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryVerify',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      await secondaryAuth.signInWithCredential(credential);
      await secondaryAuth.signOut();

      // Update backend
      if (mounted) {
        final success = await ref
            .read(authControllerProvider.notifier)
            .addVerifiedContactNumber(number);

        if (mounted) {
          if (success) {
            Navigator.pop(context); // Close sheet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Phone number verified successfully!'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update profile.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Verification Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verify Phone Number',
            style: UberMoneyTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'To see all rides, you must verify your phone number.',
            style: UberMoneyTheme.bodyMedium.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: UberMoneyTheme.inputDecoration(
              hintText: 'Enter your phone number',
              prefixIcon: const Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyPhoneNumber,
            style: UberMoneyTheme.primaryButtonStyle,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Verify Number'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
