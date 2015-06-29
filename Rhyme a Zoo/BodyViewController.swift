//
//  BodyViewController.swift
//  WordWorld
//
//  Created by Cal on 6/3/15.
//  Copyright (c) 2015 Hear a Tale. All rights reserved.
//

import Foundation
import UIKit
import Photos

let RZMainFriendSettingPath = "zooKeeper"
let WWCloseClassCollectionNotification = "com.hearatale.wordworld.closeclass"
let WWBodyBackgroundThread = dispatch_queue_create("WWBodyBackground", nil)

class BodyViewController : UIViewController {
    
    @IBOutlet weak var body: UIImageView!
    @IBOutlet weak var skinTone: UIImageView!
    @IBOutlet weak var socks: UIImageView!
    @IBOutlet weak var shoes: UIImageView!
    @IBOutlet weak var pants: UIImageView!
    @IBOutlet weak var belt: UIImageView!
    @IBOutlet weak var shirt: UIImageView!
    @IBOutlet weak var bowtie: UIImageView!
    @IBOutlet weak var mouth: UIImageView!
    @IBOutlet weak var nose: UIImageView!
    @IBOutlet weak var eyes: UIImageView!
    @IBOutlet weak var hair: UIImageView!
    @IBOutlet weak var glasses: UIImageView!
    @IBOutlet weak var wrist: UIImageView!
    @IBOutlet weak var hold: UIImageView!
    
    var imageMap: [String : UIImageView]!
    var outfitMap: [NSString : NSString] = ["bodyShape" : "Body-Feature-body.png"]
    var allFeatures: [BodyFeature] = []
    let classOrder = ["bodyShape", "body", "hair", "eyes", "nose", "mouth", "glasses", "shirt", "pants", "socks", "shoes", "bowtie", "belt", "wrist", "hold"]
    
    var currentSkinToneFeature: BodyFeature?
    let outlineHolding = "Body-Feature-body2"
    let outlineStraight = "Body-Feature-body"
    
    @IBOutlet weak var categoryCollection: UICollectionView!
    var categoryDelegate: CategoryCollectionDelegate?
    
    @IBOutlet weak var classCollection: UICollectionView!
    @IBOutlet weak var classConstraint: NSLayoutConstraint!
    var classDelegate: ClassCollectionDelegate?
    @IBOutlet weak var classTitle: UILabel!
    
    //pragma MARK: - Set Up for customizing user choice of friend
    
    @IBOutlet weak var classHeaderBackground: UIView!
    @IBOutlet weak var colorBack: UIButton!
    @IBOutlet weak var colorDice: UIButton!
    @IBOutlet weak var colorDownload: UIButton!
    @IBOutlet weak var colorReset: UIImageView!
    
    var themedColor: UIColor!
    var currentFriend: String!
    
    func prepareEditor(#color: UIColor) {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.themedColor = UIColor(hue: 202.0 / 360.0, saturation: 0.52, brightness: 0.84, alpha: 1.0)
        self.currentFriend = RZMainFriendSettingPath
        
        //load existing outfit
        let userData = NSUserDefaults.standardUserDefaults()
        if let savedOutfit = userData.valueForKey(RZMainFriendSettingPath) as? [NSString : NSString] {
            outfitMap = savedOutfit
        }
        
        imageMap = [
            "bodyShape" : body,
            "body" : skinTone,
            "socks" : socks,
            "shoes" : shoes,
            "pants" : pants,
            "belt" : belt,
            "shirt" : shirt,
            "bowtie" : bowtie,
            "mouth" : mouth,
            "nose" : nose,
            "eyes" : eyes,
            "hair" : hair,
            "glasses" : glasses,
            "wrist" : wrist,
            "hold" : hold
        ]
        
        //load data from CSV
        let csvPath = NSBundle.mainBundle().pathForResource("body feature database", ofType: "csv")!
        let csvString = String(contentsOfFile: csvPath, encoding: NSUTF8StringEncoding)!
        let csv = split(csvString){ $0 == "\n" }
        
        //process csv
        for line in csv {
            let cells = split(line){ $0 == "," }
            if cells.count != 3 {
                continue
            }
            
            let feature = BodyFeature(csvEntry: line)
            allFeatures.append(feature)
        }
        
        //set up collection views
        //category collection
        categoryDelegate = CategoryCollectionDelegate(controller: self)
        categoryCollection.delegate = categoryDelegate!
        categoryCollection.dataSource = categoryDelegate!
        categoryCollection.reloadData()
        
        //class collection
        classDelegate = ClassCollectionDelegate(controller: self)
        classCollection.delegate = classDelegate
        classCollection.dataSource = classDelegate
        classConstraint.constant = (classCollection.frame.width + 100)
        self.view.layoutIfNeeded()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "closeClassCollection", name: WWCloseClassCollectionNotification, object: nil)
        
        //tint with theme color
        classHeaderBackground.backgroundColor = themedColor
        
        //tint buttons
        let buttonsToTint = [colorBack, colorDice, colorDownload]
        for button in buttonsToTint {
            let tintable = button.imageView!.image!.imageWithRenderingMode(.AlwaysTemplate)
            button.setImage(tintable, forState: UIControlState.Normal)
            button.imageView!.tintColor = themedColor
        }
        
        //tint images
        let imagesToTint = [colorReset]
        for imageView in imagesToTint {
            let tintable = imageView.image?.imageWithRenderingMode(.AlwaysTemplate)
            imageView.image = tintable
            imageView.tintColor = themedColor
        }
        
        
        //update outfit to saved outfit
        for (className, imageName) in outfitMap {
            imageMap[className as String]?.image = UIImage(named: imageName as String)
        }
        
    }
    
    func dismissThis() {
        self.dismissViewControllerAnimated(true, completion: {
            
            //set all imageViews to nil
            for (_, imageView) in self.imageMap {
                imageView.image = nil
            }
            
        })
    }
    
    @IBAction func close(sender: AnyObject) {
        let userData = NSUserDefaults.standardUserDefaults()
        userData.setValue(self.outfitMap, forKey: self.currentFriend)
        dismissThis()
    }
    
    
    //pragma MARK: - Managing Body Figure
    
    func setImageInView(className: String, toFeature feature: BodyFeature?) {
        if let imageView = imageMap![className] {
            //deinit previous
            imageView.image = nil
            
            //set new
            imageView.image = feature?.getImage(cropped: false)
            
            //save to outfit map
            if let feature = feature {
                outfitMap.updateValue(feature.fileName, forKey: className)
            } else {
                outfitMap.removeValueForKey(className)
            }
            
            //ensure correct body stance
            if className == "body" || className == "hold" {
                if className == "body" { currentSkinToneFeature = feature }
                
                let isHolding = hold.image != nil
                if isHolding {
                    //outline
                    body.image = UIImage(named: outlineHolding)
                    outfitMap.updateValue(outlineHolding, forKey: "bodyShape")
                    
                    //skin tone
                    if let skinName = currentSkinToneFeature?.fileName as NSString? {
                        if skinName.containsString("-straight") {
                            let newSkinName = skinName.stringByReplacingOccurrencesOfString("-straight", withString: "")
                            currentSkinToneFeature = BodyFeature(duplicateAndChange: currentSkinToneFeature!, fileName: newSkinName)
                            setImageInView("body", toFeature: currentSkinToneFeature)
                        }
                    }
                }
                else if !isHolding {
                    //outline
                    body.image = UIImage(named: outlineStraight)
                    outfitMap.updateValue(outlineStraight, forKey: "bodyShape")
                    
                    //skin tone
                    if let skinName = currentSkinToneFeature?.fileName as NSString? {
                        if !skinName.containsString("-straight") {
                            let newSkinName = "\(skinName)-straight"
                            currentSkinToneFeature = BodyFeature(duplicateAndChange: currentSkinToneFeature!, fileName: newSkinName)
                            setImageInView("body", toFeature: currentSkinToneFeature)
                        }
                    }
                }
            }
            
            
        }
    }
    
    
    @IBAction func randomize(sender: AnyObject) {
        for (className, _) in imageMap! {
            
            //get new image
            let classFeatures = allFeaturesInClass(className)
            if classFeatures.count == 0 { continue }
            let randomChoice = Int(arc4random_uniform(UInt32(classFeatures.count - 1)))
            setImageInView(className, toFeature: classFeatures[randomChoice])
            
        }
    }
    
    @IBAction func reset(sender: UIButton) {
        //show warning alert
        let warning = UIAlertController(title: "Reset Friend", message: "This cannot be undone.", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Nevermind", style: .Default, handler: nil)
        let resetAction = UIAlertAction(title: "Reset", style: UIAlertActionStyle.Destructive, handler: { alert in
            
            //perform reset
            for (className, _) in self.imageMap {
                self.setImageInView(className, toFeature: nil)
                
                UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
                    sender.transform = CGAffineTransformRotate(sender.transform, CGFloat(M_PI))
                    }, completion: nil)
            }
            
        })
        
        warning.addAction(cancelAction)
        warning.addAction(resetAction)
        self.presentViewController(warning, animated: true, completion: nil)
        
    }
    
    func allFeaturesInClass(className: String) -> [BodyFeature] {
        var classFeatures: [BodyFeature] = []
        
        for feature in allFeatures {
            if feature.className == className {
                classFeatures.append(feature)
            }
        }
        
        return classFeatures
    }
    
    
    func createImageOfBody() -> UIImage {
        
        var fullRect = CGRect(origin: CGPointZero, size: CGSizeMake(1152, 1728))
        
        UIGraphicsBeginImageContext(fullRect.size)
        
        for className in classOrder {
            if let image = imageMap[className]?.image {
                image.drawInRect(fullRect)
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    //pragma MARK: - Managing Image Permissions and such
    
    var auth: PHAuthorizationStatus!
    
    @IBAction func saveBodyImage() {
        
        if auth == nil {
            auth = PHPhotoLibrary.authorizationStatus()
        }
        
        //request access
        if auth == PHAuthorizationStatus.NotDetermined {
            PHPhotoLibrary.requestAuthorization({ newStatus in
                self.auth = newStatus
                delay(1.0) {
                    self.saveBodyImage()
                }
            })
        }
        
        //no access granted
        if auth == PHAuthorizationStatus.Denied {
            //create an alert to send the user to settings
            let alert = UIAlertController(title: "Error", message: "You denied access to the camera roll.", preferredStyle: UIAlertControllerStyle.Alert)
            
            let okAction = UIAlertAction(title: "Nevermind", style: UIAlertActionStyle.Destructive, handler: nil)
            let fixAction = UIAlertAction(title: "Fix it!", style: .Default, handler: { action in
                
                UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
                //hopefully they granted permission. otherwise we're gonna have problems.
                self.auth = PHAuthorizationStatus.Authorized
                
            })
            
            alert.addAction(okAction)
            alert.addAction(fixAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        if auth == PHAuthorizationStatus.Authorized {
            let image = createImageOfBody()
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            let alert = UIAlertController(title: "Saved to Camera Roll", message: nil, preferredStyle: .Alert)
            
            //create the accessory image view
            let imageView = UIImageView(frame: CGRectMake(0, 0, 300, 100))
            imageView.image = image
            imageView.contentMode = .ScaleAspectFit
            imageView.alpha = 0.0
            
            let content = UIViewController()
            content.view.addSubview(imageView)
            alert.setValue(content, forKey: "contentViewController")
            
            //add "ok"
            let okAction = UIAlertAction(title: "ok", style: .Default, handler: nil)
            alert.addAction(okAction)
            
            self.presentViewController(alert, animated: true, completion: { success in
                let accessoryFrame = content.view.frame
                imageView.frame = CGRectMake(-1.0, -5.0, accessoryFrame.width, accessoryFrame.height * 2.0)
                UIView.animateWithDuration(0.3, animations: {
                    imageView.alpha = 1.0
                })
            })
            
        }
        
    }
    
    
    
    //pragma MARK: - Switching Between Collection Views
    
    func showClassCollection(className: String) {
        
        let classTitleMap = [
            "bodyShape" : "Body Shape",
            "body" : "Skin Tone",
            "socks" : "Socks",
            "shoes" : "Shoes",
            "pants" : "Pants",
            "belt" : "Belts",
            "shirt" : "Shirts",
            "bowtie" : "Bowties",
            "mouth" : "Mouths",
            "nose" : "Noses",
            "eyes" : "Eyes",
            "hair" : "Hair Styles",
            "glasses" : "Glasses",
            "wrist" : "Small Accessories",
            "hold" : "Big Accessories"
        ]
        
        classTitle.text = classTitleMap[className]
        classDelegate!.setClass(className)
        classCollection.reloadData()
        self.view.layoutIfNeeded()
        
        classConstraint.constant = 0
        classCollection.setContentOffset(CGPointZero, animated: false)
        
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            self.categoryCollection.transform = CGAffineTransformMakeScale(0.75, 0.75)
            self.categoryCollection.alpha = 0.0
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    @IBAction func closeClassCollection() {
        classConstraint.constant = (classCollection.frame.width + 100)
        
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            self.view.layoutIfNeeded()
            self.categoryCollection.transform = CGAffineTransformMakeScale(1.0, 1.0)
            self.categoryCollection.alpha = 1.0
            }, completion: nil)
    }
    
    @IBAction func panOutClassCollection(sender: UIPanGestureRecognizer) {
        let velocity = sender.velocityInView(self.view)
        if velocity.x > 1000 {
            closeClassCollection()
        }
    }
    
    
}

//pragma MARK: - Body Feature Data

class BodyFeature {
    
    let fileName: String
    let type: String
    let className: String
    
    init(csvEntry: String) {
        //format: fileName, type, class
        let cells = split(csvEntry){ $0 == "," }.map { String($0) }
        fileName = cells[0]
        type = cells[1]
        className = cells[2]
    }
    
    init(duplicateAndChange duplicate: BodyFeature, fileName: String) {
        self.fileName = fileName
        self.type = duplicate.type
        self.className = duplicate.className
    }
    
    func getImage(#cropped: Bool) -> UIImage {
        let bundle = NSBundle.mainBundle()
        let filePath = bundle.pathForResource(fileName + (cropped ? "#cropped" : ""), ofType: "png")
        let data = NSData(contentsOfFile: filePath!)!
        return UIImage(data: data)!
    }
    
}

//pragma MARK: - Collection View Delegates

class CategoryCollectionDelegate : NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let classOrder = ["body", "hair", "eyes", "nose", "mouth", "glasses", "shirt", "pants", "socks", "shoes", "bowtie", "belt", "wrist", "hold"]
    let controller: BodyViewController
    
    init(controller: BodyViewController) {
        self.controller = controller
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return classOrder.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        let className = classOrder[index]
        let all = controller.allFeaturesInClass(className)
        let feature = all[5]
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("feature", forIndexPath: indexPath) as! BodyCell
        cell.decorate(feature: feature)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let collectionWidth = collectionView.frame.width
        //three items per row with 0px padding
        let width = (collectionWidth - 2.0) / CGFloat(3.0)
        return CGSizeMake(width, width)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let className = classOrder[indexPath.item]
        controller.showClassCollection(className)
    }
    
}

class ClassCollectionDelegate : CategoryCollectionDelegate {
    
    var className: String?
    var features: [BodyFeature]?
    
    func setClass(name: String) {
        className = name
        features = controller.allFeaturesInClass(name)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let features = features {
            return features.count + 1
        }
        return 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let features = features {
            
            //clear button must come first
            if indexPath.item == 0 {
                return collectionView.dequeueReusableCellWithReuseIdentifier("clear", forIndexPath: indexPath) as! UICollectionViewCell
            }
            
            let feature = features[indexPath.item - 1]
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("feature", forIndexPath: indexPath) as! BodyCell
            cell.decorate(feature: feature)
            
            return cell
            
        }
        return collectionView.dequeueReusableCellWithReuseIdentifier("skin", forIndexPath: indexPath) as! UICollectionViewCell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.item == 0 {
            controller.setImageInView(className!, toFeature: nil)
            return
        }
        
        let feature = features![indexPath.item - 1]
        controller.setImageInView(className!, toFeature: feature)
    }
    
}

//pragma MARK: - Collection View Cells

class BodyCell : UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView!
    var featureName: String = ""
    
    func decorate(#feature: BodyFeature) {
        image.image = nil //deinit previous
        
        featureName = feature.fileName
        self.backgroundColor = UIColor.whiteColor()
        self.alpha = 0.0
        
        dispatch_async(WWBodyBackgroundThread, {
            
            let featureImage = feature.getImage(cropped: true)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.image.image = featureImage
                UIView.animateWithDuration(0.3, animations: {
                    self.alpha = 1.0
                })
            })
            
        })
    }
    
}
