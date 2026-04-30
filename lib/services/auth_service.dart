import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';
import 'firestore_service.dart';
import '../config/app_secrets.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Debug counter to track instances
  static int _instanceCounter = 0;
  final int _instanceId;

  AuthService() : _instanceId = ++_instanceCounter {
    print('🏗️ AuthService instance $_instanceId created');
  }

  // Brevo API Configuration
  static const String brevoApiKey = AppSecrets.brevoApiKey;
  static const String brevoApiUrl = 'https://api.brevo.com/v3';

  // Secure storage for OTP and temp user data persistence
  static const _secureStorage = FlutterSecureStorage();

  // Storage key prefixes
  static const String _otpPrefix = 'otp_';
  static const String _tempUserPrefix = 'temp_user_';

  // Simple verification guard
  static final Set<String> _currentlyVerifying = {};

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Get user stream
  Stream<User?> get userStream => _firebaseAuth.authStateChanges();

  // Email Sign Up
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email Sign In
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn
          .signIn();
      if (googleSignInAccount == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Reset Password
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'The user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-credential':
        return 'The provided credential is invalid.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in provider.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // ============ OTP METHODS ============

  /// Generate a 6-digit OTP
  String _generateOtp() {
    Random random = Random();
    int otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  /// Send OTP to email using Brevo
  Future<void> sendOtpToEmail({required String email, String? fullName}) async {
    try {
      final String normalizedEmail = email.trim().toLowerCase();
      final String otp = _generateOtp();

      // Persist OTP in secure storage so it survives hot reload
      final otpData = jsonEncode({
        'otp': otp,
        'timestamp': DateTime.now().toIso8601String(),
        'attempts': 0,
      });

      print('💾 About to store OTP data: $otpData');
      await _secureStorage.write(
        key: '$_otpPrefix$normalizedEmail',
        value: otpData,
      );

      // Verify it was stored
      final verification = await _secureStorage.read(
        key: '$_otpPrefix$normalizedEmail',
      );
      print('✅ Verification read back: $verification');

      print('💾 OTP stored in secure storage for $normalizedEmail');

      // Prepare email content - Using proper Brevo format
      final Map<String, dynamic> emailData = {
        'to': [
          {'email': normalizedEmail, 'name': fullName ?? 'User'},
        ],
        'sender': {
          'name': 'Forest Fire Monitor',
          'email': 'ayush18x4@gmail.com', // ✅ Your verified Gmail account
        },
        'subject': 'Your Forest Fire Monitor OTP Code: $otp',
        'htmlContent': _generateOtpEmailHtml(otp, fullName ?? 'User'),
        'replyTo': {'email': 'ayush18x4@gmail.com', 'name': 'Support'},
      };

      print('📧 Sending OTP to $email...');
      print('OTP Code: $otp');

      // Send email via Brevo
      final response = await http
          .post(
            Uri.parse('$brevoApiUrl/smtp/email'),
            headers: {
              'Content-Type': 'application/json',
              'api-key': brevoApiKey,
              'Accept': 'application/json',
            },
            body: jsonEncode(emailData),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Email send request timed out (15s)'),
          );

      print('📬 Brevo Response Status: ${response.statusCode}');
      print('📬 Response Body: ${response.body}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(
            'Brevo Error (${response.statusCode}): ${errorBody['message'] ?? errorBody['error'] ?? 'Unknown error'}',
          );
        } catch (e) {
          throw Exception(
            'Failed to send OTP (${response.statusCode}): ${response.body}',
          );
        }
      }

      print('✅ OTP sent successfully to $email');
    } catch (e) {
      print('❌ Error sending OTP: $e');
      throw Exception('Error sending OTP: $e');
    }
  }

  /// Generate HTML email template for OTP
  String _generateOtpEmailHtml(String otp, String name) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f4; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; }
        .header { text-align: center; color: #ff6b35; margin-bottom: 20px; }
        .otp-code { font-size: 32px; font-weight: bold; color: #ff6b35; text-align: center; letter-spacing: 5px; padding: 20px; background-color: #f9f9f9; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; color: #999; font-size: 12px; margin-top: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🔥 Forest Fire Monitor</h1>
        </div>
        <p>Hello $name,</p>
        <p>Your One-Time Password (OTP) for Forest Fire Monitor is:</p>
        <div class="otp-code">$otp</div>
        <p>This code will expire in 10 minutes. Do not share this code with anyone.</p>
        <p>If you did not request this code, please ignore this email.</p>
        <div class="footer">
          <p>&copy; 2026 Forest Fire Monitor. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Verify OTP
  Future<bool> verifyOtp({required String email, required String otp}) async {
    final String normalizedEmail = email.trim().toLowerCase();

    // Simple guard against concurrent verification
    if (_currentlyVerifying.contains(normalizedEmail)) {
      print(
        '🚫 verifyOtp already in progress for $normalizedEmail, blocking duplicate call',
      );
      throw Exception('Verification already in progress. Please wait.');
    }

    // Mark as currently verifying
    _currentlyVerifying.add(normalizedEmail);

    try {
      print(
        '🔍 verifyOtp called for: "$normalizedEmail" (instance $_instanceId)',
      );
      print('🔍 Looking for key: "$_otpPrefix$normalizedEmail"');

      final stored = await _secureStorage.read(
        key: '$_otpPrefix$normalizedEmail',
      );

      print('🔍 stored OTP data: $stored');

      if (stored == null) {
        throw Exception(
          'No OTP found for this email. Please request a new one.',
        );
      }

      final otpData = jsonDecode(stored) as Map<String, dynamic>;
      final storedOtp = otpData['otp'] as String;
      final timestamp = DateTime.parse(otpData['timestamp'] as String);
      int attempts = otpData['attempts'] as int;

      // Check if OTP expired (10 minutes)
      if (DateTime.now().difference(timestamp).inMinutes > 10) {
        await _secureStorage.delete(key: '$_otpPrefix$normalizedEmail');
        throw Exception('OTP has expired. Please request a new one.');
      }

      // Check attempts (max 5)
      if (attempts >= 5) {
        await _secureStorage.delete(key: '$_otpPrefix$normalizedEmail');
        throw Exception('Too many failed attempts. Please request a new OTP.');
      }

      if (storedOtp != otp) {
        final updated = jsonEncode({
          'otp': storedOtp,
          'timestamp': otpData['timestamp'],
          'attempts': attempts + 1,
        });
        await _secureStorage.write(
          key: '$_otpPrefix$normalizedEmail',
          value: updated,
        );
        throw Exception('Invalid OTP. Please try again.');
      }

      // Check if OTP was already used
      final isUsed = otpData['used'] as bool? ?? false;
      if (isUsed) {
        print('🔄 OTP already used, returning success for duplicate call');
        return true;
      }

      // Mark OTP as used (but don't delete yet)
      final usedOtpData = jsonEncode({
        'otp': storedOtp,
        'timestamp': otpData['timestamp'],
        'attempts': attempts,
        'used': true,
        'usedAt': DateTime.now().toIso8601String(),
      });
      await _secureStorage.write(
        key: '$_otpPrefix$normalizedEmail',
        value: usedOtpData,
      );

      print('✅ OTP verified and marked as used for $normalizedEmail');

      // Schedule cleanup after 1 minute (to allow duplicate calls to see "used" status)
      Future.delayed(const Duration(minutes: 1), () async {
        await _secureStorage.delete(key: '$_otpPrefix$normalizedEmail');
        print('🧹 Cleaned up used OTP for $normalizedEmail');
      });

      return true;
    } finally {
      // Always remove from verification set
      _currentlyVerifying.remove(normalizedEmail);
    }
  }

  /// Store temporary signup data (email, name, phone, password)
  Future<void> storeTempSignupData({
    required String email,
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();
    print('💾 storeTempSignupData called for: $normalizedEmail');

    final tempData = jsonEncode({
      'email': normalizedEmail,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'password': password,
      'timestamp': DateTime.now().toIso8601String(),
    });

    print('💾 About to store temp data: $tempData');
    await _secureStorage.write(
      key: '$_tempUserPrefix$normalizedEmail',
      value: tempData,
    );

    // Verify it was stored
    final verification = await _secureStorage.read(
      key: '$_tempUserPrefix$normalizedEmail',
    );
    print('✅ Verification read back: $verification');

    print(
      '✅ Temporary signup data stored in secure storage for $normalizedEmail',
    );
  }

  /// Complete signup with OTP verification
  Future<UserCredential> completeSignupWithOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final String normalizedEmail = email.trim().toLowerCase();

      print('📝 completeSignupWithOtp called for: $normalizedEmail');

      // Verify OTP first
      await verifyOtp(email: normalizedEmail, otp: otp);

      print(
        '✅ OTP verified, now looking for temp data with key: "$_tempUserPrefix$normalizedEmail"',
      );

      // Get temporary user data from secure storage
      final storedTempData = await _secureStorage.read(
        key: '$_tempUserPrefix$normalizedEmail',
      );
      print('📝 Retrieved temp data: $storedTempData');

      if (storedTempData == null) {
        throw Exception('Signup data not found. Please try again.');
      }

      final userData = jsonDecode(storedTempData) as Map<String, dynamic>;
      final password = userData['password'] as String;
      final fullName = userData['fullName'] as String;
      final phoneNumber = userData['phoneNumber'] as String;

      // Create Firebase account with provided password
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );

      // Update user profile with display name
      await userCredential.user?.updateDisplayName(fullName);

      // Save user profile to Firestore
      if (userCredential.user != null) {
        await _firestoreService.saveUserProfile(
          userId: userCredential.user!.uid,
          name: fullName,
          email: normalizedEmail,
          phoneNumber: phoneNumber,
        );
      }

      print(
        '✅ User account created: $normalizedEmail, Name: $fullName, Phone: $phoneNumber',
      );

      // Clean up temporary data
      await _secureStorage.delete(key: '$_tempUserPrefix$normalizedEmail');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Complete login with password + OTP verification
  Future<UserCredential> completeLoginWithOtp({
    required String email,
    required String password,
    required String otp,
  }) async {
    try {
      final String normalizedEmail = email.trim().toLowerCase();

      // Verify OTP first (before signing in, so we don't sign in with wrong OTP)
      await verifyOtp(email: normalizedEmail, otp: otp);

      print('✅ OTP verified for $normalizedEmail');

      // Now sign in with password
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );

      print('✅ Login successful for $normalizedEmail');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with OTP (legacy method for basic OTP login)
  Future<UserCredential> signInWithOtp({
    required String email,
    required String otp,
  }) async {
    try {
      // Verify OTP first
      await verifyOtp(email: email, otp: otp);

      // Check if user exists
      final signInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(
        email,
      );

      if (signInMethods.isEmpty) {
        throw Exception(
          'No account found with this email. Please sign up first.',
        );
      }

      // For OTP-only login, we'd need custom tokens from backend
      // This is a placeholder - in production you'd implement proper OTP-only auth
      throw Exception(
        'OTP-only login requires backend implementation. Please use email/password login.',
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Generate a secure random password
  String _generateSecurePassword() {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789!@#\$%^&*';
    Random random = Random();
    return List.generate(
      16,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
