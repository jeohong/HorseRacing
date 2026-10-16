import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameState()

    var body: some View {
        ZStack {
            switch game.mode {
            case .GameStart:
                GameStartView(game: game)
            case .FirstGame:
                GameProcessingView(game: game)
            case .LastGame:
                FinalGameProcessingView(game: game)
            case .Rank:
                ResultView(game: game)
            }
        }
        .onAppear{
            SoundSetting.shared.play(.bgm)
        }
    }
}
