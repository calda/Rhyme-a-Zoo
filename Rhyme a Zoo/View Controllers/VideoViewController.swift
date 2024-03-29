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
            let dataArray = dataString.split { $0 == "\n" }
            frames = []
            for frameInfo in dataArray {
                let splits = frameInfo.components(separatedBy: ":")
                let name = splits[0] + ".jpeg"
                let time = (splits[1] as NSString).doubleValue
                frames?.append((imageName: name, time: time))
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
        let progressTimer = Timer.scheduledTimer(timeInterval: 0.005, target: self, selector: #selector(VideoViewController.updatePercentageBar), userInfo: nil, repeats: true)
        timers.append(progressTimer)
    }
    
    @objc func showImage(_ timer: Timer) {
        if let imageName = timer.userInfo as? String {
            self.imageView.image = UIImage(named: imageName)
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func updatePercentageBar() {
        if let videoStartTime = videoStartTime, let videoDuration = videoDuration {
            let timeSinceStart = videoStartTime.timeIntervalSinceNow
            let percent = -timeSinceStart / videoDuration
            setProgressBarPercentage(percent)
        }
    }
    
    //MARK: - Configuring the view
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageContainerStackView: UIStackView!
    @IBOutlet weak var skipButton: UIVisualEffectView!
    @IBOutlet weak var progressBar: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        loadDataForVideo()
        
        if let frames = frames {
            imageView.image = UIImage(named: frames[0].imageName)
            imageContainer.configureAsEdgeToEdgeImageView(in: self, optional: true)
            
            if UIScreen.hasSafeAreaInsets {
                // on Safe Area screens, don't let the timer bar overlap the image
                imageContainerStackView.spacing = 0
            } else {
                // on traditional hardware, allow the timer to clip the image
                // so that the content stays 16:9
                imageContainerStackView.spacing = -10
            }
            
            if iPad() {
                imageContainerStackView.spacing = 0
                imageContainer.layer.cornerRadius = 20
                imageContainer.layer.masksToBounds = true
            }
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
    currentController.presentFullScreen(videoController, animated: true, completion: nil)
}

