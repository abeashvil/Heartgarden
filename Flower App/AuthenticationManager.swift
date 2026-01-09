//
//  AuthenticationManager.swift
//  Flower App
//
//  Created for managing user authentication
//

import Foundation
import AuthenticationServices
import Combine

enum AuthMethod: String, Codable {
    case apple = "apple"
    case email = "email"
    case phone = "phone"
}

struct UserAuth: Codable {
    var userId: String
    var authMethod: AuthMethod
    var email: String?
    var phoneNumber: String?
    var displayName: String?
    var isAuthenticated: Bool
    var createdAt: Date
}

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserAuth?
    
    private let authKey = "userAuth"
    
    private init() {
        loadAuthState()
    }
    
    // Load authentication state from UserDefaults
    private func loadAuthState() {
        if let data = UserDefaults.standard.data(forKey: authKey),
           let userAuth = try? JSONDecoder().decode(UserAuth.self, from: data) {
            self.currentUser = userAuth
            self.isAuthenticated = userAuth.isAuthenticated
        } else {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    // Save authentication state to UserDefaults
    private func saveAuthState() {
        if let userAuth = currentUser,
           let data = try? JSONEncoder().encode(userAuth) {
            UserDefaults.standard.set(data, forKey: authKey)
        }
    }
    
    // Sign in with Apple
    func signInWithApple(userId: String, email: String?, displayName: String?) {
        let userAuth = UserAuth(
            userId: userId,
            authMethod: .apple,
            email: email,
            phoneNumber: nil,
            displayName: displayName,
            isAuthenticated: true,
            createdAt: Date()
        )
        self.currentUser = userAuth
        self.isAuthenticated = true
        saveAuthState()
    }
    
    // Sign in with Email
    func signInWithEmail(email: String, password: String) -> Bool {
        // For now, we'll do simple validation
        // In production, this would connect to a backend service
        guard !email.isEmpty, !password.isEmpty else {
            return false
        }
        
        // Simple validation - in production, verify with backend
        let userAuth = UserAuth(
            userId: UUID().uuidString,
            authMethod: .email,
            email: email,
            phoneNumber: nil,
            displayName: nil,
            isAuthenticated: true,
            createdAt: Date()
        )
        self.currentUser = userAuth
        self.isAuthenticated = true
        saveAuthState()
        return true
    }
    
    // Sign in with Phone
    func signInWithPhone(phoneNumber: String, verificationCode: String) -> Bool {
        // For now, we'll do simple validation
        // In production, this would verify SMS code with backend
        guard !phoneNumber.isEmpty, !verificationCode.isEmpty else {
            return false
        }
        
        // Simple validation - in production, verify SMS code with backend
        let userAuth = UserAuth(
            userId: UUID().uuidString,
            authMethod: .phone,
            email: nil,
            phoneNumber: phoneNumber,
            displayName: nil,
            isAuthenticated: true,
            createdAt: Date()
        )
        self.currentUser = userAuth
        self.isAuthenticated = true
        saveAuthState()
        return true
    }
    
    // Send verification code (mock for now)
    func sendVerificationCode(to phoneNumber: String) -> Bool {
        // In production, this would send SMS via backend service
        // For now, we'll just validate the phone number format
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleaned.count >= 10
    }
    
    // Sign out
    func signOut() {
        self.currentUser = nil
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: authKey)
    }
}

