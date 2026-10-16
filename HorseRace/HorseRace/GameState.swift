//
//  GameState.swift
//  HorseRace
//
//  Created by Hong jeongmin on 2026/10/16.
//

import SwiftUI

enum GameConfig {
    static let maxHorseCount = 10
    static let minHorseCount = 2
}

enum Mode {
    case GameStart
    case FirstGame
    case LastGame
    case Rank
}

// 화면 간에 공유되는 게임 상태
final class GameState: ObservableObject {
    @Published var mode: Mode = .GameStart
    @Published private(set) var horseCount = GameConfig.minHorseCount
    @Published var horseNames = Array(repeating: "", count: GameConfig.maxHorseCount)
    // 말별 최종 라운드 기록 (값이 작을수록 빠름)
    @Published private(set) var resultInfo: [Double] = []

    /// 말 수를 늘리고 성공 여부를 반환
    func increaseHorseCount() -> Bool {
        guard horseCount < GameConfig.maxHorseCount else { return false }
        horseCount += 1
        return true
    }

    /// 말 수를 줄이고 성공 여부를 반환
    func decreaseHorseCount() -> Bool {
        guard horseCount > GameConfig.minHorseCount else { return false }
        horseCount -= 1
        return true
    }

    func displayName(of index: Int) -> String {
        horseNames[index].isEmpty ? "\(index + 1)번마" : horseNames[index]
    }

    // 경주 결과를 새로 뽑고 1라운드 시작
    func startRace() {
        resultInfo = (0..<horseCount).map { _ in Double.random(in: 60.0...120.0) }
        mode = .FirstGame
    }

    func finishFirstRound() {
        mode = .LastGame
    }

    func finishRace() {
        mode = .Rank
    }

    func restart() {
        mode = .GameStart
    }
}
