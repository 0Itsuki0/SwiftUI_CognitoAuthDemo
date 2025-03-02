//
//  CognitoManager.swift
//  CognitoDemo
//
//  Created by Itsuki on 2025/02/26.
//

import SwiftUI
import AWSCognitoIdentityProvider
import AWSCognitoIdentityProviderASF
import AWSCore


@MainActor
@Observable
class CognitoManager {
    enum CognitoError: Error {
        case invalidPool
        case userNotFound
        case userNotSignedIn
        case sessionError(NSError?)
        
        var message: String {
            switch self {
            case .invalidPool:
                return "Invalid Cognito User Pool"
            case .userNotFound:
                return "User not found"
            case .userNotSignedIn:
                return "User not signed in"
            case .sessionError(let error):
                if let error {
                    // error messages from AWS are contained in userInfo
                    // Ex: Error Domain=com.amazonaws.AWSCognitoIdentityProviderErrorDomain Code=18 "(null)" UserInfo={__type=InvalidUserPoolConfigurationException, message=Device tracking not currently enabled for this pool.}
                    let type = error.userInfo["__type"] as? String ?? ""
                    let errorMessage = error.userInfo["message"] as? String ?? ""
                    if type.isEmpty && errorMessage.isEmpty {
                        return "Unknown session error"
                    }
                    return type.isEmpty ? errorMessage : "\(type): \(errorMessage)"
                } else {
                    return "Unknown session error"
                }
            }
        }
    }
    
    struct UserTokens {
        var idToken: AWSCognitoIdentityUserSessionToken?
        var accessToken: AWSCognitoIdentityUserSessionToken?
        var refreshToken: AWSCognitoIdentityUserSessionToken?
        
        init(session: AWSCognitoIdentityUserSession) {
            self.idToken = session.idToken
            self.accessToken = session.accessToken
            self.refreshToken = session.refreshToken
        }
    }
    
    var error: CognitoError? = nil {
        didSet {
            if let error {
                print(error.message)
            }
        }
    }
    
    var userSignedIn: Bool = false

    private var pool: AWSCognitoIdentityUserPool? {
        return AWSCognitoIdentityUserPool(forKey: CognitoConstants.userPoolKey)
    }
    
    init () {
        
        let serviceConfiguration: AWSServiceConfiguration = .init(region: CognitoConstants.region, credentialsProvider: nil)
        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: CognitoConstants.clientID, clientSecret: CognitoConstants.clientSecret, poolId: CognitoConstants.userPoolId)
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: CognitoConstants.userPoolKey)

        let userPool = AWSCognitoIdentityUserPool(forKey: CognitoConstants.userPoolKey)
        self.userSignedIn = userPool?.currentUser()?.isSignedIn == true
        
    }
    
    func signUp(username: String, password: String) async -> AWSCognitoIdentityUser? {
        guard let pool else {
            self.error = .invalidPool
            return nil
        }
        // for adding other attributes
//        let emailAttribute: AWSCognitoIdentityUserAttributeType = AWSCognitoIdentityUserAttributeType(name: "email", value: email)
//        let attributes: [AWSCognitoIdentityUserAttributeType] = [emailAttribute]
        
        let attributes: [AWSCognitoIdentityUserAttributeType]? = nil

        let task = pool.signUp(username, password: password, userAttributes: attributes, validationData: nil)
        
        do {
            let result: AWSCognitoIdentityUserPoolSignUpResponse = try await asyncTask(task)
            if result.user.confirmedStatus == .confirmed && result.user.isSignedIn {
                self.userSignedIn = true
            }
            return result.user
            
        } catch(let error) {
            print("error signing up: \(error)")
            if let error = error as? CognitoError {
                self.error = error
            }
            return nil
        }
    }
    
    func confirmSignUp(username: String, confirmationCode: String) async -> Bool {
        guard let pool else {
            self.error = .invalidPool
            return false
        }
        let user: AWSCognitoIdentityUser = pool.getUser(username)
        
        do {
            let _ = try await asyncTask(user.confirmSignUp(confirmationCode))
            // NOTE: pool.currentUser()?.isSignedIn will be false at this point
            return true
        } catch(let error) {
            print("error signing up: \(error)")
            if let error = error as? CognitoError {
                self.error = error
            }
            return false
        }
    }
    

    func signIn(username: String, password: String) async -> UserTokens? {
        guard let pool else {
            self.error = .invalidPool
            return nil
        }
        let user: AWSCognitoIdentityUser = pool.getUser(username)

        let task = user.getSession(username, password: password, validationData: nil)
        if let tokens = await self.processUserSessionTask(task) {
            self.userSignedIn = true
            return tokens
        }
        return nil
    }
    
    
    func sendForgotPasswordCode(username: String) async -> Bool {
        guard let pool else {
            self.error = .invalidPool
            return false
        }
        let user: AWSCognitoIdentityUser = pool.getUser(username)

        do {
            let _ = try await self.asyncTask(user.forgotPassword())
            return true
        } catch(let error) {
            print("error send forgot password code: \(error)")
            if let error = error as? CognitoError {
                self.error = error
            }
            return false
        }
    }
    
    
    func confirmForgotPassword(username: String, confirmationCode: String, newPassword: String) async -> Bool {
        guard let pool else {
            self.error = .invalidPool
            return false
        }
        
        let user: AWSCognitoIdentityUser = pool.getUser(username)

        do {
            let _ = try await self.asyncTask(user.confirmForgotPassword(confirmationCode, password: newPassword))
            return true
        } catch(let error) {
            print("error confirm forgot password: \(error)")
            if let error = error as? CognitoError {
                self.error = error
            }
            return false
        }
    }
    
    
    func changePasswordForCurrentUser(oldPassword: String, newPassword: String) async -> Bool {
        guard let user = getSignedInUser() else {
            return false
        }
        do {
            let _ = try await self.asyncTask(user.changePassword(oldPassword, proposedPassword: newPassword))
            return true
        } catch(let error) {
            print("error changing password: \(error)")
            if let error = error as? CognitoError {
                self.error = error
            }
            return false
        }
    }
    
    func signOut() {
        // equivalent to
        // pool?.currentUser()?.signOut() + pool?.clearLastKnownUser()
        pool?.currentUser()?.signOutAndClearLastKnownUser()
        self.userSignedIn = false
    }
}



// MARK: - get signed in user info

extension CognitoManager {
    
    func getTokens() async -> UserTokens? {
        guard let user = getSignedInUser() else {
            return nil
        }
        if let tokens = await self.processUserSessionTask(user.getSession()) {
            return tokens
        }
        return nil
    }
    
    // unique user ID if only email or phone number is set as sign in option; Otherwise, user-selected username
    func getCurrentUsername() -> String? {
        guard let user = getSignedInUser() else {
            return nil
        }
        return user.username
    }
    
    
    func getCurrentUserDetail() async -> AWSCognitoIdentityUserGetDetailsResponse? {
        guard let user = getSignedInUser() else {
            return nil
        }
        do {
            let result = try await self.asyncTask(user.getDetails())
            return result
        } catch(let error) {
            print("error getting user details: \(error)")
            if let error = error as? CognitoError {
                self.error = error
            }
            return nil

        }
    }
    
    
    // available only if Device tracking is enabled for the user pool
    func getCurrentDeviceId() -> String? {
        guard let user = getSignedInUser() else {
            return nil
        }
        return user.deviceIdentifier
    }
    
    // available only if Device tracking is enabled for the user pool
    func listDevices(limit: Int = 10, paginationToken: String? = nil) async -> ([AWSCognitoIdentityProviderDeviceType]?, String?) {
        
        guard let user = getSignedInUser() else {
            return (nil, nil)
        }
        do {
            let result: AWSCognitoIdentityUserListDevicesResponse = try await asyncTask(user.listDevices(10, paginationToken: nil))
            let devices = result.devices
            let paginationToken = result.paginationToken
            return (devices, paginationToken)

        } catch(let error) {
            print("error listing devices: \(error)")
            if let error = error as? CognitoError {
                self.error = error
            }
            return (nil, nil)
        }
    }
}



// MARK: - private helper functions

extension CognitoManager {
    
    private func getSignedInUser() -> AWSCognitoIdentityUser? {
        guard let pool else {
            self.error = .invalidPool
            return nil
        }
        guard let currentUser = pool.currentUser() else {
            self.error = .userNotFound
            return nil
        }
        guard currentUser.isSignedIn else {
            self.error = .userNotSignedIn
            return nil
        }
        return currentUser
    }

    
    private func processUserSessionTask(_ task: AWSTask<AWSCognitoIdentityUserSession>) async -> UserTokens? {
        do {
            let result = try await asyncTask(task)
            return .init(session: result)
        } catch(let error) {
            print("error processing user session task: \(error)")
            if let error = error as? CognitoError {
                self.error = error
            }
            return nil
        }
    }
    
    private func asyncTask<T>(_ task: AWSTask<T>) async throws -> T {
        let result: T = try await withCheckedThrowingContinuation { continuation in
            task.continueWith { task in
                if let error = task.error as? NSError {
                    continuation.resume(throwing: CognitoError.sessionError(error))
                    return
                }
                guard let result = task.result else {
                    continuation.resume(throwing: CognitoError.sessionError(nil))
                    return
                }
                continuation.resume(returning: result)
                return task
            }
        }
        return result
    }
}
