//
//  CredentialVC.swift
//  OauthDemo
//
//  Created by Dharasis Behera on 11/06/21.
//

import UIKit

class CredentialVC: UIViewController {
    
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtpassword: UITextField!

    
    var multiFactorAuth: MultiFactorAuth?
    var mfaToken: String?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    func enrollUser(){
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "enrollmentVCSegue", sender: self)
        }
    }
    
    func challengeUser(){
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "otpVCSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
       if segue.identifier == "otpVCSegue"{
            let destinationVC: OTPViewController = segue.destination as! OTPViewController
            destinationVC.multtifactorAuth = multiFactorAuth
            destinationVC.mfa_token = mfaToken
        } else if segue.identifier == "enrollmentVCSegue"{
            let destinationVC: UserEnrollementVC = segue.destination as! UserEnrollementVC
            destinationVC.multifactorAuth = multiFactorAuth
            destinationVC.mfa_token = mfaToken
        } else{
            let destinationVC: DetailViewController = segue.destination as! DetailViewController
            print(appDelegate.authServer.token ?? "")
            destinationVC.token = appDelegate.authServer.token
        }
        
        
      
    }
}

extension CredentialVC{
    @IBAction func onClickLoginWithMFA(){
        let refreshToken = UserDefaults.standard.string(forKey: PersistentConstant.refreshToken)
        //MARK: Check is app has access token & Token expiring date
        if let date = UserDefaults.standard.object(forKey: PersistentConstant.tokenExpireTime) as? Date, let _ = UserDefaults.standard.object(forKey: PersistentConstant.accessToken){
            //MARK: If Access token has expired
            if date < Date(){
                //MARK: Fetching access token using refresh token
                appDelegate.authServer.getAccessTokenFromRefreshToken(refreshToken: refreshToken!) { (successToken) in
                    if successToken {
                        print("Fetched Access token from Refresh token")
                        self.fetchDetail()
                    }
                }
            }else{
                //MARK: Fetch details with saved access token
                print("Fetched details with saved access token")
                appDelegate.authServer.createTokenFromPersistantStore()
                self.fetchDetail()
            }
        }else{
            //MARK: Normal OAuth flow is no detail found in Persistent store i.e. for the first time login
            print("Started MFA flow for the first time")
            startMFA()
            
        }
    }
    
    
    func fetchDetail(){
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "DetailVCSegue", sender: self)
        }
    }
    
    func startMFA(){
        multiFactorAuth?.proceedWithResourceOWnerGrantFlow(email: txtEmail.text ?? "", password: txtpassword.text ?? ""){ (mfaToken) in
            
            guard let mfaToken = mfaToken else{return}
            
            self.mfaToken = mfaToken
            
            self.multiFactorAuth?.retrieveEnrolledAuthenticator(mfaToken: mfaToken) { (status: EnrolledStatus) in
                switch status{
                
                // Challenge User by sending OTP
                //Popup OTP View COntroller at the same time
                case .enrolled:
                    print("Challenging process starts!")
//                    self.multiFactorAuth?.challengeUserWithOtp(mfaToken: mfaToken) { (response) in
//                        if response {
                            self.challengeUser()
//                        }
//                    }
                // Enroll Authenticator
                case .not_enrolled, .not_verified:
                    self.enrollUser()
                case .error:
                    return
                }
            }
        }

    }
    
    @IBAction func unwindFromOTPVC( _ seg: UIStoryboardSegue) {
        
        self.fetchDetail()
    }
    
    @IBAction func unwindFromEnrollementVC( _ seg: UIStoryboardSegue) {
        self.fetchDetail()
    }
    
    
}
        

