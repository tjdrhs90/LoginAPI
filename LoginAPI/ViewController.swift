//
//  ViewController.swift
//  LoginAPI
//
//  Created by sgsim on 2023/04/11.
//

import UIKit
import AuthenticationServices
import GoogleSignIn
import NaverThirdPartyLogin
import KakaoSDKUser

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SNSLogin.shared.delegate = self
    }
    
    //카카오 버튼 터치
    @IBAction func kakaoBtnTap(_ sender: UIButton) {
        print(type(of: self),#function)
        SNSLogin.shared.login(.kakao, vc: self)
    }
    //네이버 버튼 터치
    @IBAction func naverBtnTap(_ sender: UIButton) {
        print(type(of: self),#function)
        SNSLogin.shared.login(.naver, vc: self)
    }
    //구글 버튼 터치
    @IBAction func googleBtnTap(_ sender: UIButton) {
        print(type(of: self),#function)
        SNSLogin.shared.login(.google, vc: self)
    }
    //애플 버튼 터치
    @IBAction func appleBtnTap(_ sender: UIButton) {
        print(type(of: self),#function)
        SNSLogin.shared.login(.apple, vc: self)
    }
    
    //카카오 로그아웃 버튼 터치
    @IBAction func kakaoLogoutBtnTap(_ sender: UIButton) {
        print(type(of: self),#function)
        SNSLogin.shared.logout()
    }
    //네이버 로그아웃 버튼 터치
    @IBAction func naverLogoutBtnTap(_ sender: UIButton) {
        print(type(of: self),#function)
        SNSLogin.shared.logout()
    }
    //구글 로그아웃 버튼 터치
    @IBAction func googleLogoutBtnTap(_ sender: UIButton) {
        print(type(of: self),#function)
        SNSLogin.shared.logout()
    }
    //애플 로그아웃 버튼 터치
    @IBAction func appleLogoutBtnTap(_ sender: UIButton) {
        print(type(of: self),#function)
        SNSLogin.shared.logout()
    }
}


//MARK: - SNSLoginDelegate
extension ViewController: SNSLoginDelegate {
    /// SNS 로그인 성공
    func snsLoginSuccess(_ loginType: SNSLoginType, uniqueID: String) {
        print(type(of: self),#function,uniqueID)
    }
    /// SNS 로그인 실패
    func snsLoginError(_ loginType: SNSLoginType, error: Error?) {
        print(type(of: self),#function,error?.localizedDescription ?? "")
    }
}
