//
//  ViewController.swift
//  ToBetOrNot
//
//  Created by weiting chien on 16/7/19.
//  Copyright © 2019 weiting chien. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth // 這邊的Auth，是指Authentication，「新增使用者UID」或是「從Auth獲取使用者UID」需要用到這個部分
import FirebaseDatabase // 需要用到Database
import FBSDKLoginKit

class LogInViewController: UIViewController {
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    var uid = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signUpButton(_ sender: Any) {
        
        if self.email.text == "" || self.password.text == "" {
            super.showMsg("請輸入email和密碼", showMsgStatus: .loginFail, handler: nil)
            return
        }
            
        Auth.auth().createUser(withEmail: self.email.text!, password: self.password.text!, completion: { (user, error) in
                
            if error != nil {
                self.showMsg((error?.localizedDescription)!, showMsgStatus: .loginFail, handler: nil)
                return
            }
                
            if let user = Auth.auth().currentUser{
                self.uid = user.uid
            }
    
            Database.database().reference(withPath: "ID/\(self.uid)/Safety-Check").setValue("ON")
                
//            super.showMsg("註冊成功", showMsgStatus: .loginSuccess, handler: self.handler)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nextVC =  storyboard.instantiateViewController(withIdentifier: "SignUpViewControllerID") as! SignUpViewController
            self.present(nextVC, animated: true, completion: nil)
        })
    }
    
//    func handler() -> Void {
//        self.dismiss(animated: true, completion: nil)
//    }
    
    @IBAction func logInButton(_ sender: Any) {
        
        if self.email.text == "" || self.password.text == "" {
            super.showMsg("請輸入email和密碼", showMsgStatus: .loginFail, handler: nil)
            return
        }
            
        Auth.auth().signIn(withEmail: self.email.text!, password: self.password.text!, completion: { (user, error) in
            
            if error != nil {
                self.showMsg((error?.localizedDescription)!, showMsgStatus: .loginFail, handler: nil)
                return
            }
            
            if let user = Auth.auth().currentUser{
                self.uid = user.uid
            }
                    
            Database.database().reference(withPath: "Online-Status/\(self.uid)").setValue("ON")
                    
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nextVC = storyboard.instantiateViewController(withIdentifier: "ConfirmViewControllerID")as! ConfirmViewController
            self.present(nextVC,animated:true,completion:nil)
        })
    }
    
    @IBAction func ResetPassword(_ sender: UIButton) {
        if self.email.text == "" {
            self.showMsg("請輸入email", showMsgStatus: .loginFail, handler: nil)
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: self.email.text!, completion: { (error) in
            // 重設失敗
            if error != nil {
                self.showMsg((error?.localizedDescription)!, showMsgStatus: .loginFail, handler: nil)
                return
            }
            
            self.showMsg("重設成功，請檢查信箱信件", showMsgStatus: .loginFail, handler: nil)
        })
    }
    
    @IBAction func FB_Login_In(_ sender: UIButton) {
        let fbLoginManager = LoginManager()
        // 使用FB登入的SDK，並請求可以讀取用戶的基本資料和取得用戶email的權限
        fbLoginManager.logIn(permissions: ["public_profile", "email"], from: self) { (result, error) in
            
            // 登入失敗
            if error != nil {
                self.showMsg("Failed to login: \(error?.localizedDescription)", showMsgStatus: .loginFail, handler: nil)
                return
            }
            
            // 取得登入者的token失敗
            if AccessToken.current == nil {
                self.showMsg("Failed to get access token", showMsgStatus: .loginFail, handler: nil)
                return
            }
            
//            print("tokenString: \(AccessToken.current!.tokenString)")
            
            // 擷取用戶的access token，並通過調用將其轉換為Firebase的憑證
            let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
            
            // 呼叫Firebase的API處理登入的動作
            Auth.auth().signIn(with: credential, completion: { (user, error) in
                
                if error != nil {
                    self.showMsg((error?.localizedDescription)!, showMsgStatus: .loginFail, handler: nil)
                    return
                }
                
                if let currentUser = Auth.auth().currentUser {
                    self.uid = currentUser.uid
                    Database.database().reference(withPath: "ID/\(self.uid)/Name").setValue(currentUser.displayName!)
                    Database.database().reference(withPath: "ID/\(self.uid)/Gender").setValue("")
                    Database.database().reference(withPath: "ID/\(self.uid)/Email").setValue(currentUser.email!)
                    Database.database().reference(withPath: "ID/\(self.uid)/Phone").setValue("")
                    Database.database().reference(withPath: "ID/\(self.uid)/Safety-Check").setValue("ON")
                    Database.database().reference(withPath: "Online-Status/\(self.uid)").setValue("ON")
                    
                    if let uploadImageUrl = currentUser.photoURL?.absoluteString {
                        // 存放在database
                        let databaseRef = Database.database().reference(withPath: "ID/\(self.uid)/Photo")
                        
                        databaseRef.setValue(uploadImageUrl, withCompletionBlock: { (error, dataRef) in
                            
                            if error != nil {
                                
                                print("Database Error: \(error!.localizedDescription)")
                            }
                            else {
                                
                                print("圖片已儲存")
                            }
                            
                        })
                    }
                }

                // 使用FB登入成功
//                self.showMsg("使用FB登入成功", showMsgStatus: .loginSuccess, handler: nil)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let nextVC =  storyboard.instantiateViewController(withIdentifier: "ConfirmViewControllerID") as! ConfirmViewController
                self.present(nextVC, animated: true, completion: nil)
            })
        }
    }
}


extension UIViewController {
    // 提示錯誤訊息
    func showMsg(_ message: String, showMsgStatus: ShowMsgStatus, handler: (() -> Swift.Void)? = nil) {
        let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        let cancel: UIAlertAction!
        
        switch showMsgStatus {
        case .loginSuccess:
            cancel = UIAlertAction(title: "確定", style: .default) { action in
                handler!()
            }
        default:
            cancel = UIAlertAction(title: "確定", style: .default, handler: nil)
        }
        
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

enum ShowMsgStatus {
    case loginSuccess
    case loginFail
    case friendNotExist
    case friendAlreadyExist
}

