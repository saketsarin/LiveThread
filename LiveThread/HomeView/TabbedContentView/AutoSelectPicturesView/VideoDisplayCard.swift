//
//  VideoDisplayCard.swift
//  LiveThread
//
//  Created by DRMAC on 31/03/24.
//

import SwiftUI
import AVKit
import Photos

struct VideoDisplayCard: View {
    var videoURL: URL
    
    @State private var isShowingPopup = false
    @State private var popupMessage = ""
    @State private var popupTitle = ""
    
    var body: some View {
        VStack {
            Button(action: {
                guard let playerViewController = createPlayerViewController() else {
                    self.isShowingPopup = true
                    self.popupTitle = "Error"
                    self.popupMessage = "Failed to create video player."
                    return
                }
                
                UIApplication.shared.windows.first?.rootViewController?.present(playerViewController, animated: true) {
                    playerViewController.player?.play()
                }
            }) {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(width: 180, height: 200)
                    .cornerRadius(10)
            }
            HStack {
                Button(action: {
                    downloadVideo()
                }) {
                    Image(systemName: "square.and.arrow.down")
                }
                .padding()
                
                Button(action: {
                    shareVideo()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .padding()
            }
        }
        .alert(isPresented: $isShowingPopup) {
            Alert(title: Text(popupTitle), message: Text(popupMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func createPlayerViewController() -> AVPlayerViewController? {
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        return playerViewController
    }
    
    private func downloadVideo() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoFileName = "\(UUID().uuidString).mp4"
        let destinationURL = documentsDirectory.appendingPathComponent(videoFileName)
        
        let downloadTask = URLSession.shared.downloadTask(with: videoURL) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    self.isShowingPopup = true
                    self.popupTitle = "Error"
                    self.popupMessage = "Failed to download video."
                }
                return
            }
            
            do {
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                DispatchQueue.main.async {
                    self.isShowingPopup = true
                    self.popupTitle = "Success"
                    self.popupMessage = "Video downloaded successfully."
                }
            } catch {
                DispatchQueue.main.async {
                    self.isShowingPopup = true
                    self.popupTitle = "Error"
                    self.popupMessage = "Failed to save video."
                }
            }
        }
        
        downloadTask.resume()
    }

    
    private func shareVideo() {
        let appIDString = "1234567890"
        let videoData = try? Data(contentsOf: videoURL)
        shareVideoData(videoData: videoData, appID: appIDString)
    }

    private func shareVideoData(videoData: Data?, appID: String) {
        guard let videoData = videoData else {
            DispatchQueue.main.async {
                self.isShowingPopup = true
                self.popupTitle = "Error"
                self.popupMessage = "Failed to load video."
            }
            return
        }
        
        let urlScheme = URL(string: "instagram-stories://share?source_application=\(appID)")
        
        if let urlScheme = urlScheme, UIApplication.shared.canOpenURL(urlScheme) {
            let pasteboardItems = [["com.instagram.sharedSticker.backgroundVideo" : videoData, "com.instagram.sharedSticker.appID" : appID]]
            let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate : Date().addingTimeInterval(60 * 5)]
            
            UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
            UIApplication.shared.open(urlScheme, options: [:], completionHandler: nil)
        } else {
            DispatchQueue.main.async {
                self.isShowingPopup = true
                self.popupTitle = "Error"
                self.popupMessage = "Failed to share video."
            }
        }
    }
}

