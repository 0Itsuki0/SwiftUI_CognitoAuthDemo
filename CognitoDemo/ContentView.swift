//
//  ContentView.swift
//  CognitoDemo
//
//  Created by Itsuki on 2025/02/26.
//

import SwiftUI
import AWSCognitoIdentityProvider
import AWSCognitoIdentityProviderASF

struct ContentView: View {
    private enum EntryMode {
        case signIn
        case signUp
        case forgotPassword
        case confirmSignUp
        case confirmForgotPassword
        
        var title: String {
            switch self {
            case .signIn:
                return "Sign In"
            case .signUp:
                return "Sign Up"
            case .forgotPassword:
                return "Forgot Password"
            case .confirmSignUp:
                return "Confirm Sign up"
            case .confirmForgotPassword:
                return "Enter Confirmation Code and New Password"
            }
        }
        
        var buttonTitle: String {
            switch self {
            case .signIn:
                return "Sign In"
            case .signUp:
                return "Sign Up"
            case .forgotPassword:
                return "Send Reset Code"
            case .confirmSignUp:
                return "Confirm"
            case .confirmForgotPassword:
                return "Reset Password"
            }
        }
    }
    
    @Environment(CognitoManager.self) private var cognitoManager
    
    @State private var entryMode: EntryMode? = nil
    @State private var isProcessing: Bool = false
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var code: String = ""
    
    @State private var errorMessage: String?

    var body: some View {
        @Bindable var cognitoManager = cognitoManager
        ZStack {
            VStack(spacing: 24) {
                Image(systemName: "key.icloud")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32)
                    .fontWeight(.bold)
                
                Text("Cognito Authentication")
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack {
                    Button(action: {
                        entryMode = .signIn
                    }, label: {
                        Text("Sign In")
                    })
                    
                    Text("/")
                    
                    Button(action: {
                        entryMode = .signUp
                    }, label: {
                        Text("Sign Up")
                    })
                }
            }
            
            if let entryMode {
                VStack(alignment: .leading, spacing: 24) {
                    
                    Text(entryMode.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.leading, 4)
                    
                    switch entryMode {
                    case .signIn:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username (Email)")
                                .fontWeight(.semibold)
                                .padding(.leading, 4)
                            TextField(text: $username, label: {})
                                .textFieldStyle(.roundedBorder)
                        }
                                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .fontWeight(.semibold)
                                .padding(.leading, 4)
                            SecureField(text: $password, label: {})
                                .textFieldStyle(.roundedBorder)
                        }

                    case .signUp:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username (Email)")
                                .fontWeight(.semibold)
                                .padding(.leading, 4)
                            TextField(text: $username, label: {})
                                .textFieldStyle(.roundedBorder)
                        }
                                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .fontWeight(.semibold)
                                .padding(.leading, 4)
                            SecureField(text: $password, label: {})
                                .textFieldStyle(.roundedBorder)
                        }

                    case .forgotPassword:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username (Email)")
                                .fontWeight(.semibold)
                                .padding(.leading, 4)
                            TextField(text: $username, label: {})
                                .textFieldStyle(.roundedBorder)
                        }


                    case .confirmSignUp:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirmation code")
                                .fontWeight(.semibold)
                                .padding(.leading, 4)
                            TextField(text: $code, label: {})
                                .textFieldStyle(.roundedBorder)
                        }

                    case .confirmForgotPassword:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirmation code")
                                .fontWeight(.semibold)
                                .padding(.leading, 4)
                            TextField(text: $code, label: {})
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .fontWeight(.semibold)
                                .padding(.leading, 4)
                            SecureField(text: $password, label: {})
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                        }
                        if let error = cognitoManager.error {
                            Text(error.message)
                                .foregroundStyle(.red)
                        }
                        
                        Button(action: {
                            switch entryMode {
                            case .confirmForgotPassword:
                                if code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    self.errorMessage = "Code and new password is required"
                                    return
                                }
                                break

                            case .confirmSignUp:
                                if code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    self.errorMessage = "Code is required"
                                    return
                                }
                                break
                            case .signIn, .signUp:
                                if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    self.errorMessage = "Username and password are required"
                                    return
                                }
                                break
                                
                            case .forgotPassword:
                                if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    self.errorMessage = "Username is required"
                                    return
                                }
                                break

                            }
                            
                            isProcessing = true
                            self.errorMessage = nil
                            cognitoManager.error = nil
                            
                            Task {
                                switch entryMode {
                                case .confirmSignUp:
                                    let result = await cognitoManager.confirmSignUp(username: username, confirmationCode: code)
                                    if !result {
                                        return
                                    }
                                    // AWSCognitoIdentityUser.isSignedIn will be false after confirming sign up
                                    let _ = await cognitoManager.signIn(username: username, password: password)
                                    self.entryMode = nil
                                    clearInput()
                                    break
                                    
                                case .confirmForgotPassword:
                                    let result = await cognitoManager.confirmForgotPassword(username: username, confirmationCode: code, newPassword: password)
                                    if !result {
                                        return
                                    }
                                    let _ = await cognitoManager.signIn(username: username, password: password)
                                    self.entryMode = nil
                                    clearInput()
                                    break
                                    
                                case .signIn:
                                    let tokens = await cognitoManager.signIn(username: username, password: password)
                                    if tokens == nil && cognitoManager.error != nil {
                                        if let error = cognitoManager.error, case CognitoManager.CognitoError.sessionError(let sessionError) = error {
                                            if let errorType = sessionError?.userInfo["__type"] as? String, errorType == "UserNotConfirmedException" {
                                                self.entryMode = .confirmSignUp
                                            }
                                        }
                                        return
                                    }
                                    self.entryMode = nil
                                    clearInput()
                                    break
                                    
                                case .signUp:
                                    if let user = await cognitoManager.signUp(username: username, password: password) {
                                        let confirmedStatus: AWSCognitoIdentityUserStatus = user.confirmedStatus
                                        if confirmedStatus == .confirmed {
                                            if !user.isSignedIn {
                                                let _ = await cognitoManager.signIn(username: username, password: password)
                                            }
                                            self.entryMode = nil
                                            clearInput()
                                        } else if confirmedStatus == .unconfirmed {
                                            self.entryMode = .confirmSignUp
                                        }
                                    }
                                    break
                                    
                                case .forgotPassword:
                                    let result = await cognitoManager.sendForgotPasswordCode(username: username)
                                    if !result {
                                        return
                                    }
                                    self.entryMode = .confirmForgotPassword
                                    break
                                }
                                
                                isProcessing = false
                            }
                        }, label: {
                            Text(entryMode.buttonTitle)
                        })
                        .buttonStyle(.borderedProminent)
                    }
                    
                    
                    if entryMode == .signIn {
                        HStack {
                            Text("Don't have an account?")
                            
                            Button(action: {
                                self.entryMode = .signUp
                            }, label: {
                                Text("Sign up")
                            })
                        }
                        .font(.subheadline)
                        .padding(.leading, 4)
                    }
                    
                    if entryMode == .signUp {
                        HStack {
                            Text("Already have an account?")
                            
                            Button(action: {
                                self.entryMode = .signIn
                            }, label: {
                                Text("Sign In")
                            })
                        }
                        .font(.subheadline)
                        .padding(.leading, 4)
                    }

                }
                .padding(.horizontal, 32)
                .padding(.vertical, 48)
                .frame(maxWidth: .infinity)
                .background(.blue.opacity(0.2))
                .background(RoundedRectangle(cornerRadius: 8).fill(.white).stroke(.gray, style: .init(lineWidth: 1)))
                .overlay(alignment: .topTrailing, content: {
                    Button(action: {
                        self.entryMode = nil
                    }, label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 8)
                            .foregroundStyle(.white)
                            .padding(.all, 8)
                            .background(Circle().fill(.gray))
                    })
                    .padding(.all, 16)
                })
                .onAppear {
                    cognitoManager.error = nil
                    self.errorMessage = nil
                }

            }

        }
        .padding()
        .navigationDestination(isPresented: $cognitoManager.userSignedIn, destination: {
            SignedInView()
                .environment(cognitoManager)
                .navigationBarBackButtonHidden(true)
        })
        .onAppear {
            cognitoManager.error = nil
        }
        .onDisappear {
            cognitoManager.error = nil
        }
    }
    
    private func clearInput() {
        self.username = ""
        self.password = ""
        self.code = ""
    }
}

struct SignedInView: View {
    @Environment(CognitoManager.self) private var cognitoManager

    @State private var tokens: CognitoManager.UserTokens?
    var body: some View {
        Group {
            
            if cognitoManager.userSignedIn, let token = tokens {
                
                List{
                    if let error = cognitoManager.error {
                        Text(error.message)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.red)
                    }
                    
                    NavigationLink(destination: {
                        UserDetailView()
                            .environment(cognitoManager)
                            .navigationTitle("User Details")
                    }, label: {
                        Text("User Details")
                    })
                    
                    NavigationLink(destination: {
                        TokenView(token: token.idToken?.tokenString ?? "(not available)")
                            .navigationTitle("ID Token")
                    }, label: {
                        Text("ID Token")
                    })
                    
                    NavigationLink(destination: {
                        TokenView(token: token.accessToken?.tokenString ?? "(not available)")
                            .navigationTitle("Access Token")
                    }, label: {
                        Text("Access Token")
                    })
                    
                    NavigationLink(destination: {
                        TokenView(token: token.refreshToken?.tokenString ?? "(not available)")
                            .navigationTitle("Refresh Token")
                    }, label: {
                        Text("Refresh Token")
                    })
                    
                    NavigationLink(destination: {
                        DeviceListView()
                            .environment(cognitoManager)
                            .navigationTitle("Devices")
                    }, label: {
                        Text("Devices")
                    })
                   
                }
                .toolbar(content: {
                    Button(action: {
                        cognitoManager.signOut()
                    }, label: {
                        Text("Sign Out")
                    })

                })
                .navigationTitle("Itsuki's World")
                .navigationBarTitleDisplayMode(.inline)


            } else {

                if let error = cognitoManager.error {
                    Text(error.message)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                    .frame(height: 24)
                
                Text("Tokens are not available.")
                Text("Please sign in again.")
                
                Spacer()
                    .frame(height: 24)
                
                Button(action: {
                    cognitoManager.signOut()
                }, label: {
                    Text("Back to Sign In")
                })
            }
        }
        .task {
            self.tokens = await cognitoManager.getTokens()
        }
        .onAppear {
            cognitoManager.error = nil
        }
        .onDisappear {
            cognitoManager.error = nil
        }
    }
}

struct UserDetailView: View {
    @Environment(CognitoManager.self) private var cognitoManager
    @State private var userDetails: AWSCognitoIdentityUserGetDetailsResponse? = nil
    
    @State private var showChangePassword: Bool = false
    @State private var isProcessing: Bool = false
    
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    
    @State private var errorMessage: String? = nil
    @State private var changeSuccess: Bool = false

    var body: some View {
        ZStack {
            List {
                if let error = cognitoManager.error {
                    Text(error.message)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.red)
                }

                if let userDetails {
                    VStack(alignment: .leading) {
                        let userAttributes: [AWSCognitoIdentityProviderAttributeType] = userDetails.userAttributes ?? []
                        
                        ForEach(0..<userAttributes.count, id: \.self) { index in
                            let attribute = userAttributes[index]
                            if let name = attribute.name, let value = attribute.value {
                                Text("\(name): \(value)")
                            }
                        }
                        
                        Spacer()
                            .frame(height: 16)
                        
                        Button(action: {
                            self.showChangePassword = true
                        }, label: {
                            Text("Change password")
                        })
                    }
                    .font(.subheadline)


                }
            }
            
            if showChangePassword {
                VStack(alignment: .leading, spacing: 24) {

                    Text("Change Password")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.leading, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Password")
                                    .fontWeight(.semibold)
                                    .padding(.leading, 4)
                                SecureField(text: $oldPassword, label: {})
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("New Password")
                                    .fontWeight(.semibold)
                                    .padding(.leading, 4)
                                SecureField(text: $newPassword, label: {})
                                    .textFieldStyle(.roundedBorder)
                            }

                    VStack(alignment: .leading, spacing: 8) {
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                        }
                        if let error = cognitoManager.error {
                            Text(error.message)
                                .foregroundStyle(.red)
                        }

                        Button(action: {
                            if newPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || oldPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                self.errorMessage = "Passwords are required"
                                return
                            }

                            isProcessing = true
                            self.errorMessage = nil
                            cognitoManager.error = nil

                            Task {
                                let result = await cognitoManager.changePasswordForCurrentUser(oldPassword: oldPassword, newPassword: newPassword)
                                if result {
                                    self.showChangePassword = false
                                    clearInput()
                                }
                            }
                            
                            isProcessing = false
                            
                        }, label: {
                            Text("Confirm")
                        })
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                    }
                    
                    if changeSuccess {
                        HStack {
                            Text("Password changed.")
                        }
                    }

                }
                .padding(.horizontal, 32)
                .padding(.vertical, 48)
                .frame(maxWidth: .infinity)
                .background(.blue.opacity(0.2))
                .background(RoundedRectangle(cornerRadius: 8).fill(.white).stroke(.gray, style: .init(lineWidth: 1)))
                .overlay(alignment: .topTrailing, content: {
                    if !changeSuccess {
                        Button(action: {
                            self.showChangePassword = false
                        }, label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 8)
                                .foregroundStyle(.white)
                                .padding(.all, 8)
                                .background(Circle().fill(.gray))
                        })
                        .padding(.all, 16)
                    }
                })
                .padding()
                .onAppear {
                    cognitoManager.error = nil
                    self.errorMessage = nil
                    self.changeSuccess = false
                }
            }
        }
        .task {
            cognitoManager.error = nil
            self.userDetails = await cognitoManager.getCurrentUserDetail()
        }
        .onDisappear {
            cognitoManager.error = nil
        }
    }
    
    private func clearInput() {
        self.newPassword = ""
        self.oldPassword = ""
    }
}

struct TokenView: View {
    var token: String
    
    var body: some View {
        ScrollView {
            Text(token)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
        }
    }
}

struct DeviceListView: View {
    @Environment(CognitoManager.self) private var cognitoManager
    @State private var devices: [AWSCognitoIdentityProviderDeviceType] = []
    @State private var paginationToken: String? = nil

    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        List {
            if let error = cognitoManager.error {
                Text(error.message)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.red)
            }
           
            ForEach(0..<devices.count, id:\.self) { index in
                let device: AWSCognitoIdentityProviderDeviceType = devices[index]
                let deviceKey: String? = device.deviceKey
                let createdDate: Date? = device.deviceCreateDate
                let lastAuthenticatedDate: Date? = device.deviceLastAuthenticatedDate
                let lastModifiedDate: Date? = device.deviceLastModifiedDate
                VStack(alignment: .leading) {
                    Text("Device key: \(deviceKey ?? "(not available)")")
                    if let createdDate {
                        Text("Create date: \(formatter.string(from: createdDate))")
                    }
                    if let lastAuthenticatedDate {
                        Text("Last authenticate: \(formatter.string(from: lastAuthenticatedDate))")
                    }
                    if let lastModifiedDate {
                        Text("Last modified: \(formatter.string(from: lastModifiedDate))")
                    }

                }
            }
        }
        .task {
            cognitoManager.error = nil
            let result = await cognitoManager.listDevices()
            self.devices = result.0 ?? []
            self.paginationToken = result.1
        }
        .toolbar(content: {
            if let paginationToken {
                Button(action: {
                    Task {
                        let result = await cognitoManager.listDevices(paginationToken: paginationToken)
                        self.devices.append(contentsOf: result.0 ?? [])
                        self.paginationToken = result.1
                    }
                }, label: {
                    Text("Load More")
                })
            }
        })
        .onDisappear {
            cognitoManager.error = nil
        }
    }
}

#Preview {
    NavigationStack {
//        ContentView()
//        SignedInView()
//        DeviceListView()
        UserDetailView()
            .environment(CognitoManager())

    }
}
