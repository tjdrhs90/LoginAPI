//
//  AppDelegate.swift
//  LoginAPI
//
//  Created by sgsim on 2023/04/11.
//

import UIKit
import KakaoSDKCommon
import KakaoSDKAuth
import AuthenticationServices
import GoogleSignIn
import NaverThirdPartyLogin

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: "000395.9b6aa42cb19c4a80a67a7f1a61a5b624.0157") { (credentialState, error) in
            switch credentialState {
            case .authorized:
                print("Authorization Logic")
            case .revoked, .notFound:
                print("Not Authorization Logic")
            default:
                break
            }
        }
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
              print("Show the app's signed-out state.")
            } else {
              print("Show the app's signed-in state.")
            }
          }
        
        settingNaverSNSLogin()
        
        KakaoSDK.initSDK(appKey: "9ebdb7befbedfb2fca279a211d82ac52")
        
        return true
    }
    
    /// 네이버 로그인 셋팅
    func settingNaverSNSLogin() {
        
        let instance = NaverThirdPartyLoginConnection.getSharedInstance()
        //네이버 앱으로 인증하는 방식 활성화
        instance?.isNaverAppOauthEnable = true
        //SafariViewController에서 인증하는 방식 활성화
        instance?.isInAppOauthEnable = true
        //인증 화면을 아이폰의 세로모드에서만 적용
        instance?.isOnlyPortraitSupportedInIphone()
        
        instance?.serviceUrlScheme = kServiceAppUrlScheme
        instance?.consumerKey = kConsumerKey
        instance?.consumerSecret = kConsumerSecret
        instance?.appName = kServiceAppName
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.handleOpenUrl(url: url)
        }
        
        var handled: Bool
        
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        
        NaverThirdPartyLoginConnection.getSharedInstance().application(app, open: url, options: options)
        
        return false
    }
}

