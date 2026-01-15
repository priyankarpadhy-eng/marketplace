import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/services/web_auth_service.dart';
import '../../../core/theme/uber_money_theme.dart';

/// A self-contained widget handling Web Phone Login flow.
class WebPhoneLoginWidget extends StatefulWidget {
  final Function(UserCredential) onLoginSuccess;

  const WebPhoneLoginWidget({super.key, required this.onLoginSuccess});

  @override
  State<WebPhoneLoginWidget> createState() => _WebPhoneLoginWidgetState();
}

class _WebPhoneLoginWidgetState extends State<WebPhoneLoginWidget> {
  final _webAuthService = WebAuthService();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isCodeSent = false;
  ConfirmationResult? _confirmationResult;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('Please enter a valid phone number');
      return;
    }

    // Ensure E.164 format
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';

    setState(() => _isLoading = true);

    try {
      final result = await _webAuthService.signInWithPhoneNumber(
        formattedPhone,
      );

      if (mounted) {
        setState(() {
          _confirmationResult = result;
          _isCodeSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OTP Sent!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  Future<void> _verifyCode() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || _confirmationResult == null) {
      _showError('Please enter a valid OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _webAuthService.verifyOTP(
        confirmationResult: _confirmationResult!,
        otp: otp,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLoginSuccess(userCredential);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: UberMoneyTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only verify platform check purely for this widget's strict logic
    // though the service handles checks too.
    if (!_webAuthService.isWeb) {
      return const Center(child: Text('Phone Login is only supported on Web'));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: UberMoneyTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: UberMoneyTheme.shadowMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCodeSent ? 'Enter Verification Code' : 'Phone Login',
            style: UberMoneyTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _isCodeSent
                ? 'Sent to ${_phoneController.text}'
                : 'Enter your phone number to continue',
            style: UberMoneyTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          if (!_isCodeSent) _buildPhoneInput() else _buildOtpInput(),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixText: '+91 ',
            prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: UberMoneyTheme.primary, // Black
              foregroundColor: UberMoneyTheme.textLight, // White
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Send Code'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          maxLength: 6,
          decoration: const InputDecoration(
            counterText: '',
            hintText: '000000',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: UberMoneyTheme.primary,
              foregroundColor: UberMoneyTheme.textLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Verify & Login'),
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _isCodeSent = false;
                    _otpController.clear();
                  });
                },
          child: const Text('Change Number'),
        ),
      ],
    );
  }
}
