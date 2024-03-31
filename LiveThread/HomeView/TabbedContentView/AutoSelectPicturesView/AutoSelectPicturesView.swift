//
//  AutoSelectPicturesView.swift
//  LiveThread
//
//  Created by DRMAC on 31/03/24.
//

import SwiftUI
import Photos
import AVKit

struct AutoSelectPicturesView: View {
    @State private var latestLivePhoto: UIImage? = nil
    @State private var isProcessing: Bool = false
    @State private var videoURLs: [URL] = []

    var body: some View {
        ZStack {
            if isProcessing {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(0..<videoURLs.count, id: \.self) { index in
                            VideoDisplayCard(videoURL: videoURLs[index])
                        }
                        Button(action: {
                            processLivePhotos()
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                    .onAppear(perform: loadLatestLivePhoto)
                }
            }
        }
    }

    private func loadLatestLivePhoto() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaSubtype == %ld", PHAssetMediaSubtype.photoLive.rawValue)
        let result = PHAsset.fetchAssets(with: .image, options: options)
        
        guard let asset = result.firstObject else { return }
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 150, height: 150), contentMode: .aspectFit, options: nil) { image, _ in
            DispatchQueue.main.async {
                self.latestLivePhoto = image
            }
        }
    }

    private func processLivePhotos() {
        isProcessing = true
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaSubtype == %ld", PHAssetMediaSubtype.photoLive.rawValue)
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var images: [UIImage] = []
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        for i in 0..<min(fetchResult.count, 30) {
            let asset = fetchResult.object(at: i)
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
                if let image = image {
                    images.append(image)
                }
            }
        }
        
        createVideoFromImages(images)
    }
    
    private func createVideoFromImages(_ images: [UIImage]) {
        let tempPath = NSTemporaryDirectory() + "output\(UUID().uuidString).mp4"
        let fileURL = URL(fileURLWithPath: tempPath)
        
        if FileManager.default.fileExists(atPath: tempPath) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        guard let videoWriter = try? AVAssetWriter(outputURL: fileURL, fileType: .mp4) else {
            isProcessing = false
            return
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: images[0].size.width,
            AVVideoHeightKey: images[0].size.height
        ]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput.expectsMediaDataInRealTime = false
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: images[0].size.width,
            kCVPixelBufferHeightKey as String: images[0].size.height
        ]
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        videoWriter.add(videoWriterInput)
        
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        let queue = DispatchQueue(label: "videoQueue")
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            for i in 0..<images.count {
                if videoWriterInput.isReadyForMoreMediaData {
                    let image = images[i]
                    if let pixelBuffer = image.pixelBuffer(width: Int(image.size.width), height: Int(image.size.height)) {
                        if !pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: 1)) {
                            isProcessing = false
                            return
                        }
                    }
                }
            }
            
            videoWriterInput.markAsFinished()
            videoWriter.finishWriting {
                DispatchQueue.main.async {
                    self.videoURLs.append(fileURL)
                    isProcessing = false
                    playVideo(fileURL)
                }
            }
        }
    }
    
    private func playVideo(_ fileURL: URL) {
        let player = AVPlayer(url: fileURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        UIApplication.shared.windows.first?.rootViewController?.present(playerViewController, animated: true) {
            player.play()
        }
    }
}

