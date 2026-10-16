//
//  HorseRaceApp.swift
//  HorseRace
//
//  Created by LeeChangHyeong on 2022/07/28.
//

import SwiftUI

@main
struct HorseRaceApp: App {
    @State private var isSplashFinished = false

    var body: some Scene {
        WindowGroup {
            if isSplashFinished {
                ContentView()
            } else {
                SplashView(isFinished: $isSplashFinished)
            }
        }
    }
}

// Launch Screen과 같은 로고를 메인 스레드를 막지 않고 2초간 노출
private struct SplashView: View {
    @Binding var isFinished: Bool

    var body: some View {
        Image("Logo")
            .resizable()
            .ignoresSafeArea()
            .task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFinished = true
                }
            }
    }
}
