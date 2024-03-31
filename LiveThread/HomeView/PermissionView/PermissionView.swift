//
//  PermissionView.swift
//  LiveThread
//
//  Created by DRMAC on 31/03/24.
//

import SwiftUI
import Photos

struct PermissionView: View {
    @Binding var galleryAccessStatus: PHAuthorizationStatus

    private func requestGalleryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.galleryAccessStatus = status
                if self.galleryAccessStatus.rawValue == 2 {
                    self.requestGalleryAccess()
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            CarouselView()
            Text("Hey there! \n\nAre you ready to create video threads from your live photos?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            Button(action: {
                self.requestGalleryAccess()
            }) {
                Text("Let's go!")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.top, 20)
        }
    }
}
