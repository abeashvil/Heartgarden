# Firebase Setup - Step by Step

## Quick Start Checklist

- [ ] Create Firebase project
- [ ] Add iOS app to Firebase
- [ ] Download GoogleService-Info.plist
- [ ] Add GoogleService-Info.plist to Xcode project
- [ ] Install Firebase SDK via Swift Package Manager
- [ ] Enable Authentication methods in Firebase Console
- [ ] Replace AuthenticationManager.swift with AuthenticationManagerFirebase.swift
- [ ] Replace SignUpView.swift with SignUpViewFirebase.swift
- [ ] Initialize Firebase in Flower_AppApp.swift
- [ ] Test authentication

## Detailed Steps

### 1. Create Firebase Project

1. Visit https://console.firebase.google.com/
2. Click "Add Project" or "Create a project"
3. Enter project name: "Flower App" (or your preferred name)
4. Click "Continue"
5. (Optional) Enable Google Analytics - you can skip this
6. Click "Create Project"
7. Wait for project creation, then click "Continue"

### 2. Add iOS App

1. In Firebase Console, click the iOS icon (or "Add app" → iOS)
2. iOS bundle ID: `abep.Flower-App`
   - To find your bundle ID: Xcode → Project → General → Bundle Identifier
3. App nickname: "Flower App iOS" (optional)
4. App Store ID: Leave blank for now
5. Click "Register app"

### 3. Download Configuration File

1. Click "Download GoogleService-Info.plist"
2. **Important**: Don't close this page yet - you'll need it later

### 4. Add Configuration File to Xcode

1. Open your Xcode project
2. In Project Navigator, right-click on "Flower App" folder
3. Select "Add Files to 'Flower App'..."
4. Select the downloaded `GoogleService-Info.plist`
5. **Important**: Check "Copy items if needed"
6. **Important**: Make sure "Flower App" target is checked
7. Click "Add"

### 5. Install Firebase SDK

1. In Xcode: File → Add Packages...
2. In the search bar, enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select "Up to Next Major Version" with version `11.0.0` or later
4. Click "Add Package"
5. Select these products:
   - ✅ FirebaseAuth
   - ✅ FirebaseCore
6. Click "Add Package"
7. Wait for package resolution

### 6. Enable Authentication Methods

1. In Firebase Console, go to: Authentication → Sign-in method
2. Click on each method and enable:

   **Email/Password:**
   - Click "Email/Password"
   - Toggle "Enable" to ON
   - Click "Save"

   **Phone:**
   - Click "Phone"
   - Toggle "Enable" to ON
   - Click "Save"
   - Note: For production, you'll need Firebase Blaze plan

   **Apple:**
   - Click "Apple"
   - Toggle "Enable" to ON
   - You'll need to configure OAuth (see Apple Developer setup below)
   - Click "Save"

### 7. Update Your Code

1. **Initialize Firebase in App:**
   - Open `Flower_AppApp.swift`
   - Add `import FirebaseCore` at the top
   - In the `init()` or `body`, add:
     ```swift
     FirebaseApp.configure()
     ```

2. **Replace Authentication Files:**
   - Rename `AuthenticationManager.swift` to `AuthenticationManager.swift.backup`
   - Rename `AuthenticationManagerFirebase.swift` to `AuthenticationManager.swift`
   - Rename `SignUpView.swift` to `SignUpView.swift.backup`
   - Rename `SignUpViewFirebase.swift` to `SignUpView.swift`

### 8. Apple Sign In Setup (Optional but Recommended)

1. Go to Apple Developer Portal: https://developer.apple.com
2. Certificates, Identifiers & Profiles → Identifiers
3. Select your App ID
4. Enable "Sign In with Apple" capability
5. In Firebase Console → Authentication → Sign-in method → Apple:
   - Enter your OAuth client ID and secret
   - Follow Firebase's instructions

### 9. Test Your Implementation

1. Build and run your app
2. Test Email sign-up with a real email
3. Test Phone sign-up (requires real phone number)
4. Test Apple Sign In (requires real device, not simulator)

## Troubleshooting

### "GoogleService-Info.plist not found"
- Make sure the file is in your Xcode project
- Check that it's added to the correct target
- Try cleaning build folder: Product → Clean Build Folder

### "Firebase module not found"
- Make sure you added FirebaseAuth and FirebaseCore packages
- Try restarting Xcode
- Check Package Dependencies in Project Settings

### Phone verification not working
- Free tier has limited SMS - use your own phone number for testing
- For production, upgrade to Blaze plan

### Apple Sign In not working
- Must test on real device (simulator doesn't support it)
- Check Apple Developer account setup
- Verify OAuth configuration in Firebase

## Production Checklist

- [ ] Upgrade to Firebase Blaze plan (for phone auth)
- [ ] Configure Apple Sign In OAuth
- [ ] Set up error monitoring
- [ ] Test all authentication flows
- [ ] Set up rate limiting
- [ ] Configure security rules
- [ ] Test on multiple devices

## Cost Estimate

- **Free Tier (Spark Plan):**
  - Email/Password: Unlimited
  - Phone Auth: Limited (test numbers only)
  - Apple Sign In: Free
  
- **Blaze Plan (Pay-as-you-go):**
  - Phone SMS: ~$0.01-0.05 per verification
  - First $0.01/day is free
  - Very affordable for most apps

## Next Steps After Setup

1. Test all three authentication methods
2. Handle edge cases (network errors, etc.)
3. Add user profile management
4. Implement password reset functionality
5. Add email verification (optional)

