//
//  AuthManager.swift
//  Controlio
//
//  Created by Jerry Lin on 10/22/25.
//

import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit
import WebKit
import AuthenticationServices

/// Provides functionality to authentication actions
class AuthManager {
    static let shared = AuthManager()
    private init() {}

    // Email / Password sign up
    func signUp(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error { completion(.failure(error)) }
            else if let result = result { completion(.success(result)) }
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error { completion(.failure(error)) }
            else if let result = result { completion(.success(result)) }
        }
    }

    // Google Sign-In
    func googleSignIn(presenting: UIViewController, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
            if let error = error { completion(.failure(error)); return }

            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Google user"])))
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error { completion(.failure(error)) }
                else if let authResult = authResult { completion(.success(authResult)) }
            }
        }
    }
    
    // Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
