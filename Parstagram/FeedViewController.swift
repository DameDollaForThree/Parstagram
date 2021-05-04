//
//  FeedViewController.swift
//  Parstagram
//
//  Created by  caijicang on 2021/4/29.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    let commentBar = MessageInputBar()
    var showsCommentBar = false     // boolean to keep track of whether to show the comment bar
    
    var posts = [PFObject]()    // an array to store all the posts
    var selectedPost: PFObject!     // put "!" to make it optional (can be nil); keep track of which post is currently selected
    var myRefreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // comment bar attributes
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        // tableView attributes
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .interactive        // pull down tableView to dismiss keyboard
        
        // whenever keyboard is hidden, call keyboardWillBeHidden
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // set up refresh control for our tableView
        myRefreshControl = UIRefreshControl()
        myRefreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
        tableView.refreshControl = myRefreshControl
    }
    
    @objc func keyboardWillBeHidden(note: Notification) {
        commentBar.inputTextView.text = nil     // clear the input text in the comment bar
        // hide the comment bar
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    
    // two mysteries functions for MessageInputBar
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    // this magical function displays/hides the comment bar depending on the returning boolean
    override var canBecomeFirstResponder: Bool {
        return showsCommentBar
    }
    
    // make tableView refresh after composing one post
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadPosts()
    }
    
    // the main query function
    @objc func loadPosts() {
        // follow the Parse documentation about query: https://docs.parseplatform.org/ios/guide/#basic-queries
        let query = PFQuery(className:"Post")
        query.includeKeys(["user", "comments", "comments.user"])      // want actual user/comments, otherwise will give us a reference
        query.limit = 20
        query.addDescendingOrder("createdAt")   // list posts from newest to oldest
        
        // get the query
        query.findObjectsInBackground { posts, error in
            if posts != nil {
                self.posts = posts!     // store the data
                self.tableView.reloadData()     // reload the tableView
                self.myRefreshControl.endRefreshing()   // end refreshing after pulling, otherwise the spin will be there forever
            }
        }
    }
    
    // when the "post" button is pressed, add the new comment
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // create the comment
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        comment["post"] = selectedPost
        comment["user"] = PFUser.current()
        selectedPost.add(comment, forKey: "comments")
        selectedPost.saveInBackground { success, error in
            if success {
                print("Comment saved")
            } else {
                print("Error saving comment")
            }
        }
        
        tableView.reloadData()      // refresh the UI right after the comment is added
        
        // clear and dismiss the input bar
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()      // hide the comment bar
        commentBar.inputTextView.resignFirstResponder()     // hide the keyboard
    }
    
    
    @IBAction func onLogoutButton(_ sender: Any) {
        PFUser.logOut()     // clear the Parse cache
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        
        // navigate back to the login screen
        let loginViewController = main.instantiateViewController(identifier: "LoginViewController")
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        
        let delegate = windowScene.delegate as? SceneDelegate else { return }
        
        delegate.window?.rootViewController = loginViewController
    }
    
    
    // two functions for implementing the tableView
    // # of rows in section = # of rows for one post
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []      // default value is [] if nil
        return comments.count + 2
    }
    
    // # of sections = # of posts
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    // render the view each cell within a post
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]     // locate the currently selected post using "secion" instead of "row"
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        // post cell
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            
            let user = post["user"] as! PFUser
            cell.usernameLabel.text = user["username"] as? String
            
            cell.captionLabel.text = post["Description"] as? String
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            
            cell.photoView.af_setImage(withURL: url)
            
            return cell
        }
        
        // comment cell
        else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            let comment = comments[indexPath.row - 1]
            cell.commentLabel.text = comment["text"] as? String

            let user = comment["user"] as! PFUser
            cell.nameLabel.text = user["username"] as? String

            return cell
        }
        
        // add a comment cell
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]     // locate the currently selected post using "secion" instead of "row"
        let comments = (post["comments"] as? [PFObject]) ?? []      // default value is [] if nil
        
        // handle the last row "add a comment" when it's selected
        if indexPath.row == comments.count + 1 {
            showsCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post     // assign the currently selected post to the holder
        }
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
