import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';

class EnhancedSignupScreen extends StatefulWidget {
  final VoidCallback onSignInPressed;

  const EnhancedSignupScreen({super.key, required this.onSignInPressed});

  @override
  State<EnhancedSignupScreen> createState() => _EnhancedSignupScreenState();
}

class _EnhancedSignupScreenState extends State<EnhancedSignupScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _proceedToOtp() async {
    final email = _emailController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    print(
      '📝 _proceedToOtp called with email: $email, fullName: $fullName, phone: $phone',
    );
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

    if (fullName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name';
      });
      return;
    }

    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }

    if (!RegExp(r'^\+?[0-9]{10,}$').hasMatch(phone.replaceAll(' ', ''))) {
      setState(() {
        _errorMessage =
            'Please enter a valid phone number (at least 10 digits)';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a password';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the Terms & Conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Store temporary signup data
      await _authService.storeTempSignupData(
        email: email,
        fullName: fullName,
        phoneNumber: phone,
        password: password,
      );

      // Send OTP
      await _authService.sendOtpToEmail(email: email, fullName: fullName);

      if (mounted) {
        // Navigate to OTP verification screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: email,
              authMode: 'signup',
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
                const SizedBox(height: 24),
                Icon(
                  Icons.local_fire_department,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Forest Fire Monitor',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
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
                // Full Name Field
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: 12),
                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'you@example.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !_isLoading,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                // Phone Field
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1 (555) 123-4567',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !_isLoading,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                // Password Field
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 8 characters',
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
                const SizedBox(height: 12),
                // Confirm Password Field
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !_isLoading,
                  ),
                  obscureText: _obscureConfirmPassword,
                ),
                const SizedBox(height: 16),
                // Terms Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                    ),
                    Expanded(
                      child: Text(
                        'I agree to Terms & Conditions',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Continue Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _proceedToOtp,
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
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
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
                          'We\'ll send a 6-digit code to verify your email',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : widget.onSignInPressed,
                      child: const Text('Sign In'),
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
