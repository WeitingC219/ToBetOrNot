//
//  FriendListViewController.swift
//  ToBetOrNot
//
//  Created by weiting chien on 20/7/19.
//  Copyright © 2019 weiting chien. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class FriendListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct Friend {
        var id: String
        var name: String
    }
    
    var friendName: [Friend] = []
    
    var uid = ""
    
    @IBOutlet weak var friendTableView: UITableView!
  
    let cellIdentifier: String = "FriendTableViewCell"
    var refreshControl: UIRefreshControl!
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friendName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! FriendTableViewCell
        cell.friendName.text = self.friendName[indexPath.row].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, indexPath in
            
            print(self.uid)
            print(self.friendName[indexPath.row].id)
            
            let friendName = self.friendName
            let ref_rb = Database.database().reference(withPath:"ID/\(self.friendName[indexPath.row].id)/Friend/")
            ref_rb.observeSingleEvent(of: .value, with: { snapshot in
                if let friend_rb = snapshot.value as? [String] {
                    for i in 0..<friend_rb.count {
                        if friend_rb[i] == self.uid {
                            ref_rb.child("\(i)").removeValue()
                        }
                    }
                }
                
            })
            
            let ref_rt = Database.database().reference(withPath:"ID/\(self.uid)/Friend/")
            ref_rt.observeSingleEvent(of: .value, with: { snapshot in
                if let friend_rt = snapshot.value as? [String] {
                    print(friend_rt)
                    for i in 0..<friend_rt.count {
        
                        if friend_rt[i] == friendName[indexPath.row].id {
                            ref_rt.child("\(i)").removeValue()
                        }
                    }
                }
                
            })
            
            self.friendName.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        }
        delete.backgroundColor = UIColor.red
        
        return [delete]
    }
    
    override func viewDidLoad() {
        
        if let user = Auth.auth().currentUser{
            uid = user.uid
        }
        
        // 設置委任對象
        friendTableView.delegate = self
        friendTableView.dataSource = self
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadEventTableView), for: UIControl.Event.valueChanged)
        friendTableView.addSubview(refreshControl)
        
        loadFriendData()
        
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func reloadEventTableView() {
        // 移除array中的所有資料
        self.friendName.removeAll()
        // 加入新查詢回來的資料
        loadFriendData()
    }
    
    func loadFriendData() {
        
        Database.database().reference(withPath:"ID/\(self.uid)/Friend/")
            .observeSingleEvent(of: .value) { (snapshot) in
                
            var count = snapshot.childrenCount
            
            for item in snapshot.children {
                let friend = item as! DataSnapshot
                
                Database.database().reference(withPath:"ID/\(friend.value! as! String)/Name")
                    .observe(.value, with: { (snap) in
                        self.friendName.append(Friend(id: friend.value! as! String, name: snap.value as! String))
                        
                        count -= 1
                        
                        if count == 0 {
                            DispatchQueue.main.async () {
                                // reload table view
                                self.friendTableView.reloadData()
                                // 結束refresh control
                                self.refreshControl.endRefreshing()
                            }
                        }
                })
            }
        }
        self.friendName = self.friendName.reversed()
    }
    
    @IBAction func Back(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
