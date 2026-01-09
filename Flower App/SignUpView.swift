//
//  SignUpView.swift
//  Flower App
//
//  Created for user sign-up and authentication
//

import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @ObservedObject var authManager = AuthenticationManager.shared
    @State private var selectedMethod: AuthMethod? = nil
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var showVerificationCode = false
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    
    var onSignInComplete: () -> Void
    
    private var primaryTextColor: Color {
        Color.primary
    }
    
    private var transparentBoxBackground: some View {
        ZStack {
            Color.white.opacity(0.9)
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // App Logo/Title
                    VStack(spacing: 16) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Heartgarden")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("Grow your relationship, one question at a time")
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 60)
                    
                    // Authentication Options
                    if selectedMethod == nil {
                        VStack(spacing: 16) {
                            // Apple Sign In
                            SignInWithAppleButton(
                                onRequest: { request in
                                    request.requestedScopes = [.fullName, .email]
                                },
                                onCompletion: { result in
                                    handleAppleSignIn(result: result)
                                }
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(10)
                            
                            // Email Sign Up
                            Button(action: {
                                selectedMethod = .email
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 18))
                                    Text("Continue with Email")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            
                            // Phone Sign Up
                            Button(action: {
                                selectedMethod = .phone
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 18))
                                    Text("Continue with Phone")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    // Email Form
                    if selectedMethod == .email {
                        emailSignUpForm
                    }
                    
                    // Phone Form
                    if selectedMethod == .phone {
                        phoneSignUpForm
                    }
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // Email Sign Up Form
    private var emailSignUpForm: some View {
        VStack(spacing: 20) {
            // Back button
            HStack {
                Button(action: {
                    selectedMethod = nil
                    errorMessage = nil
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(primaryTextColor)
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            
            VStack(spacing: 16) {
                Text("Sign Up with Email")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                
                // Email field
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 32)
                
                // Password field
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 32)
                
                // Confirm Password field
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 32)
                
                // Sign Up button
                Button(action: {
                    signUpWithEmail()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(email.isEmpty || password.isEmpty || confirmPassword.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(10)
                .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty || isLoading)
                .padding(.horizontal, 32)
            }
            .padding()
            .background(transparentBoxBackground)
            .cornerRadius(16)
            .padding(.horizontal, 32)
        }
    }
    
    // Phone Sign Up Form
    private var phoneSignUpForm: some View {
        VStack(spacing: 20) {
            // Back button
            HStack {
                Button(action: {
                    selectedMethod = nil
                    showVerificationCode = false
                    errorMessage = nil
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(primaryTextColor)
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            
            VStack(spacing: 16) {
                Text(showVerificationCode ? "Verify Phone Number" : "Sign Up with Phone")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                
                if !showVerificationCode {
                    // Phone number field
                    TextField("Phone Number", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                        .padding(.horizontal, 32)
                    
                    // Send Code button
                    Button(action: {
                        sendVerificationCode()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Verification Code")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(phoneNumber.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(10)
                    .disabled(phoneNumber.isEmpty || isLoading)
                    .padding(.horizontal, 32)
                } else {
                    // Verification code field
                    TextField("Verification Code", text: $verificationCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 32)
                    
                    // Verify button
                    Button(action: {
                        verifyPhoneNumber()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Verify")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(verificationCode.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(10)
                    .disabled(verificationCode.isEmpty || isLoading)
                    .padding(.horizontal, 32)
                }
            }
            .padding()
            .background(transparentBoxBackground)
            .cornerRadius(16)
            .padding(.horizontal, 32)
        }
    }
    
    // Handle Apple Sign In
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userId = appleIDCredential.user
                let email = appleIDCredential.email
                var displayName: String? = nil
                
                if let fullName = appleIDCredential.fullName {
                    displayName = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                }
                
                authManager.signInWithApple(
                    userId: userId,
                    email: email,
                    displayName: displayName
                )
                
                if authManager.isAuthenticated {
                    onSignInComplete()
                }
            }
        case .failure(let error):
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
        }
    }
    
    // Sign up with email
    private func signUpWithEmail() {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = authManager.signInWithEmail(email: email, password: password)
            isLoading = false
            
            if success {
                onSignInComplete()
            } else {
                errorMessage = "Failed to sign up. Please try again."
            }
        }
    }
    
    // Send verification code
    private func sendVerificationCode() {
        guard !phoneNumber.isEmpty else {
            errorMessage = "Please enter a phone number"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = authManager.sendVerificationCode(to: phoneNumber)
            isLoading = false
            
            if success {
                showVerificationCode = true
                errorMessage = nil
            } else {
                errorMessage = "Invalid phone number. Please try again."
            }
        }
    }
    
    // Verify phone number
    private func verifyPhoneNumber() {
        guard !verificationCode.isEmpty else {
            errorMessage = "Please enter the verification code"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = authManager.signInWithPhone(phoneNumber: phoneNumber, verificationCode: verificationCode)
            isLoading = false
            
            if success {
                onSignInComplete()
            } else {
                errorMessage = "Invalid verification code. Please try again."
            }
        }
    }
}

