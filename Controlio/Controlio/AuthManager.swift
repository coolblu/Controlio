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

    // Email / Password sign up through firebase
    func signUp(email: String, password: String, name: String? = nil, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else { return }

            // Reload to ensure currentUser is fully updated
            user.reload { reloadError in
                if let reloadError = reloadError {
                    print("Reload error:", reloadError.localizedDescription)
                }

                if let name = name, !name.isEmpty {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = name
                    changeRequest.commitChanges { commitError in
                        if let commitError = commitError {
                            print("Failed to set display name:", commitError.localizedDescription)
                        }

                        // Fetch user info after displayName is committed
                        UserManager.shared.fetchUser()
                    }
                } else {
                    UserManager.shared.fetchUser()
                }
            }

            if let result = result {
                completion(.success(result))
            }
        }
    }
    
    // Simple email and password login through firebase
    func login(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let result = result {
                // Update UserManager immediately
                UserManager.shared.fetchUser()
                completion(.success(result))
            }
        }
    }

    // Google Sign-In
    func googleSignIn(presenting: UIViewController, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
            if let error = error {
                completion(.failure(error)); return
            }

            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Google user"])))
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                } else if let authResult = authResult {
                    UserManager.shared.fetchUser()
                    completion(.success(authResult))
                }
            }
        }
    }
    
    // Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            UserManager.shared.fetchUser() // reset user info
        } catch {
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }
}
