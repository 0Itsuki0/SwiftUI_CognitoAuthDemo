
# Authentication with Cognito User Pool

This demo uses the AWS SDKs to implement the entire authentication flow natively focusing on Sign-in with persistent passwords, ie: the traditional username and password sign in.

The following capabilities are included.
- Sign up + Confirm sign up with confirmation code
- Sign in
- Sign out
- Forgot password + change password with confirmation code
- Change password
- Retrieve Tokens (ID Token, Access Token, and Refresh Token)
- Retrieve User Info (Details, attributes, devices)

<br>

![](./demo.gif)

## Set Up
1. Create a Amazon Cognito User Pool
2. Set up Related IDs in [`CognitoConstants`](./CognitoDemo/CognitoConstants.swift)


For more details, please refer to my blog: [SwiftUI: Authentication with Amazon Cognito User Pool](https://medium.com/@itsuki.enjoy/swiftui-authentication-with-amazon-cognito-user-pool-3956f4ff3e95)
