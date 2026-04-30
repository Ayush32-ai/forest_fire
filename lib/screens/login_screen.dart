import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSignUpPressed;

  const LoginScreen({
    super.key,
    required this.onSignUpPressed,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _useOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
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

  Future<void> _sendOtpLogin() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
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
        // Navigate to OTP verification screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: email,
              authMode: 'login',
              onSuccess: () {
                Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                );
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 48),
                // Login Method Toggle
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: !_useOtp
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _useOtp = false;
                                      _errorMessage = null;
                                    });
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Password',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_useOtp
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Material(
                          color: _useOtp
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _useOtp = true;
                                      _errorMessage = null;
                                    });
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Email OTP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _useOtp
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),
                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !_isLoading,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Password Field (only show if not using OTP)
                if (!_useOtp)
                  Column(
                    children: [
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
                    ],
                  ),
                // Sign In/OTP Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_useOtp ? _sendOtpLogin : _signIn),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _useOtp ? 'Send OTP' : 'Sign In',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                // Google Sign In Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Image.asset(
                    'assets/google_logo.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.login),
                  ),
                  label: const Text('Sign in with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
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
