//
//  FeedViewController.swift
//  Parstagram
//
//  Created by  caijicang on 2021/4/29.
//

import UIKit
import Parse
import AlamofireImage

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var posts = [PFObject]()    // an array of posts
    
    var myRefreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        myRefreshControl = UIRefreshControl()
        myRefreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
        tableView.refreshControl = myRefreshControl
    }
    
    // make tableView refresh after composing one post
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadPosts()
    }
    
    @objc func loadPosts() {
        // follow the Parse documentation about query: https://docs.parseplatform.org/ios/guide/#basic-queries
        let query = PFQuery(className:"Post")
        query.includeKey("user")      // want actual user, otherwise will give us a reference
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
    
    // two functions for implementing the tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        
        let post = posts[indexPath.row]
        let user = post["user"] as! PFUser
        cell.usernameLabel.text = user.username
        
        cell.captionLabel.text = post["Description"] as? String
        
        let imageFile = post["image"] as! PFFileObject
        let urlString = imageFile.url!
        let url = URL(string: urlString)!
        
        cell.photoView.af_setImage(withURL: url)
        
        return cell
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
