import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameState()

    var body: some View {
        ZStack {
            switch game.mode {
            case .gameStart:
                GameStartView(game: game)
            case .firstGame:
                GameProcessingView(game: game)
            case .lastGame:
                FinalGameProcessingView(game: game)
            case .rank:
                ResultView(game: game)
            }
        }
        .onAppear{
            SoundSetting.shared.play(.bgm)
        }
    }
}
