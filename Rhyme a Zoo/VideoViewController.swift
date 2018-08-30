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
    var timers: [Timer] = []
    var videoDuration: TimeInterval?
    var videoStartTime: Date?
    
    func loadDataForVideo() {
        /* data is in the following format:
        s1:0.0
        s2:1.0
        s3:2.0 
        ... */
        if let path = Bundle.main.path(forResource: videoName, ofType: "txt") {
            let dataString = (try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)) as String
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
        videoStartTime = Date()
        UAPlayer().play(videoName, ofType: "mp3", ifConcurrent: .interrupt)
        
        //add timer for closing the view after playback
        self.videoDuration = UALengthOfFile(videoName, ofType: "mp3")
        let endTimer = Timer.scheduledTimer(timeInterval: videoDuration!, target: self, selector: #selector(VideoViewController.showImage(_:)), userInfo: nil, repeats: false)
        timers.append(endTimer)
        
        //add timer for frames
        if let frames = frames {
            for (image, time) in frames {
                let timer = Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(VideoViewController.showImage(_:)), userInfo: image, repeats: false)
                timers.append(timer)
            }
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
        
        //add timer for progress bar
        let progressTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(VideoViewController.updatePercentageBar), userInfo: nil, repeats: true)
        timers.append(progressTimer)
    }
    
    func showImage(_ timer: Timer) {
        if let imageName = timer.userInfo as? String {
            self.imageView.image = UIImage(named: imageName)
        }
        else {
            self.dismiss(animated: true, completion: nil)
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
    
    override func viewWillAppear(_ animated: Bool) {
        loadDataForVideo()
        if let frames = frames {
            imageView.image = UIImage(named: frames[0].imageName)
        }
        
        if RZSettingSkipVideos.currentSetting() == false {
            skipButton.isHidden = true
        } else {
            skipButton.isHidden = false
        }
        
        setProgressBarPercentage(0.0001)
    }
    
    func setProgressBarPercentage(_ percent: Double) {
        var newTransform = CGAffineTransform(scaleX: CGFloat(percent), y: CGFloat(1.0))
        
        let width = imageView.frame.width
        let hiddenWidth = width * CGFloat(1 - percent)
        newTransform.tx = -hiddenWidth / 2.0 - 2.0
        
        progressBar.transform = newTransform
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //end playback
        for timer in timers {
            timer.invalidate()
        }
        UAHaltPlayback()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        completion?()
    }
    
    @IBAction func closeView(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

func playVideo(name: String, currentController: UIViewController, completion: (() -> ())?) {
    let videoController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "video") as! VideoViewController
    videoController.videoName = name
    videoController.completion = completion
    currentController.present(videoController, animated: true, completion: nil)
}

