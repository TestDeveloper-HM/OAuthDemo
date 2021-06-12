//
//  UserEnrollementVC.swift
//  OauthDemo
//
//  Created by Dharasis Behera on 08/06/21.
//

import UIKit

class UserEnrollementVC: UIViewController {

    @IBOutlet var otpTextFied: UITextField!
    @IBOutlet var numberTextField: UITextField!
    @IBOutlet var sendOTPButton: UIButton!
    @IBOutlet var verifyOTPButton: UIButton!

    var multifactorAuth: MultiFactorAuth?
    var mfa_token: String?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

}

extension UserEnrollementVC{
    @IBAction func onClickVerifyButton(sender: UIButton){
        multifactorAuth?.checkEnrollmentWithTokenEndpoint(mfaToken: mfa_token ?? "", otp: otpTextFied.text ?? "", handler: { (success) in
            guard let _ = success else{return}
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "unwindToMainVC", sender: self)
            }
        })
    }
    
    @IBAction func onClickSendOTPButton(sender: UIButton){
        multifactorAuth?.enrollAuthenticator(mfaToken: mfa_token ?? "", number: "+91-\(numberTextField.text ?? "")" , completionHandler: { (success) in
            DispatchQueue.main.async {
                self.numberTextField.isEnabled = false
                self.numberTextField.alpha = 0.7
                self.sendOTPButton.isEnabled = false
                self.sendOTPButton.alpha = 0.7

            }
        })
    }
}
