//
//  CarouselView.swift
//  LiveThread
//
//  Created by DRMAC on 31/03/24.
//

import SwiftUI
import Combine
import SDWebImageSwiftUI

final class ColorViewModel: ObservableObject {
    @Published var selectedImageIndex = 0
    private var autoScrollTimer: AnyCancellable?
    
    let gifNames = ["gif1", "gif2", "gif3", "gif4"]
    
    init() {
        autoScrollImages()
    }
    
    func autoScrollImages() {
        autoScrollTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            withAnimation(.easeInOut(duration: 1)) {
                self?.selectedImageIndex += 1
                if self?.selectedImageIndex ?? 0 >= (self?.gifNames.count ?? 0) * 100 {
                    self?.selectedImageIndex = 0
                }
            }
        }
    }
}

struct CarouselView: View {
    @StateObject var colorViewModel = ColorViewModel()
    @GestureState private var dragState = DragState.inactive
    
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
    }
    
    var body: some View {
        VStack {
            TabView(selection: Binding<Int>(
                get: { colorViewModel.selectedImageIndex },
                set: { newIndex in colorViewModel.selectedImageIndex = newIndex }
            )) {
                ForEach(0..<colorViewModel.gifNames.count, id: \.self) { index in
                    let gifName = colorViewModel.gifNames[index]
                    let gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif")!
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                        .frame(width: 330, height: 300)
                        .ignoresSafeArea()
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(width: 330, height: 320) 
            .transition(.opacity)
            .gesture(
                DragGesture().updating($dragState) { drag, state, transaction in
                    state = .dragging(translation: drag.translation)
                }
                .onEnded { drag in
                    let dragThreshold: CGFloat = 100.0
                    if drag.predictedEndTranslation.width > dragThreshold {
                        colorViewModel.selectedImageIndex = max(colorViewModel.selectedImageIndex - 1, 0)
                    } else if drag.predictedEndTranslation.width < -dragThreshold {
                        colorViewModel.selectedImageIndex = min(colorViewModel.selectedImageIndex + 1, colorViewModel.gifNames.count - 1)
                    }
                }
            )
        }
    }
}
