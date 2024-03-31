//
//  TabbedContentView.swift
//  LiveThread
//
//  Created by DRMAC on 31/03/24.
//

import SwiftUI

struct TabbedContentView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            AutoSelectPicturesView()
                .tabItem {
                    Label("Auto Select", systemImage: "photo.on.rectangle.angled")
                }
                .tag(0)
            SelectFromGalleryView()
                .tabItem {
                    Label("Gallery", systemImage: "photo.fill.on.rectangle.fill")
                }
                .tag(1)
        }
        .tabViewStyle(DefaultTabViewStyle())
        .accentColor(.blue)
    }
}
