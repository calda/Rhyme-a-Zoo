//
//  UniversalAudioPlayer.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/29/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

private let UAAudioQueue = DispatchQueue(label: "com.hearatale.raz.audio", attributes: [])
private var UAAudioIsPlaying = false
private var UAShouldHaltPlayback = false
private var UAAudioIsDisabled = false

enum UAConcurrentAudioMode {
    ///The audio track will immediately start playing.
    case interrupt
    ///The audio track will be added to the play queue and will attempt to play after other tracks finish playing.
    case wait
    ///The audio track will only play is no other audio is playing or queued.
    case ignore
}

func UAHaltPlayback() {
    UAShouldHaltPlayback = true
    UAAudioIsPlaying = false
    delay(0.05) {
        UAShouldHaltPlayback = false
    }
}

func UADisablePlayback(forSeconds duration: TimeInterval) {
    UAAudioIsDisabled = true
    
    Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { _ in
        UAAudioIsDisabled = false
    })
}

func UAIsAudioPlaying() -> Bool {
    return UAAudioIsPlaying
}

func UALengthOfFile(_ name: String, ofType type: String) -> TimeInterval {
    if let path = Bundle.main.path(forResource: name, ofType: type) {
        let URL = Foundation.URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: URL, options: nil)
        
        let time = asset.duration
        return TimeInterval(CMTimeGetSeconds(time))
    }
    return 0.0
}

class UAPlayer {

    var player: AVAudioPlayer?
    var name: String?
    var shouldHalt = false
    
    @discardableResult
    func play(
        _ name: String,
        ofType type: String,
        ifConcurrent mode: UAConcurrentAudioMode = .interrupt ) -> Bool
    {
        if UAAudioIsDisabled { return false  }
        
        self.name = name
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .duckOthers, .allowBluetooth])
        
        if let path = Bundle.main.path(forResource: name, ofType: type) {
            player = try? AVAudioPlayer(data: Data(contentsOf: URL(fileURLWithPath: path)))
            
            if mode == .interrupt {
                startPlayback()
                return true
            }
            
            if mode == .ignore {
                if !UAAudioIsPlaying {
                    startPlayback()
                    return true
                }
            }
            
            if mode == .wait {
                UAAudioQueue.async(execute: {
                    while(UAAudioIsPlaying) {
                        if UAShouldHaltPlayback {
                            return
                        }
                    }
                    self.startPlayback()
                })
                return true
            }
        }
        
        return false
    }
    
    func startPlayback() {
         if UAAudioIsDisabled { return }
        
        if let player = player {
            UAAudioIsPlaying = true
            player.play()
            
            UAAudioQueue.async(execute: {
                while(player.isPlaying) {
                    if self.shouldHalt && !self.fading {
                        sync {
                            self.doVolumeFade()
                        }
                        return
                    }
                    if UAShouldHaltPlayback {
                        sync {
                            self.shouldHalt = true
                            UAAudioIsPlaying = false
                        }
                    }
                }
                
                if !self.shouldHalt {
                    sync {
                        UAAudioIsPlaying = false
                    }
                }
            })
        }
    }
    
    var fading = false
    
    func doVolumeFade() {
        fading = true
        if let player = player {
            if player.volume > 0.1 {
                player.volume = player.volume - 0.1
                delay(0.1) {
                    self.doVolumeFade()
                }
            } else {
                fading = false
                player.stop()
            }
            
        }
    }
    
}
