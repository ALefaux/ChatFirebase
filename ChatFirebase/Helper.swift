//
//  Helper.swift
//  ChatFirebase
//
//  Created by Axel Lefaux on 18/02/2018.
//  Copyright © 2018 Axel Lefaux. All rights reserved.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseDatabase

class Helper {
    static let helper = Helper()
    
    func logInAnonymously() {
        print("Login anonymously did tapped")
        // Anonymously log users in
        // Switch view by setting navigation controller as root view controller
        
        Auth.auth().signInAnonymously { (anonymousUser, error) in
            if error == nil {
                print("UserId: \(anonymousUser!.uid)")
                
                let newUser = Database.database().reference().child("users").child(anonymousUser!.uid)
                newUser.setValue(["displayname":"Anonymous","id":"\(anonymousUser!.uid)","profileUrl":""])
                
                self.switchToNavigationViewController()
            } else {
                print(error!.localizedDescription)
                return
            }
        }
    }
    
    func logInWithGoogle(authentification: GIDAuthentication) {
        let credential = GoogleAuthProvider.credential(withIDToken: authentification.idToken, accessToken: authentification.accessToken)
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print(user?.email ?? "User instance is nil")
                print(user?.displayName ?? "User instance is nil")
                
                let newUser = Database.database().reference().child("users").child(user!.uid)
                newUser.setValue(["displayname":"\(user!.displayName!)","id":"\(user!.uid)","profileUrl":"\(user!.photoURL!)"])
                
                self.switchToNavigationViewController()
            }
        }
    }
    
    func switchToNavigationViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let naviVC = storyboard.instantiateViewController(withIdentifier: "NavigationVC")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = naviVC
    }
}
