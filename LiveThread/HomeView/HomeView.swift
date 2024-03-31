//
//  HomeView.swift
//  LiveThread
//
//  Created by DRMAC on 31/03/24.
//

import SwiftUI
import Photos

struct HomeView: View {
    @State private var galleryAccessStatus = PHPhotoLibrary.authorizationStatus()
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if galleryAccessStatus.rawValue == 3 || galleryAccessStatus.rawValue == 4 {
                TabbedContentView(selectedTab: $selectedTab)
            } else {
                PermissionView(galleryAccessStatus: $galleryAccessStatus)
            }
        }
    }
}
