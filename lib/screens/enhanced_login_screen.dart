import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EnhancedLoginScreen extends StatefulWidget {
  final VoidCallback onSignUpPressed;

  const EnhancedLoginScreen({super.key, required this.onSignUpPressed});

  @override
  State<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtpForLogin() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      return;
    }

    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Send OTP
      await _authService.sendOtpToEmail(email: email);

      if (mounted) {
        // Navigate to OTP verification screen with password
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationWithPasswordScreen(
              email: email,
              password: _passwordController.text,
              authMode: 'login',
              onSuccess: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Icons.local_fire_department,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Forest Fire Monitor',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),
                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900], fontSize: 12),
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),
                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !_isLoading,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Password Field
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !_isLoading,
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 24),
                // Sign In with OTP Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtpForLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enter your password, then verify with OTP',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Divider
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: Colors.grey)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 32),
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : widget.onSignUpPressed,
                      child: const Text('Sign Up'),
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

/// OTP Verification screen with password for login
class OtpVerificationWithPasswordScreen extends StatefulWidget {
  final String email;
  final String password;
  final String authMode;
  final VoidCallback onSuccess;

  const OtpVerificationWithPasswordScreen({
    super.key,
    required this.email,
    required this.password,
    required this.authMode,
    required this.onSuccess,
  });

  @override
  State<OtpVerificationWithPasswordScreen> createState() =>
      _OtpVerificationWithPasswordScreenState();
}

class _OtpVerificationWithPasswordScreenState
    extends State<OtpVerificationWithPasswordScreen> {
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
      // Complete login with password + OTP
      await _authService.completeLoginWithOtp(
        email: widget.email,
        password: widget.password,
        otp: otp,
      );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isLoading ? null : const BackButton(),
        title: const Text('Enter OTP'),
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
                  Icons.security,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify Your Identity',
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
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
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
                          counterText: '',
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
                          'Verify & Sign In',
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
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    if (_canResend)
                      TextButton(
                        onPressed: _isLoading ? null : _resendOtp,
                        child: const Text('Resend OTP'),
                      )
                    else
                      Text(
                        'Resend in $_resendCountdown seconds',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
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
