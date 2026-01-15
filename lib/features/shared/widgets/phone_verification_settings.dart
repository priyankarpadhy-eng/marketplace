import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace/core/theme/uber_money_theme.dart';
import 'package:marketplace/features/auth/auth_controller.dart';
import 'package:marketplace/core/models/user_model.dart';

class PhoneVerificationSettings extends ConsumerStatefulWidget {
  final UserModel user;
  const PhoneVerificationSettings({super.key, required this.user});

  @override
  ConsumerState<PhoneVerificationSettings> createState() =>
      _PhoneVerificationSettingsState();
}

class _PhoneVerificationSettingsState
    extends ConsumerState<PhoneVerificationSettings> {
  List<Map<String, dynamic>> _contactNumbers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserContacts();
  }

  void _loadUserContacts() {
    if (widget.user.contactNumbers.isNotEmpty) {
      _contactNumbers = List<Map<String, dynamic>>.from(
        widget.user.contactNumbers.map(
          (c) => {...c, 'controller': TextEditingController(text: c['number'])},
        ),
      );
    } else {
      // Default primary if none exist
      _contactNumbers = [
        {
          'number': '',
          'type': 'primary',
          'verified': false,
          'controller': TextEditingController(),
        },
      ];
    }
  }

  @override
  void dispose() {
    for (var c in _contactNumbers) {
      if (c['controller'] is TextEditingController) {
        (c['controller'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  Future<void> _verifyNumber(int index) async {
    final controller =
        _contactNumbers[index]['controller'] as TextEditingController;
    final number = controller.text.trim();

    if (number.isEmpty || number.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    // Show Caution Dialog before starting
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Identity Verification'),
        content: const Text(
          "We are verifying your identity via Phone Number. This is required for safety and security. This does NOT automatically grant you selling privileges unless approved by admin.\n\nThank You,\nMarketplace Team",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    setState(() => _isLoading = true);

    try {
      // E.164 formatting
      final formattedNumber = number.startsWith('+') ? number : '+91$number';

      if (kIsWeb) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw 'No user logged in';

        final confirmationResult = await user.linkWithPhoneNumber(
          formattedNumber,
        );
        setState(() => _isLoading = false);
        _showOtpDialog(
          index,
          null,
          formattedNumber,
          webConfirmation: confirmationResult,
        );
      } else {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: formattedNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _finalizeVerification(index, credential, formattedNumber);
          },
          verificationFailed: (FirebaseAuthException e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Verification Failed: ${e.message}')),
              );
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            if (mounted) {
              setState(() => _isLoading = false);
              _showOtpDialog(index, verificationId, formattedNumber);
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showOtpDialog(
    int index,
    String? verificationId,
    String formattedNumber, {
    ConfirmationResult? webConfirmation,
  }) async {
    final otpController = TextEditingController();
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter code sent to $formattedNumber'),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final smsCode = otpController.text.trim();
              if (smsCode.isEmpty) return;

              Navigator.pop(ctx);
              _isLoading = true;
              if (mounted) setState(() {});

              if (webConfirmation != null) {
                // Web Flow
                try {
                  await webConfirmation.confirm(smsCode);
                  await _onVerificationSuccess(index, formattedNumber);
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Web Verification Failed: $e')),
                    );
                  }
                }
              } else {
                // Mobile Flow
                if (verificationId == null) {
                  setState(() => _isLoading = false);
                  return;
                }

                final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: smsCode,
                );
                await _finalizeVerification(index, credential, formattedNumber);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _onVerificationSuccess(int index, String verifiedNumber) async {
    // Update Local State
    setState(() {
      _contactNumbers[index]['verified'] = true;
      _contactNumbers[index]['number'] = verifiedNumber;
      _isLoading = false;
    });

    // Update Firestore Immediately
    await _updateFirestore();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Number Verified and Linked!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _finalizeVerification(
    int index,
    PhoneAuthCredential credential,
    String verifiedNumber,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }

      // Try to link the credential to the existing user
      try {
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          throw 'This phone number is already linked to another account.';
        } else if (e.code == 'provider-already-linked') {
          await user.updatePhoneNumber(credential);
        } else {
          rethrow;
        }
      }

      await _onVerificationSuccess(index, verifiedNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateFirestore() async {
    final uid = widget.user.uid;

    final contactsToSave = _contactNumbers
        .map(
          (c) => {
            'number': c['number'],
            'type': c['type'],
            'verified': c['verified'],
          },
        )
        .toList();

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'contactNumbers': contactsToSave,
    });

    ref.invalidate(currentUserProvider);
  }

  void _addNumber() {
    if (_contactNumbers.length >= 3) return;
    setState(() {
      _contactNumbers.add({
        'number': '',
        'type': 'secondary',
        'verified': false,
        'controller': TextEditingController(),
      });
    });
  }

  void _removeNumber(int index) {
    setState(() {
      if (_contactNumbers[index]['controller'] is TextEditingController) {
        (_contactNumbers[index]['controller'] as TextEditingController)
            .dispose();
      }
      _contactNumbers.removeAt(index);
    });
    _updateFirestore();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Details (Identity Verification)',
          style: UberMoneyTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Verified numbers help secure your account and build trust.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        ...List.generate(_contactNumbers.length, (index) {
          final c = _contactNumbers[index];
          final isPrimary = c['type'] == 'primary';
          final isVerified = c['verified'] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isPrimary ? 'Primary Number' : 'Backup Number',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (isVerified)
                        const Chip(
                          label: Text(
                            'Verified',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        )
                      else
                        const Chip(
                          label: Text('Unverified'),
                          backgroundColor: Colors.amber,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: c['controller'],
                          readOnly: isVerified,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!isVerified)
                        ElevatedButton(
                          onPressed: () => _verifyNumber(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Verify'),
                        ),
                      if (!isPrimary || (isVerified && isPrimary))
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeNumber(index),
                        ),
                    ],
                  ),
                  if (isVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'To change this number, delete it and add a new one.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),

        if (_contactNumbers.length < 3)
          OutlinedButton.icon(
            onPressed: _addNumber,
            icon: const Icon(Icons.add),
            label: const Text('Add Additional Number'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
      ],
    );
  }
}
