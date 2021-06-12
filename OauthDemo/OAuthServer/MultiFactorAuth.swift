//
//  MultiFactorAuth.swift
//  OauthDemo
//
//  Created by Dharasis Behera on 07/06/21.
//

import Foundation

enum EnrolledStatus {
    case enrolled
    case not_enrolled
    case not_verified
    case error

}

class MultiFactorAuth{

    var authServer: OAuthServer!
    var oobCode: String?
    var authenticatorId: String?

    /**
     Entroll Authenticator
     */
 
    func enrollAuthenticator(mfaToken: String, number: String, completionHandler:@escaping (Bool)->Void){
        let headers = ["authorization": "Bearer \(mfaToken)",
                       "content-type": "application/json"]
        
        let parameters = [
            "authenticator_types": ["oob"],
            "oob_channels": ["sms"],
            "phone_number": number
        ] as [String : Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let request = NSMutableURLRequest(url: NSURL(string: "\(Credential.domain)/mfa/associate")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData! as Data
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler:  { (data, response, error) -> Void in
            if (error != nil) {
                completionHandler(false)
            } else {
                
                guard let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
                else{return}
                print(json)
                self.oobCode = json["oob_code"] as? String
                completionHandler(true)
            }
        })
        
        dataTask.resume()
    }
    
    /**
     Confirm SMS enrollment
     */
    
    func checkEnrollmentWithTokenEndpoint(mfaToken: String, otp: String, handler:@escaping (Bool?)->Void){
        let headers = [
          "authorization": "Bearer \(mfaToken)",
          "content-type": "application/x-www-form-urlencoded"
        ]
        
        

        let postData = NSMutableData(data: "grant_type=http://auth0.com/oauth/grant-type/mfa-oob".data(using: String.Encoding.utf8)!)
        postData.append("&client_id=\(Credential.clientId)".data(using: String.Encoding.utf8)!)
        postData.append("&mfa_token=\(mfaToken)".data(using: String.Encoding.utf8)!)
        postData.append("&oob_code=\(self.oobCode ?? "")".data(using: String.Encoding.utf8)!)
        postData.append("&binding_code=\(otp)".data(using: String.Encoding.utf8)!)
        let request = NSMutableURLRequest(url: NSURL(string: "\(Credential.domain)/oauth/token")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
          if (error != nil) {
            print(error)
            handler(nil)
          } else {
                guard let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
                        else{return}
            print(json)
            
            
            let decoder = JSONDecoder()
            let token = try? decoder.decode(Tokens.self, from: data ?? Data())
            
        
            self.authServer?.token = token
            
            
            saveToPersistentStore(date: increaseTime(by:json["expires_in"] as? Int ?? 0), accessToken: json["access_token"] as? String ?? "", refreshToken: json["refresh_token"] as? String ?? "")
            
            handler(true)
          }
        })
        dataTask.resume()
    }
    
    
    /**
     Retrieve enrolled authenticators
     */
    
    func retrieveEnrolledAuthenticator(mfaToken: String, handler: @escaping (EnrolledStatus)->Void){
        let headers = [
          "authorization": "Bearer \(mfaToken)",
          "content-type": "application/json"
        ]

        let request = NSMutableURLRequest(url: NSURL(string: "\(Credential.domain)/mfa/authenticators")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
          if (error != nil) {
            handler(.error)
          } else {
            guard let json = try? JSONSerialization.jsonObject(with: data!) as? [[String: Any]]
                    else{return}
            print(json)
            if json.count != 0{
                let factor = json[json.count-1] as [String:Any]
                guard let active: Bool  = factor["active"] as? Bool else {
                    return
                }
                if active{
                    self.authenticatorId = factor["id"] as? String
                    handler(.enrolled)
                }else{
                    handler(.not_verified)
                }
            }else{
                handler(.not_enrolled)
            }
          }
        })

        dataTask.resume()
    }
    
    /**
     Challenge user with OTP
     */
    func challengeUserWithOtp(mfaToken: String, handler: @escaping (Bool)->()){
        print("MFA Access token: \(mfaToken) && authenticatorId: \(authenticatorId ?? "")")

        let headers = [
            "authorization": "Bearer \(mfaToken)",
            "content-type": "application/json"
        ]
        
        let parameters = [
          "client_id": Credential.clientId,
          "challenge_type": "oob",
          "authenticator_id": authenticatorId ?? "",
          "mfa_token": mfaToken
        ] as [String : Any]

        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let request = NSMutableURLRequest(url: NSURL(string: "\(Credential.domain)/mfa/challenge")! as URL,cachePolicy: .useProtocolCachePolicy,timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
          if (error != nil) {
            handler(false)
          } else {
            guard let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
                    else{return}
            self.oobCode = json["oob_code"] as? String
            print(json)
            handler(true)
          }
        })

        dataTask.resume()
    }
    
    
//    Demo response:
//    {
//      "challenge_type": "oob",
//      "oob_code": "asdae35fdt5...",
//      "binding_method": "prompt"
//    }
//
//
    /**
     Check for challenge
     */
    
    func checkChallenge(mfaToken: String, otp: String, handler:@escaping (Bool?)->Void){
        let headers = ["content-type": "application/x-www-form-urlencoded"]

        let postData = NSMutableData(data: "grant_type=http://auth0.com/oauth/grant-type/mfa-oob".data(using: String.Encoding.utf8)!)
        postData.append("&client_id=\(Credential.clientId)".data(using: String.Encoding.utf8)!)
        postData.append("&mfa_token=\(mfaToken)".data(using: String.Encoding.utf8)!)
        postData.append("&oob_code=\(self.oobCode ?? "")".data(using: String.Encoding.utf8)!)
        postData.append("&binding_code=\(otp)".data(using: String.Encoding.utf8)!)

        let request = NSMutableURLRequest(url: NSURL(string: "\(Credential.domain)/oauth/token")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
          if (error != nil) {
            print(error)
            handler(nil)
          } else {
            guard let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
                    else{return}
            print(json)
            
            let decoder = JSONDecoder()
            let token = try? decoder.decode(Tokens.self, from: data ?? Data())
            
        
            self.authServer?.token = token
            
            saveToPersistentStore(date: increaseTime(by:json["expires_in"] as? Int ?? 0), accessToken: json["access_token"] as? String ?? "", refreshToken: json["refresh_token"] as? String ?? "")

            
            
            handler(true)
          }
        })

        dataTask.resume()
    }
    
    
    func proceedWithResourceOWnerGrantFlow(email: String, password: String, handler: @escaping (String?)->Void){

        let headers = ["content-type": "application/x-www-form-urlencoded"]
        let postData = NSMutableData(data: "grant_type=password".data(using: String.Encoding.utf8)!)
        postData.append("&username=\(email)".data(using: String.Encoding.utf8)!)
        postData.append("&password=\(password)".data(using: String.Encoding.utf8)!)
        postData.append("&client_id=\(Credential.clientId)".data(using: String.Encoding.utf8)!)
        postData.append("&scope=openid profile email offline_access enroll read:authenticators remove:authenticators".data(using: String.Encoding.utf8)!)
        postData.append("&audience=\(Credential.domain)/mfa/".data(using: String.Encoding.utf8)!)

        

        let request = NSMutableURLRequest(url: NSURL(string: "\(Credential.domain)/oauth/token")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
          if (error != nil) {
            print(error)
            handler(nil)
          } else {
            guard let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
                    else{return}
            print(json)
            
            let mfa_Token = json["mfa_token"] as? String
             
            if let mfaToken = mfa_Token{
                handler(mfaToken)
            }else{
                handler(json["mfa_token"] as? String)
            }
        
                        
          }
        })

        dataTask.resume()

    }
}
