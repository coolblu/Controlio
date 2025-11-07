//
//  UserManager.swift
//  Controlio
//
//  Created by Jerry Lin on 11/7/25.
//

import SwiftUI
import FirebaseAuth

final class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var displayName: String = "User"
    @Published var email: String = ""
    
    private init() {
        fetchUser()
    }

    func fetchUser() {
        DispatchQueue.main.async {
            if let user = Auth.auth().currentUser {
                self.email = user.email ?? ""
                if let name = user.displayName, !name.isEmpty {
                    self.displayName = name
                } else if let email = user.email, let atIndex = email.firstIndex(of: "@") {
                    self.displayName = String(email[..<atIndex])
                } else {
                    self.displayName = "User"
                }
            } else {
                // No user logged in
                self.displayName = "User"
                self.email = ""
            }
        }
    }

    func updateDisplayName(to newName: String, completion: ((Error?) -> Void)? = nil) {
        guard let user = Auth.auth().currentUser else { return }
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        changeRequest.commitChanges { error in
            DispatchQueue.main.async {
                if error == nil {
                    self.displayName = newName
                }
                completion?(error)
            }
        }
    }
}
