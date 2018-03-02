//
//  ChatViewController.swift
//  ChatFirebase
//
//  Created by Axel Lefaux on 17/02/2018.
//  Copyright © 2018 Axel Lefaux. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class ChatViewController: JSQMessagesViewController {
    var messages = [JSQMessage]()
    var avatarDict = [String: JSQMessagesAvatarImage]()
    let messageRef = Database.database().reference().child("messages")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentUser = Auth.auth().currentUser {
            self.senderId = currentUser.uid
            
            if currentUser.isAnonymous {
                self.senderDisplayName = "Anonymous"
            }
            else
            {
                self.senderDisplayName = currentUser.displayName
            }
        }
        // Do any additional setup after loading the view.
        
        observeMessages()
    }
    
    func observeUsers(id: String) {
        Database.database().reference().child("users").child(id).observe(DataEventType.value) { (snapshot) in
            if let dict = snapshot.value as? [String: AnyObject] {
                let avatarUrl = dict["profileUrl"] as! String
                self.setupAvatar(url: avatarUrl, messageId: id)
            }
        }
    }
    
    func setupAvatar(url: String, messageId: String) {
        if url != "" {
            let data = try? Data(contentsOf: URL(string: url)!)
            let image = UIImage(data: data!)
            let userImg = JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: 30)
            avatarDict[messageId] = userImg
        }
        else {
            let userImg = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "profileImage.png"), diameter: 10)
            avatarDict[messageId] = userImg
        }
        
        collectionView.reloadData()
    }
    
    func observeMessages() {
        messageRef.observe(DataEventType.childAdded, with: { snapshot in
            if let dict = snapshot.value as? [String: AnyObject] {
                let mediaType = dict["mediaType"] as! String
                let senderId = dict["senderId"] as! String
                let senderName = dict["senderName"] as! String
                
                self.observeUsers(id: senderId)
                
                switch mediaType {
                    case "TEXT":
                        let text = dict["text"] as! String
                        self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
                    case "PHOTO":
                        let fileUrl = dict["fileUrl"] as! String
                        if let data = try? Data(contentsOf: URL(string: fileUrl)!) {
                            let picture = UIImage(data: data)
                            let photo = JSQPhotoMediaItem(image: picture)
                            photo?.appliesMediaViewMaskAsOutgoing = self.senderId == senderId
                            
                            self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: photo))
                        }
                    case "VIDEO":
                        let fileUrl = dict["fileUrl"] as! String
                        let url = NSURL(string: fileUrl)
                        let video  = JSQVideoMediaItem(fileURL: url!.absoluteURL!, isReadyToPlay: true)
                        video?.appliesMediaViewMaskAsOutgoing = self.senderId == senderId
                        
                        self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: video))
                    default:
                        print("unknown media type")
                }
                
                self.collectionView.reloadData()
            }
        })
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text": text, "senderId": senderId, "senderName": senderDisplayName, "mediaType": "TEXT"]
        newMessage.setValue(messageData)
        
        print(messages)
        self.finishSendingMessage()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Number of item: \(messages.count)")
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        if message.senderId == self.senderId {
            return bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.blue)
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.red)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        
        return avatarDict[message.senderId]
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("didPressAccessoryButton")
        let sheet = UIAlertController(title: "Media message", message: "Please select a media", preferredStyle: UIAlertControllerStyle.actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alert:UIAlertAction) in
            
        }
        
        let photoLibrary = UIAlertAction(title: "Photo library", style: UIAlertActionStyle.default)  { (alert: UIAlertAction) in
            self.getMediaFrom(type: kUTTypeImage)
        }
        
        let videoLibrary = UIAlertAction(title: "Video library", style: UIAlertActionStyle.default)  { (alert: UIAlertAction) in
            self.getMediaFrom(type: kUTTypeMovie)
        }
        
        sheet.addAction(photoLibrary)
        sheet.addAction(videoLibrary)
        sheet.addAction(cancel)
        self.present(sheet, animated: true, completion: nil)
    }
    
    func getMediaFrom(type: CFString) {
        print(type)
        
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.present(mediaPicker, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        print("didTapMessageBubbleAt: \(indexPath.item)")
        
        let message = messages[indexPath.item]
        
        if message.isMediaMessage {
            if let mediaItem = message.media as? JSQVideoMediaItem {
                let player = AVPlayer(url: mediaItem.fileURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func logoutDidTapped(_ sender: Any) {
        if let _ = try? Auth.auth().signOut() {
            // Create a main storyboard instance
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            // From main storyboard instantiate a View controller
            let logInVC = storyboard.instantiateViewController(withIdentifier: "LogInVC") as! LogInViewController
            
            // Get the app delegate
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            // Set LogIn View Controller as root view controller
            appDelegate.window?.rootViewController = logInVC
        }
        else {
            print("Logout exception")
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func sendMedia(picture: UIImage?, video: NSURL?){
        print(Storage.storage().reference())
        if picture != nil {
            print(picture!)
            
            let filePath = "\(Auth.auth().currentUser!)/\(NSDate.timeIntervalSinceReferenceDate)"
            print(filePath)
            let data = UIImageJPEGRepresentation(picture!, 0.1)
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpg"
            Storage.storage().reference().child(filePath).putData(data!, metadata: nil) { (metadata, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                
                print(metadata!)
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "mediaType": "Photo"]
                newMessage.setValue(messageData)
            }
        } else if video != nil {
            let filePath = "\(Auth.auth().currentUser!)/\(NSDate.timeIntervalSinceReferenceDate)"
            print(filePath)
            if let data = try? Data(contentsOf: video!.absoluteURL!) {
                let metadata = StorageMetadata()
                metadata.contentType = "video/mp4"
                Storage.storage().reference().child(filePath).putData(data, metadata: metadata) { (metadata, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    
                    print(metadata!)
                    let fileUrl = metadata!.downloadURLs![0].absoluteString
                    let newMessage = self.messageRef.childByAutoId()
                    let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "mediaType": "VIDEO"]
                    newMessage.setValue(messageData)
                }
            }
        }
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("did finish picking")
        
        // Get the image
        print(info)
        
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
            sendMedia(picture: picture, video: nil)
        }
        else if let picture = info[UIImagePickerControllerEditedImage] as? UIImage {
            sendMedia(picture: picture, video: nil)
        }
        else if let video = info[UIImagePickerControllerMediaURL] as? NSURL {
            sendMedia(picture: nil, video: video)
        }
        
        self.dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
}
