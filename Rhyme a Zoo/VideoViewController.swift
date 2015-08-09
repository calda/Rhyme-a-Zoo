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
    var frames: [(imageName: String, time: Double)]?
    var timers: [NSTimer] = []
    
    func loadDataForVideo() {
        /* data is in the following format:
        s1:0.0
        s2:1.0
        s3:2.0 
        ... */
        if let path = NSBundle.mainBundle().pathForResource(videoName, ofType: "txt") {
            let dataString = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as! String
            let dataArray = split(dataString){ $0 == "\n" }
            frames = []
            for frameInfo in dataArray {
                let splits = split(frameInfo){ $0 == ":" }
                let name = splits[0] + ".jpeg"
                let time = (splits[1] as NSString).doubleValue
                frames?.append(imageName: name, time: time)
            }
        }
    }
    
    func playVideo() {
        UAPlayer().play(videoName, ofType: "mp3", ifConcurrent: .Interrupt)
        
        //add timer for closing the view after playback
        let duration = UALengthOfFile(videoName, ofType: "mp3")
        let endTimer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: "showImage:", userInfo: nil, repeats: false)
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
    }
    
    func showImage(timer: NSTimer) {
        if let imageName = timer.userInfo as? String {
            self.imageView.image = UIImage(named: imageName)
        }
        else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    //MARK: - Configuring the view
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewWillAppear(animated: Bool) {
        loadDataForVideo()
        if let frames = frames {
            imageView.image = UIImage(named: frames[0].imageName)
        }
        
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
    
    @IBAction func closeView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
}