
import SwiftUI
import Photos
import AVKit

struct SelectFromGalleryView: View {
    @State private var livePhotos: [UIImage] = []
    @State private var selectedPhotos: [UIImage] = []
    @State private var isProcessing: Bool = false
    @State private var videoURLs: [URL] = []
    @State private var isShowingPopup = false
    @State private var popupMessage = ""
    @State private var popupTitle = ""

    var body: some View {
        VStack {
            if isProcessing {
                ProgressView()
            } else {
                if !livePhotos.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: UIScreen.main.bounds.width / 4), spacing: 0)]) {
                            ForEach(livePhotos.indices, id: \.self) { index in
                                Image(uiImage: livePhotos[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.width / 4)
                                    .clipped()
                                    .onTapGesture {
                                        if selectedPhotos.contains(livePhotos[index]) {
                                            selectedPhotos.removeAll(where: { $0 == livePhotos[index] })
                                        } else {
                                            selectedPhotos.append(livePhotos[index])
                                        }
                                    }
                                    .border(selectedPhotos.contains(livePhotos[index]) ? Color.blue : Color.clear, width: 2)
                            }
                        }
                    }
                    Button(action: {
                        processSelectedPhotos(selectedPhotos: selectedPhotos)
                    }) {
                        Text("Create Video")
                    }
                } else {
                    Text("No live photos found")
                        .font(.title)
                }
            }
            Spacer()
        }
        .padding()
        .onAppear(perform: loadAllLivePhotos)
        .alert(isPresented: $isShowingPopup) {
            Alert(title: Text(popupTitle), message: Text(popupMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func loadAllLivePhotos() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaSubtype == %ld", PHAssetMediaSubtype.photoLive.rawValue)
        let result = PHAsset.fetchAssets(with: .image, options: options)
        
        if result.count == 0 {
            self.isShowingPopup = true
            self.popupTitle = "Error"
            self.popupMessage = "No live photos found."
            return 
        }
        
        result.enumerateObjects { (asset, _, _) in
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.width / 3), contentMode: .aspectFill, options: nil) { image, _ in
                DispatchQueue.main.async {
                    if let image = image {
                        self.livePhotos.append(image)
                    } else {
                        self.isShowingPopup = true
                        self.popupTitle = "Error"
                        self.popupMessage = "Failed to load image from asset."
                    }
                }
            }
        }
    }

    private func processSelectedPhotos(selectedPhotos: [UIImage]) {
        isProcessing = true
        createVideoFromImages(selectedPhotos)
    }
    
    private func createVideoFromImages(_ images: [UIImage]) {
        let tempPath = NSTemporaryDirectory() + "output\(UUID().uuidString).mp4"
        let fileURL = URL(fileURLWithPath: tempPath)
        
        if FileManager.default.fileExists(atPath: tempPath) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        guard let videoWriter = try? AVAssetWriter(outputURL: fileURL, fileType: .mp4) else {
            isProcessing = false
            self.isShowingPopup = true
            self.popupTitle = "Error"
            self.popupMessage = "Failed to create video writer."
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
                            self.isShowingPopup = true
                            self.popupTitle = "Error"
                            self.popupMessage = "Failed to append pixel buffer."
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
