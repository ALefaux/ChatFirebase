//
//  LogInViewController.swift
//  ChatFirebase
//
//  Created by Axel Lefaux on 17/02/2018.
//  Copyright © 2018 Axel Lefaux. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class LogInViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {

    @IBOutlet weak var anonymousButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        anonymousButton.layer.borderWidth = 2.0
        anonymousButton.layer.borderColor = UIColor.white.cgColor
        
        GIDSignIn.sharedInstance().clientID = "527420977673-4h466eq1pdchasvdhbeds4uiflgt13gc.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(Auth.auth().currentUser)
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                print(user)
                Helper.helper.switchToNavigationViewController()
            } else {
                print("Unauthorized")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logInAnonymouslyDidTapped(_ sender: Any) {
        print("Login anonymously did tapped")
        // Anonymously log users in
        // Switch view by setting navigation controller as root view controller
        
        Helper.helper.logInAnonymously()
    }
    
    @IBAction func googleLogInDidTapped(_ sender: Any) {
        print("Google login did tapped")
        // Anonymously log users in
        // Switch view by setting navigation controller as root view controller
        
        GIDSignIn.sharedInstance().signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            print(error!.localizedDescription)
            
            return
        }
        
        print(user.authentication)
        Helper.helper.logInWithGoogle(authentification: user.authentication)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
