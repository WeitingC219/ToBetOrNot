//
//  friendInviteViewController.swift
//  ToBetOrNot
//
//  Created by weiting chien on 19/7/19.
//  Copyright © 2019 weiting chien. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class FriendInviteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct Friend_Request {
        var request_name: String
        var request_by: String
        var request_target: String
        var id: String
    }
    
    @IBOutlet weak var inviteTableView: UITableView!
    // cell的identifier
    let cellIdentifier: String = "InviteTableViewCell"
    // 建立一個Refresh Control，下拉更新資料使用
    var refreshControl: UIRefreshControl!
    
    var friendList: [Friend_Request] = []
    
    //============table================
    // get the count of elements you are going to display in your tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friendList.count
    }
    
    // assign the values in your array variable to a cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 建立Cell以Event Table View Cell的型別
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! InviteTableViewCell
        
        cell.friendName.text = self.friendList[indexPath.row].request_name
        cell.id = self.friendList[indexPath.row].id
        // 將以event的id記錄到cell中
//        cell.id = self.friendList[indexPath.row].id
//        // 如果這個event是完成的，就打勾顯示，否則不顯示
//        if self.eventList[indexPath.row].finish {
//            cell.accessoryType = .checkmark
//        } else {
//            cell.accessoryType = .none
//        }
        return cell
    }
    
//    // register when user taps a cell
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath) as! InviteTableViewCell
//        // 如果這個event是完成的，就要取消打勾，否則打勾，同時異動資料庫
//        if self.eventList[indexPath.row].finish {
//            self.eventList[indexPath.row].finish = false
//            cell.accessoryType = .none
//            sqlManager.updateEventFinishById(id: cell.id, finish: false)
//        } else {
//            self.eventList[indexPath.row].finish = true
//            cell.accessoryType = .checkmark
//            sqlManager.updateEventFinishById(id: cell.id, finish: true)
//        }
//    }
    
    // 設定table view cell可以Swipe顯示按鈕
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        
        let cancel = UITableViewRowAction(style: .normal, title: "Cancel") { action, indexPath in
            
            let ref = Database.database().reference(withPath: "Friend_Request/\(self.friendList[indexPath.row].id)")
            ref.removeValue { error, _ in
                print(error?.localizedDescription)
            }
            
            self.friendList.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            
        }
        cancel.backgroundColor = UIColor.red
        
        let accept = UITableViewRowAction(style: .normal, title: "Accept") { action, indexPath in
           
            let ref_rb = Database.database().reference(withPath: "ID/\(self.uid)/Friend")
            var friend_rb: [String] = []
            var friendList = self.friendList
            ref_rb.observeSingleEvent(of: .value, with: { (snapshot) in
                
                for item in snapshot.children {
                    let friend = item as! DataSnapshot
                    friend_rb.append(friend.value! as! String)
                }
                
                friend_rb.append(friendList[indexPath.row].request_by)
                ref_rb.setValue(friend_rb)
                
            })

            let ref_rt = Database.database().reference(withPath: "ID/\(self.friendList[indexPath.row].request_by)/Friend")
            var friend_rt: [String] = []
            ref_rt.observeSingleEvent(of: .value, with: { (snapshot) in
                
                for item in snapshot.children {
                    let friend = item as! DataSnapshot
                    friend_rt.append(friend.value! as! String)
                }
                
                friend_rt.append(self.uid)
                ref_rt.setValue(friend_rt)
            })
            
            let ref = Database.database().reference(withPath: "Friend_Request/\(self.friendList[indexPath.row].id)")
            ref.removeValue { error, _ in
                print(error?.localizedDescription)
            }
            
            self.friendList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        }
        accept.backgroundColor = UIColor.lightGray
        
        return [cancel, accept]
    }
    
    var uid = ""
    @IBOutlet weak var friendName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = Auth.auth().currentUser{
            uid = user.uid
        }
        
        // 設置委任對象
        inviteTableView.delegate = self
        inviteTableView.dataSource = self
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadEventTableView), for: UIControl.Event.valueChanged)
        inviteTableView.addSubview(refreshControl)
        
        loadFriendData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func Send_Request(_ sender: UIButton) {
        
        if self.friendName.text != "" {
            
            let id = generateRandomDigits(12)
            
            let ref = Database.database().reference().child("ID")
                .queryOrdered(byChild: "Name")
                .queryEqual(toValue: self.friendName.text)
                .observeSingleEvent(of: .value) { (snapshot) in
                    
                    guard snapshot.exists() else{
                        super.showMsg("此名字帳號不存在", showMsgStatus: .friendNotExist, handler: nil)
                        return
                    }
                    
                    for item in snapshot.children {
                        
                        let friend_target = item as! DataSnapshot
                        let ref_self = Database.database().reference(withPath:"ID/\(self.uid)/Friend/")
                            .observeSingleEvent(of: .value) { (snap) in

                                for item in snap.children {
                                    let friend = item as! DataSnapshot
                                    if (friend.value! as! String == friend_target.key) {
                                        super.showMsg("已有此名字朋友朋友", showMsgStatus: .friendAlreadyExist, handler: nil)
                                        return
                                    }
                                }
                                
                                Database.database().reference(withPath: "Friend_Request/\(id)/Request_By").setValue(self.uid)
                                Database.database().reference(withPath: "Friend_Request/\(id)/Request_Target").setValue(friend_target.key)
                                Database.database().reference(withPath: "Friend_Request/\(id)/Status").setValue("Pending")
                                self.friendName.text = ""
                        }
                    }
            }
        }
    }
    
    func generateRandomDigits(_ digitNumber: Int) -> String {
        var number = ""
        for i in 0..<digitNumber {
            var randomNumber = arc4random_uniform(10)
            while randomNumber == 0 && i == 0 {
                randomNumber = arc4random_uniform(10)
            }
            number += "\(randomNumber)"
        }
        return number
    }
    
    @objc func reloadEventTableView() {
        // 移除array中的所有資料
        self.friendList.removeAll()
        // 加入新查詢回來的資料
        loadFriendData()
    }
    
    func loadFriendData() {
        Database.database().reference().child("Friend_Request")
            .queryOrdered(byChild: "Request_Target")
            .queryEqual(toValue: self.uid)
            .observeSingleEvent(of: .value) { (snapshot) in
                
                var count = snapshot.childrenCount
                
                for item in snapshot.children {
                    let from = item as! DataSnapshot
                    
                    let ref = Database.database().reference(withPath: "ID/\(from.childSnapshot(forPath: "Request_By").value!)/Name")
                    ref.observe(.value, with: { (snapshot) in
                        
                        self.friendList.append(Friend_Request(request_name: snapshot.value as! String, request_by: from.childSnapshot(forPath: "Request_By").value! as! String, request_target: self.uid, id: from.key))
                        
                        count -= 1
                        
                        if count == 0 {
                            DispatchQueue.main.async () {
                                // reload table view
                                self.inviteTableView.reloadData()
                                // 結束refresh control
                                self.refreshControl.endRefreshing()
                            }
                        }
                    })
                }
        }
        self.friendList = self.friendList.reversed()
    }
    
    @IBAction func Back(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}
