//
//  Utility.swift
//  OauthDemo
//
//  Created by Dharasis Behera on 02/06/21.
//

import Foundation
import UIKit

/**
 Fetch image from URL
 */
func downloadImage(from url: URL,  completion: @escaping (UIImage)->()) {
    getData(from: url) { data, response, error in
        guard let data = data, error == nil else { return }
        completion(UIImage(data: data) ?? UIImage())
    }
}
func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
    URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
}

/**
 Generate Code Verifier for PKCE
 */
func generateRandomBytes() -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<100).map{ _ in letters.randomElement()! })
}

    /**
    Base 64 Encoding
    */
 func base64UrlEncode(_ data: Data) -> String {
    var b64 = data.base64EncodedString()
    b64 = b64.replacingOccurrences(of: "=", with: "")
    b64 = b64.replacingOccurrences(of: "+", with: "-")
    b64 = b64.replacingOccurrences(of: "/", with: "_")
    return b64
}

/**
 Sha 256
 */
func sha256(string: String) -> Data {
    let data = string.data(using:String.Encoding.utf8)!
    var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
    }
    return Data(hash)
}


extension Date {
    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
}

/**
 Save Tokens to PersistentStore
 */
func saveToPersistentStore(date: Date, accessToken: String, refreshToken:String = UserDefaults.standard.string(forKey: PersistentConstant.refreshToken) ?? ""){
    
    print("saved data to persistent store: Date: \(date.description), Access Token: \(accessToken), RefreshToken: \(refreshToken)")
    
    // User Default
    UserDefaults.standard.set(date, forKey: PersistentConstant.tokenExpireTime)
    UserDefaults.standard.set(accessToken, forKey: PersistentConstant.accessToken)
    UserDefaults.standard.set(refreshToken, forKey:  PersistentConstant.refreshToken)
}

/**
 Clear PersistentStore
 */
func clearPersistentStore(){
    
    UserDefaults.standard.removeObject(forKey: PersistentConstant.tokenExpireTime)
    UserDefaults.standard.removeObject(forKey: PersistentConstant.accessToken)
    UserDefaults.standard.removeObject(forKey: PersistentConstant.refreshToken)
}
/**
 Increase the time by seconds
 */
func increaseTime(by second: Int) -> Date{
    return Calendar.current.date(byAdding: .second, value: second , to: Date())!
}
