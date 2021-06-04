//
//  OAuthServer.swift
//  OauthDemo
//
//  Created by Dharasis Behera on 31/05/21.
//

import Foundation
import AuthenticationServices



class OAuthServer{

    private var codeVerifier: String? = nil
    private var authenticationSession: ASWebAuthenticationSession? = nil
    var authorizationCode: String? = nil
    var token: Tokens?

    /**
     Front Channel
     Fetch Authorization Grant
     */
    func getAuthorizationCode(viewController: UIViewController, handler: @escaping (Bool) -> Void){
      
        guard let challenge = generateCodeChallenge() else {
            handler(false)
            return
        }
        
        var urlComp = URLComponents(string: Credential.domain + "/authorize")!
        urlComp.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Credential.clientId),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "state", value: "login"),
            URLQueryItem(name: "scope", value: "openid profile email offline_access"),
            URLQueryItem(name: "redirect_uri", value: "oauthDemo://home"),
        ]
        authenticationSession = ASWebAuthenticationSession(url: urlComp.url!, callbackURLScheme: "oauthDemo", completionHandler: { (url, error) in
                    
            guard error == nil else {
                return handler(false)
            }
            handler(url != nil && self.parseAuthorizeRedirectUrl(url: url!))
            print(url ?? error.debugDescription)
        })
        authenticationSession?.presentationContextProvider = viewController as? ASWebAuthenticationPresentationContextProviding
        authenticationSession?.start()
    }
    
    
    /**
     Front Channel
     Parsing Authorization Grant to get Authorization Code
     */
    func parseAuthorizeRedirectUrl(url: URL) -> Bool {
        guard let urlComp = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        if urlComp.queryItems == nil {
            return false
        }

        for item in urlComp.queryItems! {
            if item.name == "code" {
                authorizationCode = item.value
            }
        }

        return authorizationCode != nil
    }
    
    
    /**
     Back Channel
     Fetching Access Token in exchange of Authorization Code
     */
    func getAccessToken(handler: @escaping (Bool) -> Void) {
        if authorizationCode == nil || codeVerifier == nil {
            handler(false)
            return
        }
        
        let urlComp = URLComponents(string: Credential.domain + "/oauth/token")!
        
        let body = [
            "grant_type": "authorization_code",
            "client_id": Credential.clientId,
            "code": authorizationCode,
            "code_verifier": codeVerifier,
            "redirect_uri": "oauthDemo://home",
            "audience" : "https://dev-k3bib8fg.us.auth0.com/api/v2/"
        ]
        
        var request = URLRequest(url: urlComp.url!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if(error != nil || data == nil) {
                // TODO: handle error
                handler(false)
                return
            }
            
//            guard let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any],
//                  let accessToken = json["access_token"] as? String,
//                  let expireTime = json["expires_in"] as? Int,
//                  let refreshToken = json["refresh_token"] as? String
//
//            else {
//
//                handler(false)
//                return
//            }
            
            
            let decoder = JSONDecoder()
            let token = try? decoder.decode(Tokens.self, from: data ?? Data())
            
        
            self.token = token
           

            saveToPersistentStore(date: increaseTime(by: self.token?.tokenExpireTime ?? 0), accessToken: self.token?.accessToken ?? "" , refreshToken: self.token?.refreshToken ?? "")
            
            handler(true)
        }
        
        task.resume()
    }

    /**
     Log Out Oauth session
     */
    func logOutUser(viewController: UIViewController){
        var urlComp = URLComponents(string: Credential.domain + "/v2/logout")!
        urlComp.queryItems = [
            URLQueryItem(name: "client_id", value: Credential.clientId),
            URLQueryItem(name: "returnTo", value: "oauthDemo://home")
        ]
        
        
        authenticationSession = ASWebAuthenticationSession(url: urlComp.url!, callbackURLScheme: "oauthDemo", completionHandler: { (url, error) in
            
            
            print(url ?? error.debugDescription)
            
            self.codeVerifier = nil
            self.authorizationCode = nil
            self.authenticationSession = nil
            self.token = nil
            clearPersistentStore()
        })
        authenticationSession?.presentationContextProvider = viewController as? ASWebAuthenticationPresentationContextProviding
        authenticationSession?.start()
        
    }
    
    
    /**
     Fetch New Access token Using Refresh Token
     */
    func getAccessTokenFromRefreshToken(refreshToken: String, handler: @escaping (Bool) -> Void){
        
        let urlComp = URLComponents(string: Credential.domain + "/oauth/token")!
        
        let body = [
            "grant_type": "refresh_token",
            "client_id": Credential.clientId,
            "refresh_token": refreshToken,
            "scope" : "openid profile email offline_access"
        ]
        
        var request = URLRequest(url: urlComp.url!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if(error != nil || data == nil) {
                // TODO: handle error
                handler(false)
                return
            }
            
//            guard let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any],
//                  let accessToken = json["access_token"] as? String,
//                  let expireTime = json["expires_in"] as? Int
//            else {
//
//                handler(false)
//                return
//            }
//            self.token = Tokens(accessToken: accessToken,
//                           refreshToken: refreshToken)
//
//            let calendar = Calendar.current
//            let date = calendar.date(byAdding: .second, value: 120, to: Date())
            
            let decoder = JSONDecoder()
            let token = try? decoder.decode(Tokens.self, from: data ?? Data())
            
        
            self.token = token
           

            saveToPersistentStore(date: increaseTime(by: self.token?.tokenExpireTime ?? 0), accessToken: self.token?.accessToken ?? "")
            
           
            handler(true)

        }
            task.resume()


       
    }

    
    /**
     Create Token from Persistant Store
     */
    func createTokenFromPersistantStore(){
        print("Access Token: \(UserDefaults.standard.string(forKey: PersistentConstant.accessToken)!)")
        self.token = Tokens(accessToken: UserDefaults.standard.string(forKey: PersistentConstant.accessToken)!, refreshToken: UserDefaults.standard.string(forKey: PersistentConstant.refreshToken)!, tokenExpireTime: 0)
    }
    
    
    /**
     Generate Code Challenge for PKCE
     */
    private func generateCodeChallenge() -> String? {
        codeVerifier = generateRandomBytes()
        guard codeVerifier != nil else {
            return nil
        }
        return base64UrlEncode(sha256(string: codeVerifier!))
    }
   

    /**
     Fetch Profile Using Open ID Connect
     */
    func    getProfile(accessToken: String, handler: @escaping (Profile?) -> Void) {
        let urlComp = URLComponents(string: Credential.domain + "/userinfo")!
        
        let urlSessionConfig = URLSessionConfiguration.default;
        let authString = "Bearer \(accessToken)"
        urlSessionConfig.httpAdditionalHeaders = ["Authorization" : authString]
        
        let urlSession = URLSession(configuration: urlSessionConfig)
        let task = urlSession.dataTask(with: urlComp.url!) {
            (data, response, error) in
            if(error != nil || data == nil) {
                // TODO: handle error
                handler(nil)
                return
            }
            
     
            let decoder = JSONDecoder()
            let profile = try? decoder.decode(Profile.self, from: data ?? Data())

            let result = profile
            handler(result)
        }
        
        task.resume()
    }
}
