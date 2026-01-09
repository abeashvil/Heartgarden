# Backend Authentication Setup Guide

## Overview
This guide explains how to integrate a real backend authentication service. The recommended approach is **Firebase Authentication**, which provides:
- Email/Password authentication
- Phone number authentication with SMS verification
- Apple Sign In integration
- Secure token management
- Free tier with generous limits

## Option 1: Firebase Authentication (Recommended)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name (e.g., "Flower App")
4. Disable Google Analytics (optional)
5. Click "Create Project"

### Step 2: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon
2. Enter your bundle ID: `abep.Flower-App` (check your Xcode project settings)
3. Register the app
4. Download `GoogleService-Info.plist`
5. Drag `GoogleService-Info.plist` into your Xcode project (make sure "Copy items if needed" is checked)

### Step 3: Install Firebase SDK

Add Firebase to your project using Swift Package Manager:

1. In Xcode: File → Add Packages...
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select "Up to Next Major Version"
4. Add these products:
   - FirebaseAuth
   - FirebaseCore

### Step 4: Enable Authentication Methods in Firebase Console

1. Go to Firebase Console → Authentication → Sign-in method
2. Enable:
   - **Email/Password**: Enable "Email/Password" and "Email link (passwordless sign-in)"
   - **Phone**: Enable "Phone" (requires Firebase Blaze plan for production, but free tier works for testing)
   - **Apple**: Enable "Apple" (requires Apple Developer account setup)

### Step 5: Configure Apple Sign In (if using)

1. In Firebase Console → Authentication → Sign-in method → Apple
2. Follow the setup instructions
3. You'll need to configure your Apple Developer account

### Step 6: Update Code

See the updated `AuthenticationManager.swift` and `SignUpView.swift` files that integrate Firebase.

## Option 2: Custom Backend (Node.js/Express Example)

If you prefer a custom backend, you'll need:

1. **Backend Server** (Node.js, Python, etc.)
2. **Database** (PostgreSQL, MongoDB, etc.)
3. **SMS Service** (Twilio, AWS SNS, etc.)
4. **JWT Token Management**

### Basic Architecture:
```
iOS App → Backend API → Database
              ↓
         SMS Service (for phone verification)
```

### Required Endpoints:
- `POST /auth/signup-email` - Email signup
- `POST /auth/signin-email` - Email signin
- `POST /auth/send-verification-code` - Send SMS code
- `POST /auth/verify-phone` - Verify phone with code
- `POST /auth/apple` - Apple Sign In verification

## Option 3: Supabase (Alternative to Firebase)

Supabase is an open-source Firebase alternative:

1. Go to [supabase.com](https://supabase.com)
2. Create a project
3. Install Supabase Swift SDK
4. Configure authentication methods

## Recommendation

**Use Firebase Authentication** because:
- ✅ Free tier is generous
- ✅ Easy iOS integration
- ✅ Built-in SMS verification
- ✅ Secure token management
- ✅ No backend code needed
- ✅ Scales automatically

## Next Steps

1. Choose your backend solution
2. Follow the setup steps above
3. Update the `AuthenticationManager.swift` code (provided in separate file)
4. Test each authentication method
5. Deploy to production

## Testing

- **Email/Password**: Test with real email addresses
- **Phone**: Test with your own phone number (Firebase free tier allows limited SMS)
- **Apple**: Test on a real device (simulator doesn't support Apple Sign In)

## Production Considerations

1. **Phone Authentication**: Requires Firebase Blaze plan (pay-as-you-go) for production SMS
2. **Rate Limiting**: Implement rate limiting to prevent abuse
3. **Error Handling**: Handle network errors gracefully
4. **Token Refresh**: Implement automatic token refresh
5. **Security**: Never expose API keys in client code

