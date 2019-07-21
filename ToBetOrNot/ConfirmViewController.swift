//
//  ConfirmViewController.swift
//  ToBetOrNot
//
//  Created by weiting chien on 17/7/19.
//  Copyright © 2019 weiting chien. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class ConfirmViewController: UIViewController {
    
    //在這裡從Firebase load image
    @IBOutlet weak var loadImage: UIImageView!
    
    // 這是從Firebase拿取資訊，顯示實際註冊資料的Label
    @IBOutlet weak var nameData: UILabel!
    @IBOutlet weak var genderData: UILabel!
    @IBOutlet weak var emailData: UILabel!
    @IBOutlet weak var phoneData: UILabel!
    
    // 以下四個是純粹的姓名、性別、信箱、電話的Label，原先設立為 isHidden，按下按鈕才顯示出來
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    // 編輯個人資料Button(會前往另一個頁面)，原先也是 isHidden，按下按鈕才顯示出來
    @IBOutlet weak var changePersonalInfo: UIButton!
    // 登出Button，原先也是 isHidden，按下按鈕才顯示出來
    @IBOutlet weak var logOut: UIButton!
    
    var uid = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = Auth.auth().currentUser {
            uid = user.uid
        }
    }
    
    
    @IBAction func viewDetail(_ sender: Any) {
        
        // 指 ref 是 firebase中的特定路徑，導引到特定位置，像是「FIRDatabase.database().reference(withPath: "ID/\(self.uid)/Name")」
        var ref: DatabaseReference!
        
        // 這只是將原先隱藏起來的label顯示出來
        nameLabel.isHidden = false
        genderLabel.isHidden = false
        emailLabel.isHidden = false
        phoneLabel.isHidden = false
        
        ref = Database.database().reference(withPath: "ID/\(self.uid)/Photo")
        ref.observe(.value, with: { (snapshot) in
            //存放在這個 url
            let url = snapshot.value as! String
            let maxSize : Int64 = 15 * 1024 * 1024 //大小：15MB，可視情況改變
            
            let start = url.index(url.startIndex, offsetBy: 8)
            let end = url.index(url.startIndex, offsetBy: 16)
            let range = start..<end
            let source = String(url[range])
            
            if (source == "firebase") {
                
                Storage.storage().reference(forURL: url).getData(maxSize: maxSize, completion: { (data, error) in
                    
                    if error != nil {
                        print(error!)
                        return
                    }
    
                    guard let imageData = UIImage(data: data!) else { return }
                    
                    //非同步的方式，load出來
                    DispatchQueue.main.async {
                        self.loadImage.image = imageData
                    }
                })
            }
                
            else {
                
                let fileUrl = NSURL(string: url)
                let data = try? Data(contentsOf: fileUrl! as URL)
                guard let imageData = UIImage(data: data!) else { return }
                
                //非同步的方式，load出來
                DispatchQueue.main.async {
                    self.loadImage.image = imageData
                }
            }
        })

        ref = Database.database().reference(withPath: "ID/\(self.uid)/Name")
        
        // .observe 顧名思義就是「察看」的意思，也就是說ref.observe(.value)->查看「這串導引到特定位置的路徑」的value
        // snapshot只是一個代稱(習慣為snapshot)，通常搭配.value，是指「這串路徑下的值」
        ref.observe(.value, with: { (snapshot) in
            let name = snapshot.value as! String // 假設 name 是這串路徑下的值，
            // as! String 是因為下一行程式碼self.nameData.text為label，因此必須為String
            self.nameData.text = name // self.nameData.text這個label為上一行程式碼所假設的 name
            self.nameData.isHidden = false // 再把原本隱藏的顯示出來
        })
        
        ref = Database.database().reference(withPath: "ID/\(self.uid)/Gender")
        ref.observe(.value, with: { (snapshot) in
            let gender = snapshot.value as! String
            self.genderData.text = gender
            self.genderData.isHidden = false
        })
        
        ref = Database.database().reference(withPath: "ID/\(self.uid)/Email")
        ref.observe(.value, with: { (snapshot) in
            let email = snapshot.value as! String
            self.emailData.text = email
            self.emailData.isHidden = false
        })
        
        ref = Database.database().reference(withPath: "ID/\(self.uid)/Phone")
        ref.observe(.value, with: { (snapshot) in
            let phone = snapshot.value as! String
            self.phoneData.text = phone
            self.phoneData.isHidden = false
        })
        
        logOut.isHidden = false// 登出Button顯示
        changePersonalInfo.isHidden = false// 修改個人資料Button顯示
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 前往 ChangeDataViewController，一樣使用程式碼前往以避免Firebase延遲問題
    @IBAction func changePersonInfo(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "ChangeDataViewControllerID")as! ChangeDataViewController
        self.present(nextVC,animated:true,completion:nil)
    }
    
    // 前往 LogInViewController，先在Firebase中登出，並返回到最一開始的頁面
    @IBAction func logOut(_ sender: Any) {
        
        let ref = Database.database().reference(withPath: "Online-Status/\(uid)")
        // Database 的 Online-Status: "OFF"
        ref.setValue("OFF")
        // Authentication 也 SignOut
        try!Auth.auth().signOut()
        
        // 前往LogIn頁面，回到初始頁面
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "LogInViewControllerID")as! LogInViewController
        self.present(nextVC,animated:true,completion:nil)
    }
    
    @IBAction func checkFriend(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "FriendTabViewControllerID")as! FriendTabViewController
        self.present(nextVC,animated:true,completion:nil)
    }
    
}
