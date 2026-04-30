# Enhanced Email OTP Authentication - Complete Guide

## ✨ What's Changed

### New Authentication Flows

#### **SIGNUP FLOW (Enhanced)**
```
1. User enters: Email, Full Name, Phone Number, Password (with confirm)
2. Agree to Terms & Conditions
3. Click "Continue"
4. OTP sent to email
5. User enters 6-digit OTP code
6. Account created with all provided data
7. User logged in automatically
```

#### **LOGIN FLOW (Enhanced with Password + OTP)**
```
1. User enters: Email, Password
2. Click "Sign In"
3. OTP sent to email
4. User enters 6-digit OTP code
5. Both password AND OTP verified
6. User logged in (Double security!)
```

---

## 📋 What's New

### New Files Created:
1. **`lib/screens/enhanced_signup_screen.dart`** - Complete signup with name, phone, password
2. **`lib/screens/enhanced_login_screen.dart`** - Login with password + OTP verification

### Files Modified:
1. **`lib/services/auth_service.dart`** - Enhanced OTP sending & verification
2. **`lib/screens/otp_verification_screen.dart`** - Updated for new flows

### Key Features Added:
- ✅ Phone number field with validation (10+ digits)
- ✅ Password field with confirmation
- ✅ Terms & Conditions checkbox
- ✅ Password + OTP dual authentication for login
- ✅ Better error logging for OTP delivery
- ✅ Debug print statements for troubleshooting
- ✅ Enhanced email sender configuration

---

## 🔧 OTP Delivery Troubleshooting

### Why OTP Might Not Be Coming

#### **Issue 1: Unverified Sender Email**
**Problem:** The sender email `noreply@forestfire.com` is not verified in Brevo account.

**Solution:**
1. Go to Brevo Dashboard → Senders
2. Add and verify `noreply@forestfire.com`
3. OR use an already verified email

**Current Fix Applied:**
```dart
'sender': {
  'name': 'Forest Fire Monitor',
  'email': 'noreply+forestfire@gmail.com',  // More reliable format
}
```

#### **Issue 2: API Key Invalid or Expired**
**Problem:** Brevo API key is incorrect or has been rotated.

**Solution:**
1. Get new API key from Brevo Dashboard
2. Update in `lib/services/auth_service.dart`:
```dart
static const String brevoApiKey = 'YOUR_NEW_API_KEY';
```

#### **Issue 3: Email Quota Exceeded**
**Problem:** Brevo account has exceeded daily email limit.

**Solution:**
1. Check Brevo Dashboard for usage stats
2. Upgrade account plan if needed
3. Wait for quota reset (usually next day)

#### **Issue 4: Network/Timeout Issues**
**Problem:** Slow internet or API timeout.

**Solution:**
- Increased timeout from 10s to 15s
- Check internet connection
- Try again

#### **Issue 5: Email Filtered by Gmail/Outlook**
**Problem:** OTP email goes to spam/junk folder.

**Solution:**
1. Check spam folder
2. Mark as "Not Spam"
3. Add sender to contacts

---

## 🐛 Debug OTP Sending

### Enable Debug Logs
The app now prints debug information to console:

```
📧 Sending OTP to user@example.com...
OTP Code: 123456
📬 Brevo Response Status: 201
📬 Response Body: {"messageId":"unique-id"}
✅ OTP sent successfully to user@example.com
```

### Check Console Output
1. Run app with: `flutter run -v` (verbose mode)
2. Look for 📧, 📬, ✅, ❌ emojis
3. Note the OTP code and response status

### Test Endpoint Directly
Use Postman or curl to test Brevo API:

```bash
curl -X POST https://api.brevo.com/v3/smtp/email \
  -H 'api-key: YOUR_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "to": [{"email": "test@example.com", "name": "Test"}],
    "sender": {"name": "Test", "email": "verified@example.com"},
    "subject": "Test OTP: 123456",
    "htmlContent": "<p>OTP: 123456</p>"
  }'
```

---

## 🎯 How to Use Enhanced Screens

### Replace Original Screens
Update your `main.dart` to use new screens:

```dart
// OLD
LoginScreen(onSignUpPressed: ...)
SignUpScreen(onSignInPressed: ...)

// NEW
EnhancedLoginScreen(onSignUpPressed: ...)
EnhancedSignupScreen(onSignInPressed: ...)
```

### Import New Screens
```dart
import 'screens/enhanced_login_screen.dart';
import 'screens/enhanced_signup_screen.dart';
```

---

## 🔐 Security Features

### Signup Security
- ✅ Email format validation
- ✅ Phone number validation (10+ digits)
- ✅ Password strength requirement (8+ chars)
- ✅ Confirm password verification
- ✅ Terms & Conditions agreement
- ✅ OTP verification before account creation

### Login Security
- ✅ Email validation
- ✅ Password verification
- ✅ OTP verification (2-factor!)
- ✅ Max 5 OTP attempts
- ✅ 10-minute OTP expiration
- ✅ 60-second resend cooldown

---

## 🧪 Testing Checklist

### Test Signup
- [ ] Enter all required fields
- [ ] Invalid email format → Error shown
- [ ] Invalid phone (< 10 digits) → Error shown
- [ ] Password < 8 chars → Error shown
- [ ] Passwords don't match → Error shown
- [ ] Uncheck terms → Can't continue
- [ ] Click Continue → OTP sent
- [ ] Check email for 6-digit code
- [ ] Enter OTP → Account created
- [ ] Login automatically after signup

### Test Login
- [ ] Enter email + password
- [ ] Click Sign In
- [ ] OTP sent to email
- [ ] Enter OTP → Login successful
- [ ] Try wrong password first → OTP sent anyway (then fails on OTP)
- [ ] Try wrong OTP → Error message

### Test OTP Behavior
- [ ] Resend OTP before 60s → Disabled
- [ ] Resend OTP after 60s → Works, new code sent
- [ ] Wait 11 min before entering OTP → Expired error
- [ ] Enter >5 wrong codes → Too many attempts error
- [ ] Clear app data → OTP resets

---

## 📧 Brevo Email Configuration

### Verified Sender Emails (Add These)
1. **noreply+forestfire@gmail.com** (recommended - works reliably)
2. **support@forestfire.com** (if domain registered)
3. **noreply@forestfire.com** (if verified in Brevo)

### Step 1: Verify Sender in Brevo
1. Login to Brevo → Senders
2. Click "Add a sender"
3. Enter email and name
4. Confirm verification link in email
5. Email is now verified for sending

### Step 2: Update Code (if needed)
In `lib/services/auth_service.dart`:
```dart
'sender': {
  'name': 'Forest Fire Monitor',
  'email': 'your-verified@email.com',  // Update this
}
```

---

## 🚀 API Integration Details

### Brevo SMTP Email Endpoint

**URL:** `https://api.brevo.com/v3/smtp/email`  
**Method:** POST  
**Auth:** API key in header  

### Request Format
```json
{
  "to": [{"email": "user@example.com", "name": "User Name"}],
  "sender": {
    "name": "Forest Fire Monitor",
    "email": "verified@email.com"
  },
  "subject": "Your Forest Fire Monitor OTP Code: 123456",
  "htmlContent": "<html>...</html>",
  "replyTo": {
    "email": "support@forestfire.com",
    "name": "Support"
  }
}
```

### Response
- **Success (201):** `{"messageId": "unique-id"}`
- **Error (400+):** `{"code": "error_code", "message": "description"}`

---

## 💾 Data Flow

### Signup Data Flow
```
User fills form
    ↓
Validates input (email, phone, password)
    ↓
Calls storeTempSignupData() → Saves to _tempUserData map
    ↓
Calls sendOtpToEmail() → Brevo API sends email
    ↓
Navigate to OTP screen
    ↓
User enters OTP
    ↓
Calls completeSignupWithOtp() 
    ├─ Verifies OTP
    ├─ Creates Firebase account with password
    ├─ Sets display name
    └─ Clears temp data
    ↓
Success! User logged in
```

### Login Data Flow
```
User enters email + password
    ↓
Calls sendOtpForLogin()
    ├─ Validates email
    └─ Sends OTP via Brevo
    ↓
Navigate to OTP screen
    ↓
User enters OTP
    ↓
Calls completeLoginWithOtp()
    ├─ Verifies password via Firebase
    ├─ Verifies OTP locally
    └─ Returns authenticated user
    ↓
Success! User logged in with dual auth
```

---

## 📝 Code Examples

### Send OTP with Debug Output
```dart
await _authService.sendOtpToEmail(
  email: 'user@example.com',
  fullName: 'John Doe',
);
// Console output shows OTP code and Brevo response
```

### Complete Signup with OTP
```dart
await _authService.completeSignupWithOtp(
  email: 'user@example.com',
  otp: '123456',
);
// Account created with stored name, phone, password
```

### Complete Login with Password + OTP
```dart
await _authService.completeLoginWithOtp(
  email: 'user@example.com',
  password: 'userPassword123',
  otp: '123456',
);
// Both password and OTP verified
```

---

## ⚠️ Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| OTP not received | Unverified sender email | Verify email in Brevo dashboard |
| "Failed to send OTP" | Invalid API key | Update API key in code |
| "Too many failed attempts" | >5 wrong OTP entries | Request new OTP after 1 minute |
| "OTP expired" | >10 minutes passed | Request new OTP |
| Email in spam | Sender reputation | Warm up Brevo account |
| Timeout error | Slow network | Check internet connection |
| Account exists error | Email already registered | Use different email or login |

---

## 🔄 Production Deployment Checklist

Before deploying to production:

- [ ] Update Brevo API key in environment variables (NOT hardcoded)
- [ ] Verify all sender emails in Brevo dashboard
- [ ] Move OTP storage to Firebase Firestore (not in-memory)
- [ ] Implement backend OTP verification
- [ ] Add rate limiting per IP address
- [ ] Set up error monitoring (Sentry/Crashlytics)
- [ ] Configure CORS if using backend
- [ ] Test with real email addresses
- [ ] Set up SSL certificates
- [ ] Enable email authentication (SPF, DKIM, DMARC)
- [ ] Configure bounce handling
- [ ] Set up email logs monitoring

---

## 📞 Support

### Brevo Support
- Dashboard: https://app.brevo.com
- API Docs: https://developers.brevo.com/docs
- Status: https://status.brevo.com

### Firebase Support
- Console: https://console.firebase.google.com
- Docs: https://firebase.google.com/docs

---

## 📊 Testing Email Delivery

### Real-time Testing
1. Enter test email during signup
2. Watch browser console for OTP code
3. Check email inbox (also check spam)
4. Enter code to complete signup

### Using Test Emails
- Gmail: Use `email+tag@gmail.com` format
- Outlook: Check Clutter folder
- Brevo Sandbox: Can test without real emails

---

Last Updated: April 23, 2026  
Status: ✅ Ready for Testing
