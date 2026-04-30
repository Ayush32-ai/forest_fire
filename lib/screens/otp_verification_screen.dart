import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String authMode; // 'signup' or 'login'
  final VoidCallback onSuccess;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.authMode,
    required this.onSuccess,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthService _authService = AuthService();
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;
  bool _isVerifying = false; // guard against double-tap
  String? _errorMessage;
  int _resendCountdown = 0;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendTimer();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  String _getOtp() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;
    _isVerifying = true;

    final otp = _getOtp();

    if (otp.length != 6) {
      _isVerifying = false;
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.authMode == 'signup') {
        // For new enhanced signup flow
        await _authService.completeSignupWithOtp(email: widget.email, otp: otp);
      } else {
        // For old/basic login OTP flow (if still needed)
        await _authService.signInWithOtp(email: widget.email, otp: otp);
      }

      if (mounted) {
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      _isVerifying = false;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendOtpToEmail(email: widget.email);
      _startResendTimer();

      if (mounted) {
        // Clear all fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes.first.requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleOtpInput(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _handleKeyDown(int index, RawKeyEvent event) {
    if (event.isKeyPressed(LogicalKeyboardKey.backspace) &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isLoading ? null : const BackButton(),
        title: const Text('Verify Email'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.mail_outline,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify Your Email',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the 6-digit code sent to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 50,
                      height: 60,
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (event) => _handleKeyDown(index, event),
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (value) => _handleOtpInput(index, value),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900], fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 24),
                // Verify Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Theme.of(context).primaryColor,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // Resend OTP
                Column(
                  children: [
                    const Text(
                      "Didn't receive the code?",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    if (_canResend)
                      TextButton(
                        onPressed: _isLoading ? null : _resendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Text(
                        'Resend in $_resendCountdown seconds',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
