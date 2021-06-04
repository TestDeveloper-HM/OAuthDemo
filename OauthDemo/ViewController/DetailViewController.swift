//
//  DetailViewController.swift
//  OauthDemo
//
//  Created by Dharasis Behera on 31/05/21.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet var lblName: UILabel!
    @IBOutlet var lblEmail: UILabel!
    @IBOutlet var imgPhoto: UIImageView!
    @IBOutlet var imgUserMeta: UIImageView!
    @IBOutlet var lblUserMetaPhotoName: UILabel!

    var appDelegate: AppDelegate? =  UIApplication.shared.delegate as? AppDelegate
    var token: Tokens?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.appDelegate?.authServer.getProfile(accessToken: self.token?.accessToken ?? "") { [self] (profile) in
            DispatchQueue.main.async {
                print("User profile fetched")
                lblName.text = "Name : \(profile?.name ?? "")"
                lblEmail.text = "Email : \(profile?.email ?? "")"
                lblUserMetaPhotoName.text = " \(profile?.user_meta?.photo ?? "")"
                
                guard let picture = profile?.picture else{return}
                
                DispatchQueue.global().async {
                    downloadImage(from: URL(string: picture)!){(img) in
                        DispatchQueue.main.async {
                            self.imgPhoto.image = img
                        }
                    }
                }
                
                
                guard let user_meta_photo = profile?.user_meta?.photoUrl else{return}
                DispatchQueue.global().async {
                    
                    downloadImage(from: URL(string: user_meta_photo)!){(img) in
                        
                        DispatchQueue.main.async {
                            self.imgUserMeta.image = img
                        }
                    }
                }
                
                
            }
        }
	            
        // Do any additional setup after loading the view.
    }


}


extension DetailViewController{
    @IBAction func logout(){
        self.navigationController?.popViewController(animated: true)
    }
    
    
}
