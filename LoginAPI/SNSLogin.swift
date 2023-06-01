//
//  SNSLogin.swift
//  LoginAPI
//
//  Created by sgsim on 2023/04/18.
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth
import NaverThirdPartyLogin
import GoogleSignIn
import AuthenticationServices

///SNS 로그인 완료 대리자
protocol SNSLoginDelegate: AnyObject {
    /// SNS 로그인 성공
    func snsLoginSuccess(_ loginType: SNSLoginType, uniqueID: String)
    /// SNS 로그인 실패
    func snsLoginError(_ loginType: SNSLoginType, error: Error?)
}

///SNS 로그인 타입
enum SNSLoginType: String {
    case kakao
    case naver
    case google
    case apple
}

///SNS 로그인
final class SNSLogin: NSObject {
    static let shared = SNSLogin()
    
    ///네이버 로그인 인스턴스
    private let naverLoginInstance = NaverThirdPartyLoginConnection.getSharedInstance()
    ///SNS 로그인 완료 대리자
    weak var delegate: SNSLoginDelegate?
    ///SNS 로그인 타입
    private var loginType: SNSLoginType = .apple
    ///로그인 창 띄울 뷰컨트롤러
    private weak var vc: UIViewController?
    
    override init() {
        super.init()
        naverLoginInstance?.delegate = self
    }
    ///로그인
    func login(_ loginType: SNSLoginType, vc: UIViewController) {
        self.loginType = loginType
        self.vc = vc
        
        switch loginType {
        case .kakao:
            kakaoLogin()
        case .naver:
            naverLogin()
        case .google:
            googleLogin()
        case .apple:
            appleLogin()
        }
    }
    
    ///로그아웃
    func logout() {
        UserApi.shared.logout { error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("kakao logout() success.")
            }
        }
        naverLoginInstance?.requestDeleteToken()
        GIDSignIn.sharedInstance.signOut()
    }
    
    //MARK: - 카카오
    private func kakaoLogin() {
        
        ///완료 동작
        func completion(_ : OAuthToken?, error: Error?) {
            if let error {
                delegate?.snsLoginError(.kakao, error: error)
                return
            }
            print("kakao Login success.")
            
            //사용자 정보 확인
            UserApi.shared.me { [weak self] user, error in
                guard let self,
                      error == nil,
                      let user,
                      let uniqueID = user.id else {
                    self?.delegate?.snsLoginError(.kakao, error: error)
                    return
                }
                print("me() success.")
                delegate?.snsLoginSuccess(.kakao, uniqueID: String(uniqueID))
                
//                let email = user.kakaoAccount?.email ?? ""
//                let nickname = user.kakaoAccount?.profile?.nickname ?? ""
//                if let imgUrl = user.kakaoAccount?.profile?.profileImageUrl,
//                   let data = try? Data(contentsOf: imgUrl),
//                   let img = UIImage(data: data) {
//                }
            }
        }
        
        //카카오톡 앱 설치 여부 확인
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk(completion: completion) //카카오톡 앱 실행
        } else {
            UserApi.shared.loginWithKakaoAccount(completion: completion) //사파리 실행. 카카오 계정으로 로그인
        }
    }
    
    //MARK: - 네이버
    private func naverLogin() {
        naverLoginInstance?.requestThirdPartyLogin()
    }
    
    //MARK: - 구글
    private func googleLogin() {
        guard let vc else { return }
        GIDSignIn.sharedInstance.signIn(withPresenting: vc) { [weak self] signInResult, error in
            guard let self,
                  error == nil,
                  let signInResult,
                  let uniqueID = signInResult.user.userID else {
                self?.delegate?.snsLoginError(.google, error: error)
                return
            }
            delegate?.snsLoginSuccess(.google, uniqueID: uniqueID)
            
//            let emailAddress = signInResult.user.profile?.email ?? ""
//            let fullName = signInResult.user.profile?.name ?? ""
//            let givenName = signInResult.user.profile?.givenName ?? ""
//            let familyName = signInResult.user.profile?.familyName ?? ""
//            let profilePicUrl = signInResult.user.profile?.imageURL(withDimension: 320)
//            let jwt = JWTdecode.decode(jwtToken: signInResult.user.idToken?.tokenString ?? "")
        }
    }
    
    //MARK: - 애플
    private func appleLogin() {
        guard let vc else { return }
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = vc as? ASAuthorizationControllerPresentationContextProviding
        controller.performRequests()
    }
}

//MARK: - NaverThirdPartyLoginConnectionDelegate
extension SNSLogin: NaverThirdPartyLoginConnectionDelegate {
    func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
        print("네이버 로그인 성공")
        self.naverLoginPaser()
    }
    
    func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {
        print("네이버 토큰 갱신")
        self.naverLoginPaser()
    }
    
    func oauth20ConnectionDidFinishDeleteToken() {
        print("네이버 로그아웃")
    }
    
    func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection!, didFailWithError error: Error!) {
        print("에러 = \(error.localizedDescription)")
        delegate?.snsLoginError(.naver, error: error)
    }
    
    func naverLoginPaser() {
        let requestUrl = "https://openapi.naver.com/v1/nid/me"
        
        guard naverLoginInstance?.isValidAccessTokenExpireTimeNow() == true,
              let tokenType = naverLoginInstance?.tokenType,
              let accessToken = naverLoginInstance?.accessToken,
              let url = URL(string: requestUrl) else {
            delegate?.snsLoginError(.naver, error: nil)
            return
        }
        
        let authorization = "\(tokenType) \(accessToken)"
                
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        ///완료 동작
        func completion(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
            guard let data,
                  error == nil else {
                delegate?.snsLoginError(.naver, error: error)
                return
            }
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let resultJson = json["response"] as? [String: AnyObject] else {
                    delegate?.snsLoginError(.naver, error: nil)
                    return
                }
                let uniqueID = resultJson["id"] as? String ?? ""
                delegate?.snsLoginSuccess(.naver, uniqueID: uniqueID)
                
//                let name = resultJson["name"] as? String ?? ""
//                let phone = resultJson["mobile"] as! String
//                let gender = resultJson["gender"] as? String ?? ""
//                let birthyear = resultJson["birthyear"] as? String ?? ""
//                let birthday = resultJson["birthday"] as? String ?? ""
//                let profile = resultJson["profile_image"] as? String ?? ""
//                let email = resultJson["email"] as? String ?? ""
//                let nickName = resultJson["nickname"] as? String ?? ""
            } catch let error {
                delegate?.snsLoginError(.naver, error: error)
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(data, response, error)
            }
        }.resume()
    }
}

//MARK: - ASAuthorizationControllerDelegate
extension SNSLogin: ASAuthorizationControllerDelegate {
    // 성공 후 동작
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        //ASAuthorizationAppleIDCredential: 비밀번호 및 페이스ID 인증을 한 경우, ASPasswordCredential: iCloud의 패스워드를 연동했을 경우
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            delegate?.snsLoginError(.apple, error: nil)
            return
        }
        
        let uniqueID = credential.user
        delegate?.snsLoginSuccess(.apple, uniqueID: uniqueID)
        
//        guard let tokenData = credential.identityToken,
//              let tokenString = String(data: tokenData, encoding: .utf8) else { return }
//
//        let jwt = JWTdecode.decode(jwtToken: tokenString)
//        let email = jwt["email"] as? String ?? ""
//        print(email) //이메일을 가리면 bmwxz22p9z@privaterelay.appleid.com 이런 형태로 나옴
//        //이름은 맨처음 로그인할 때만 나오고, 2번째 로그인부터는 확인 불가
//        print(credential.fullName?.familyName ?? "성")
//        print(credential.fullName?.givenName ?? "이름")
    }
    
    // 실패 후 동작
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("apple login failed")
        delegate?.snsLoginError(.apple, error: error)
    }
}
