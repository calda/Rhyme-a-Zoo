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

private let UAAudioQueue = dispatch_queue_create("com.hearatale.raz.audio", DISPATCH_QUEUE_SERIAL)
private var UAAudioIsPlaying = false
private var UAShouldHaltPlayback = false

enum UAConcurrentAudioMode {
    ///The audio track will immediately start playing.
    case Interrupt
    ///The audio track will be added to the play queue and will attempt to play after other tracks finish playing.
    case Wait
    ///The audio track will only play is no other audio is playing or queued.
    case Ignore
}

func UAHaltPlayback() {
    UAShouldHaltPlayback = true
    delay(0.5) {
        UAShouldHaltPlayback = false
    }
}

func UAIsAudioPlaying() -> Bool {
    return UAAudioIsPlaying
}

class UAPlayer {

    var player: AVAudioPlayer?
    
    func play(name: String, ofType type: String, ifConcurrent mode: UAConcurrentAudioMode = .Interrupt ) -> Bool {
        
        if let path = NSBundle.mainBundle().pathForResource(name, ofType: type) {
            let data = NSData(contentsOfFile: path)
            player = AVAudioPlayer(data: data, error: nil)
            
            if mode == .Interrupt {
                startPlayback()
                return true
            }
            
            if mode == .Ignore {
                if !UAAudioIsPlaying {
                    startPlayback()
                    return true
                }
            }
            
            if mode == .Wait {
                dispatch_async(UAAudioQueue, {
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
        if let player = player {
            UAAudioIsPlaying = true
            player.play()
            
            dispatch_async(UAAudioQueue, {
                while(player.playing) {
                    if UAShouldHaltPlayback && !self.fading {
                        self.doVolumeFade()
                        UAAudioIsPlaying = false
                    }
                }
                
                player.stop()
                UAAudioIsPlaying = false
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
                player.stop()
            }
            
        }
    }
    
}

func delay(delay:Double, closure:()->()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue(), closure)
}