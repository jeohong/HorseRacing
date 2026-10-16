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

// 경주 기록 -> 순위/표시 문자열 변환
enum RaceRanking {
    typealias Entry = (horseNum: Int, second: Double)
    
    /// 기록이 빠른 순으로 정렬된 순위 (horseNum은 0부터 시작)
    static func entries(from resultInfo: [Double]) -> [Entry] {
        resultInfo.enumerated()
            .map { Entry(horseNum: $0.offset, second: $0.element / 60.0) }
            .sorted { $0.second < $1.second }
    }
    
    /// 2자리로 표시했을 때 같은 시간이 되는 순위 인덱스 (3자리로 표시 필요)
    static func preciseIndices(of entries: [Entry]) -> Set<Int> {
        var duplicates: Set<Int> = []
        for i in 0..<entries.count {
            for j in (i+1)..<entries.count {
                if formatTime(entries[i].second, precise: false)
                    == formatTime(entries[j].second, precise: false) {
                    duplicates.insert(i)
                    duplicates.insert(j)
                }
            }
        }
        return duplicates
    }
    
    // 전체 값을 먼저 반올림해야 11.996 -> "12.00s" 처럼 올림이 초 단위에 반영됨
    static func formatTime(_ second: Double, precise: Bool) -> String {
        String(format: precise ? "%.3fs" : "%.2fs", second + 10)
    }
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
