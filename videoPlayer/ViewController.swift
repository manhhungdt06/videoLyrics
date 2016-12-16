//
//  ViewController.swift
//  videoPlayer
//
//  Created by techmaster on 12/15/16.
//  Copyright © 2016 techmaster. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

let kDOCUMENT_DIRECTORY_PATH = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first

class ViewController: UIViewController {
    
    let lyricsLabel = UILabel()
    
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    
    // seeking function
    let seekSlider = UISlider()
    var playerRateBeforeSeek: Float = 0
    
    // playback function
    let invisibleButton = UIButton()
    // footage time
    var timeLeft: AnyObject!
    let timeRemainingLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        
        print(kDOCUMENT_DIRECTORY_PATH!)
        
        // An AVPlayerLayer is a CALayer instance to which the AVPlayer can
        // direct its visual output. Without it, the user will see nothing.
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        view.layer.insertSublayer(avPlayerLayer, at: 0)
        
        // playback function
        view.addSubview(invisibleButton)
        invisibleButton.addTarget(self, action: #selector(invisibleButtonTapped),
                                  for: .touchUpInside)
        
        
        
        let url = NSURL(string: "http://zmp3-mp3-mv1.zmp3-bdhcm-1.za.zdn.vn/abd0cfa9f1ec18b241fd/6483461601137111605?key=QEynjK3rF07mK3Y_svta0w&expires=1481875598")
        
        //        http://news.video.thethao.vnecdn.net/video/web/mp4/2016/12/14/al-ahli-3-5-barcelona-1481676378.mp4
        //        https://v.cdn.vine.co/r/videos/AA3C120C521177175800441692160_38f2cbd1ffb.1.5.13763579289575020226.mp4
        //        http://mv1.mp3.zdn.vn/abd0cfa9f1ec18b241fd/6483461601137111605?key=kt0yglznLkb_GfpdDq9uBw&expires=1481810007
        
        let playerItem = AVPlayerItem(url: url! as URL)
        avPlayer.replaceCurrentItem(with: playerItem)
        
        let timeInterval: CMTime = CMTimeMakeWithSeconds(1.0, 10)
        timeLeft = avPlayer.addPeriodicTimeObserver(forInterval: timeInterval,
                                                    queue: DispatchQueue.main) { (elapsedTime: CMTime) -> Void in
                                                        //                                                        print("elapsedTime now:", CMTimeGetSeconds(elapsedTime))
                                                        self.observeTime(elapsedTime: elapsedTime)
            } as AnyObject!
        
        timeRemainingLabel.textColor = UIColor.white
        lyricsLabel.textColor = UIColor.white
        view.addSubview(timeRemainingLabel)
        view.addSubview(lyricsLabel)
        
        // for slider
        view.addSubview(seekSlider)
        seekSlider.addTarget(self, action: #selector(sliderBeganTracking), for: .touchDown)
        seekSlider.addTarget(self, action: #selector(sliderEndedTracking), for: [.touchUpInside, .touchUpOutside])
        seekSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateFrame), userInfo: nil, repeats: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        avPlayer.play() // Start the playback
    }
    
    deinit {
        avPlayer.removeTimeObserver(timeLeft)
    }
    
    override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        //        let rect = CGRect(x: 16, y: 73, width: 343, height: 197)
        // Layout subviews manually
        
        // old: view.bounds
        
        avPlayerLayer.frame = view.bounds
        // hidden button
        invisibleButton.frame = view.bounds
        
        // time label -30 / +60
        let controlsHeight: CGFloat = 30
        let controlsY: CGFloat = view.bounds.height - controlsHeight
        
        lyricsLabel.frame = CGRect(x: 5, y: 20, width: 303, height: 30)

        //        textOfLabel(lyric, curTime)

        Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.getTextOfLabel), userInfo: nil, repeats: true)

        lyricsLabel.font = UIFont.systemFont(ofSize: 14)
        
        timeRemainingLabel.frame = CGRect(x: 5, y: controlsY, width: 60, height: controlsHeight)
        
        seekSlider.frame = CGRect(x: timeRemainingLabel.frame.origin.x + timeRemainingLabel.bounds.size.width,
                                  y: controlsY, width: view.bounds.size.width - timeRemainingLabel.bounds.size.width - 5, height: controlsHeight)
    }
    
    // for hidden button
    func invisibleButtonTapped(sender: UIButton) {
        let playerIsPlaying = avPlayer.rate > 0
        if playerIsPlaying {
            avPlayer.pause()
        } else {
            avPlayer.play()
        }
    }
    
    // time label
    
    func updateTimeLabel(elapsedTime: Float64, duration: Float64) {
        // test
        // CMTimeGetSeconds(avPlayer.currentItem!.duration) -
        let timeRemaining: Float64 = CMTimeGetSeconds(avPlayer.currentItem!.duration) - elapsedTime
        // (CMTimeGetSeconds(avPlayer.currentItem!.duration) - timeRemaining)
        timeRemainingLabel.text = String(format: "%02d:%02d", ((lround((CMTimeGetSeconds(avPlayer.currentItem!.duration) - timeRemaining)) / 60) % 60), lround((CMTimeGetSeconds(avPlayer.currentItem!.duration) - timeRemaining)) % 60)
    }
    
    func observeTime(elapsedTime: CMTime) {
        let duration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        
        if duration.isFinite {
            let elapsedTime = CMTimeGetSeconds(elapsedTime)
            updateTimeLabel(elapsedTime: elapsedTime, duration: duration)
        }
    }
    
    //    // Force the view into landscape mode (which is how most video media is consumed.)
    //
    //    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    //        return UIInterfaceOrientationMask.landscape
    //    }
    
    //  for slider
    
    func sliderBeganTracking() {
        playerRateBeforeSeek = avPlayer.rate
        avPlayer.pause()
    }
    
    func sliderEndedTracking() {
        let videoDuration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        let elapsedTime: Float64 = videoDuration * Float64(seekSlider.value)
        updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
        
        avPlayer.seek(to: CMTimeMakeWithSeconds(elapsedTime, 100)) { (completed: Bool) -> Void in
            if self.playerRateBeforeSeek > 0 {
                self.avPlayer.play()
            }
        }
    }
    
    func sliderValueChanged() {
        let videoDuration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        let elapsedTime: Float64 = videoDuration * Float64(seekSlider.value)
        updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
    }
    
    func updateFrame() {
        let curTime = CMTimeGetSeconds(avPlayer.currentItem!.currentTime())
        let videoDuration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        
        seekSlider.value = Float(curTime/videoDuration)
    }
    
    func getLyrics() -> [Lyrics] {
        var lyricList = [Lyrics]()
        
        if let dir = kDOCUMENT_DIRECTORY_PATH {
            let file = dir + "/lyrics_file.txt"
            let data = try! String(contentsOfFile: file)
            
            var myStr = data.components(separatedBy: .newlines)
            
            for str in myStr {
                if str == "" {
                    myStr.remove(at: myStr.index(of: str)!)
                }
            }
            for i in 4..<myStr.count {
                
                var temp = String(myStr[i])!.components(separatedBy: "]")
                
                temp[0].remove(at: temp[0].startIndex)
                
                //                print("mytime[\(i)] = \(temp[0]) - mylyrics[\(i)] = \(temp[1])")
                
                lyricList.append(Lyrics(time: temp[0], content: temp[1]))
            }
        }
        return lyricList
    }
    
    func stringToTime(_ string : String) -> Double {
        let string1 = string.components(separatedBy: ":")
        let min = Double(string1[0])
        
        let string2 = string1[1].components(separatedBy: ".")
        let sec = Double(string2[0])
        let msec = Double(string2[1])! * 0.01
        
        return min! * 60 + sec! + msec
    }
    
    var j = 0
    
    func getTextOfLabel() {
        
        let lyric = getLyrics()
        
        let curTime = Double(CMTimeGetSeconds(avPlayer.currentItem!.currentTime()))
        
        if lyric.count != 0 {
            let lyricTime = stringToTime(lyric[j].time)

            if curTime >= lyricTime {
                
                let duration2Lyrics = stringToTime(lyric[j+1].time) - stringToTime(lyric[j].time)
                
                print("curTime = \(curTime) and lyricTime = \(lyricTime) and content = \(lyric[j].content)")
                
                lyricsLabel.text = lyric[j].content

//                let lengthText = lyric[j].content == "" ? 3 : Double(lyric[j].content.characters.count)
//                
//                var length = 0.0
//                if lengthText < 5 {
//                    length = lengthText * 1.1
//                } else if lengthText < 10 && lengthText > 5{
//                    length = lengthText * 3
//                } else if lengthText < 15 && lengthText > 10{
//                    length = lengthText * 4
//                } else {
//                    length = lengthText * 5
//                }
//                
//                let characterInterval = duration2Lyrics / length
//                
//                lyricsLabel.setTextWithWordTypeAnimation(typedText: lyricsLabel, characterInterval: characterInterval)
                
                j += 1
            }
            
        }
    }
}

extension UILabel {
    func setTextWithWordTypeAnimation(typedText: UILabel, characterInterval: Double) {
        DispatchQueue.global().async {
            let attributedString = NSMutableAttributedString(string:typedText.text!)
            for i in 0...typedText.text!.characters.count{
                
                DispatchQueue.main.async {
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.red , range:  NSRange(location: 0, length: i) )
                    typedText.attributedText = attributedString
                }
                Thread.sleep(forTimeInterval: characterInterval)
                
                attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.black , range:  NSRange(location: 0, length: typedText.text!.characters.count))
                typedText.attributedText = attributedString
            }
        }
    }
}

