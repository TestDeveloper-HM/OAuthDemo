//
//  ViewController.swift
//  OauthDemo
//
//  Created by Dharasis Behera on 31/05/21.
//

import UIKit
import AuthenticationServices

class ViewController: UIViewController , ASWebAuthenticationPresentationContextProviding {
    @IBOutlet var btnLogin: UIButton!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let sceneDelegate = UIApplication.shared.connectedScenes
            .first!.delegate as! SceneDelegate
        
        return sceneDelegate.window ?? ASPresentationAnchor()
      }

}

extension ViewController{
    @IBAction func onClickLogin(sender: UIButton){
        
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
            print("Started OAuth flow for the first time")
            startOauthFlow()
        }
    }
    
    func startOauthFlow(){
        appDelegate.authServer.getAuthorizationCode(viewController: self){(sucess) in
            print("Authorization grant Fetched!")
            self.appDelegate.authServer.getAccessToken() { (successToken) in
                print("Access Token Fetched!")
                if successToken {
                    self.fetchDetail()
                }
            }
        }

    }
    
    func fetchDetail(){
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "DetailVCSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC: DetailViewController = segue.destination as! DetailViewController
        destinationVC.token = appDelegate.authServer.token
    }
    
    @IBAction func unwindToThisViewController(segue: UIStoryboardSegue) {
        appDelegate.authServer.logOutUser(viewController:self)
        
    }
}
