//
//  SoundSetting.swift
//  HorseRace
//
//  Created by DongKyu Kim on 2022/09/15.
//
import AVKit

enum Sound: String, CaseIterable {
    case bgm = "MA_JingleRepublic_TrendyJumpingYouth_Main"
    case startButton = "startButtonSound"
    case change = "changeSound"
    case negative = "negativeSound"
    case horseGallop = "HorseGallop"

    var fileExtension: String {
        switch self {
        case .bgm, .horseGallop: return "m4a"
        default: return "wav"
        }
    }

    var numberOfLoops: Int {
        self == .bgm ? -1 : 0
    }

    var volume: Float {
        self == .bgm ? 0.3 : 1.0
    }

    // 설정에서 꺼져 있으면 재생하지 않음
    var isEnabled: Bool {
        self == .bgm ? AppSetting.isBGMOn : AppSetting.isEffectSoundOn
    }
}

// View가 사라져도 재생이 끊기지 않도록 player를 앱 전역에서 보관
final class SoundSetting {
    static let shared = SoundSetting()

    private var players: [Sound: AVAudioPlayer] = [:]

    private init() {
        Sound.allCases.forEach { _ = player(for: $0) }
    }

    func play(_ sound: Sound) {
        guard sound.isEnabled, let player = player(for: sound) else { return }
        player.currentTime = 0
        player.play()
    }

    func stop(_ sound: Sound) {
        players[sound]?.stop()
    }

    /// 배경음악 설정이 바뀌었을 때 호출 (켜면 처음부터 재생, 끄면 정지)
    func updateBGM() {
        if Sound.bgm.isEnabled {
            play(.bgm)
        } else {
            stop(.bgm)
        }
    }

    private func player(for sound: Sound) -> AVAudioPlayer? {
        if let player = players[sound] { return player }
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: sound.fileExtension) else { return nil }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = sound.numberOfLoops
            player.volume = sound.volume
            player.prepareToPlay()
            players[sound] = player
            return player
        } catch let error {
            print("\(error.localizedDescription)")
            return nil
        }
    }
}
