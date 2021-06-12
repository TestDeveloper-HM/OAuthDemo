//
//  AuthServerModel.swift
//  OauthDemo
//
//  Created by Dharasis Behera on 02/06/21.
//

import Foundation
struct Tokens: Decodable {
  
    private enum CodingKeys : String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenExpireTime = "expires_in"
       }
    var accessToken: String
    var refreshToken: String?
    var tokenExpireTime: Int
    
    
//    init(from decoder: Decoder) throws {
//          let values = try decoder.container(keyedBy: CodingKeys.self)
//        refreshToken = try values.decodeIfPresent(String.self, forKey: .refreshToken) ?? ""
//        accessToken = try values.decode(String.self, forKey: .accessToken)
//        tokenExpireTime = try values.decode(Int.self, forKey: .tokenExpireTime)
//      }

}



struct Profile: Decodable {
    struct User_Meta: Decodable {
        var photo: String
        var photoUrl: String
    }
    private enum CodingKeys : String, CodingKey {
        case user_meta = "https://dev-k3bib8fg.us.auth0.comuser_metadata"
        case name = "name"
        case email = "email"
        case picture = "picture"
        case sub = "sub"

       }
    var name: String?
    var email: String?
    var picture: String?
    var sub: String?
    var user_meta: User_Meta?
}

