//
//  VideoViewController.swift
//  Rhyme a Zoo
//
//  Created by Cal on 8/9/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class VideoViewController : UIViewController {
    
    //MARK: - Managing Playback
    
    var videoName = "welcome-video"
    var completion: (() -> ())?
    var frames: [(imageName: String, time: Double)]?
    var timers: [NSTimer] = []
    var videoDuration: NSTimeInterval?
    var videoStartTime: NSDate?
    
    func loadDataForVideo() {
        /* data is in the following format:
        s1:0.0
        s2:1.0
        s3:2.0 
        ... */
        if let path = NSBundle.mainBundle().pathForResource(videoName, ofType: "txt") {
            let dataString = (try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)) as String
            let dataArray = dataString.characters.split{ $0 == "\n" }.map { String($0) }
            frames = []
            for frameInfo in dataArray {
                let splits = frameInfo.characters.split{ $0 == ":" }.map { String($0) }
                let name = splits[0] + ".jpeg"
                let time = (splits[1] as NSString).doubleValue
                frames?.append(imageName: name, time: time)
            }
        }
    }
    
    func playVideo() {
        videoStartTime = NSDate()
        UAPlayer().play(videoName, ofType: "mp3", ifConcurrent: .Interrupt)
        
        //add timer for closing the view after playback
        self.videoDuration = UALengthOfFile(videoName, ofType: "mp3")
        let endTimer = NSTimer.scheduledTimerWithTimeInterval(videoDuration!, target: self, selector: "showImage:", userInfo: nil, repeats: false)
        timers.append(endTimer)
        
        //add timer for frames
        if let frames = frames {
            for (image, time) in frames {
                let timer = NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: "showImage:", userInfo: image, repeats: false)
                timers.append(timer)
            }
        }
        else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        //add timer for progress bar
        let progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "updatePercentageBar", userInfo: nil, repeats: true)
        timers.append(progressTimer)
    }
    
    func showImage(timer: NSTimer) {
        if let imageName = timer.userInfo as? String {
            self.imageView.image = UIImage(named: imageName)
        }
        else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func updatePercentageBar() {
        if let videoStartTime = videoStartTime, let videoDuration = videoDuration {
            let timeSinceStart = videoStartTime.timeIntervalSinceNow
            let percent = -timeSinceStart / videoDuration
            setProgressBarPercentage(percent)
        }
    }
    
    //MARK: - Configuring the view
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var skipButton: UIVisualEffectView!
    @IBOutlet weak var progressBar: UIView!
    
    override func viewWillAppear(animated: Bool) {
        loadDataForVideo()
        if let frames = frames {
            imageView.image = UIImage(named: frames[0].imageName)
        }
        
        if RZSettingSkipVideos.currentSetting() == false {
            skipButton.hidden = true
        } else {
            skipButton.hidden = false
        }
        
        setProgressBarPercentage(0.0001)
    }
    
    func setProgressBarPercentage(percent: Double) {
        var newTransform = CGAffineTransformMakeScale(CGFloat(percent), CGFloat(1.0))
        
        let width = imageView.frame.width
        let hiddenWidth = width * CGFloat(1 - percent)
        newTransform.tx = -hiddenWidth / 2.0 - 2.0
        
        progressBar.transform = newTransform
    }
    
    override func viewDidAppear(animated: Bool) {
        playVideo()
    }
    
    override func viewWillDisappear(animated: Bool) {
        //end playback
        for timer in timers {
            timer.invalidate()
        }
        UAHaltPlayback()
    }
    
    override func viewDidDisappear(animated: Bool) {
        completion?()
    }
    
    @IBAction func closeView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

func playVideo(name name: String, currentController: UIViewController, completion: (() -> ())?) {
    let videoController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("video") as! VideoViewController
    videoController.videoName = name
    videoController.completion = completion
    currentController.presentViewController(videoController, animated: true, completion: nil)
}

