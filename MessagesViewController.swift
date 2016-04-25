//
//  MessagesViewController.swift
//  Purradise
//
//  Created by Nguyen T Do on 4/25/16.
//  Copyright © 2016 The Legacy 007. All rights reserved.
//

//
//  MessagesViewController.swift
//
//
//  Created by Jesse Hu on 3/3/15.
//
//

import UIKit
import Parse

class MessagesViewController: UITableViewController, UIActionSheetDelegate {
    
    var messages = [PFObject]()
    
    @IBOutlet var composeButton: UIBarButtonItem!
    @IBOutlet var emptyView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // NSNotificationCenter.defaultCenter().addObserver(self, selector: "cleanup", name: NOTIFICATION_USER_LOGGED_OUT, object: nil)
        
        // NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadMessages", name: "reloadMessages", object: nil)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(MessagesViewController.loadMessages), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView?.addSubview(self.refreshControl!)
        
//        self.emptyView?.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if PFUser.currentUser() != nil {
            self.loadMessages()
        } else {
            print("User not log in")
        }
    }
    
    // MARK: - Backend methods
    
    func loadMessages() {
        let query = PFQuery(className: PF_MESSAGES_CLASS_NAME)
        query.whereKey(PF_MESSAGES_USER, equalTo: (PFUser.currentUser()?.username!)!)
//        query.includeKey(PF_MESSAGES_LASTUSER)     this is to get the user collum
        query.orderByDescending(PF_MESSAGES_UPDATEDACTION)
        query.findObjectsInBackgroundWithBlock{ (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                self.messages.removeAll(keepCapacity: false)
                self.messages += objects as [PFObject]!
                self.tableView.reloadData()
                self.updateEmptyView()
                self.updateTabCounter()
            } else {
//                ProgressHUD.showError("Network error")
                print("Network error")
            }
            self.refreshControl!.endRefreshing()
        }
    }
    
    // MARK: - Helper methods
    
    func updateEmptyView() {
//        self.emptyView?.hidden = (self.messages.count != 0)
    }
    
    func updateTabCounter() {
        var total = 0
        for message in self.messages {
            total += message[PF_MESSAGES_COUNTER]!.integerValue
        }
        let item = self.tabBarController!.tabBar.items![1]
        item.badgeValue = (total == 0) ? nil : "\(total)"
    }
    
    // MARK: - User actions
    
    func openChat(groupId: String) {
        self.performSegueWithIdentifier("messagesChatSegue", sender: groupId)
    }
    
    func cleanup() {
        self.messages.removeAll(keepCapacity: false)
        self.tableView.reloadData()
        self.updateTabCounter()
        self.updateEmptyView()
    }
    
    @IBAction func compose(sender: UIBarButtonItem) {
        let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Single recipient", "Multiple recipients", "Address Book", "Facebook Friends")
        actionSheet.showFromTabBar(self.tabBarController!.tabBar)
    }
    
    // MARK: - Prepare for segue to chatVC
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "messagesChatSegue" {
            let chatVC = segue.destinationViewController as! ChatViewController
            chatVC.hidesBottomBarWhenPushed = true
            let groupId = sender as! String
            chatVC.groupId = groupId
//        } else if segue.identifier == "selectSingleSegue" {
//            let selectSingleVC = segue.destinationViewController.topViewController as! SelectSingleViewController
//            selectSingleVC.delegate = self
//        } else if segue.identifier == "addressBookSegue" {
//            let addressBookVC = segue.destinationViewController.topViewController as! AddressBookViewController
//            addressBookVC.delegate = self
        }
    }
    
    // MARK: - UIActionSheetDelegate
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != actionSheet.cancelButtonIndex {
            switch buttonIndex {
            case 1:
                self.performSegueWithIdentifier("selectSingleSegue", sender: self)
            case 2:
                self.performSegueWithIdentifier("selectMultipleSegue", sender: self)
            case 3:
                self.performSegueWithIdentifier("addressBookSegue", sender: self)
            case 4:
                self.performSegueWithIdentifier("facebookFriendsSegue", sender: self)
            default:
                return
            }
        }
    }
    
    // MARK: - SelectSingleDelegate
    
    func didSelectSingleUser(user2: PFUser) {
        let user1 = PFUser.currentUser()!.username!
        let user2 = user2.username!
        let groupId = Messages.startPrivateChat(user1, user2: user2)
        self.openChat(groupId)
    }
    
    // MARK: - AddressBookDelegate
    
    func didSelectAddressBookUser(user2: PFUser) {
        let user1 = PFUser.currentUser()!.username!
        let user2 = user2.username!
        let groupId = Messages.startPrivateChat(user1, user2: user2)
        self.openChat(groupId)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("messagesCell") as! MessagesCell
        // cell.bindData(self.messages[indexPath.row])
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        Messages.deleteMessageItem(self.messages[indexPath.row])
        self.messages.removeAtIndex(indexPath.row)
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        self.updateEmptyView()
        self.updateTabCounter()
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let message = self.messages[indexPath.row] as PFObject
        self.openChat(message[PF_MESSAGES_GROUPID] as! String)
    }
    
}