//
//  OTPViewController.swift
//  OauthDemo
//
//  Created by Dharasis Behera on 08/06/21.
//

import UIKit

class OTPViewController: UIViewController {

    @IBOutlet var otpTextFied: UITextField!
    @IBOutlet var otpViewMessage: UILabel!
    
    var appDelegate: AppDelegate? =  UIApplication.shared.delegate as? AppDelegate
   
    var multtifactorAuth: MultiFactorAuth?
    var mfa_token: String?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
                multtifactorAuth?.challengeUserWithOtp(mfaToken: mfa_token ?? "", handler: { (success) in
                    if !success{
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "unwindToMainVC", sender: self)
                        }
                    }
                })

        // Do any additional setup after loading the view.
    }
}

extension OTPViewController{
    @IBAction func onClickOtpButton(sender: UIButton){
        let otp = otpTextFied.text
//        multtifactorAuth?.challengeUserWithOtp(mfaToken: mfa_token ?? "", handler: { (success) in
//            if success{
                self.multtifactorAuth?.checkChallenge(mfaToken: self.mfa_token ?? "" , otp: otp ?? "", handler: { (success) in
                    guard let _ = success else{return}
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "unwindToMainVC", sender: self)
                    }
                })
//            }else{
//                DispatchQueue.main.async {
//                    self.performSegue(withIdentifier: "unwindToMainVC", sender: self)
//                }
//            }
//        })
    }
}
