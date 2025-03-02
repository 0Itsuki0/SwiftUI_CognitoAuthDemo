//
//  CognitoConfig.swift
//  CognitoDemo
//
//  Created by Itsuki on 2025/02/26.
//

import AWSCognitoIdentityProvider
import AWSCore

final class CognitoConstants {
    static let region: AWSRegionType = .APNortheast1
    static let userPoolId: String = "<user_pool_id>"
    static let clientID: String = "<client_id>"
    static let clientSecret: String? = nil
    
    // Use to retrieve the user pool instance configured. can be anything.
    static let userPoolKey: String = "UserPoolKey"
    
    private init() {}
}

