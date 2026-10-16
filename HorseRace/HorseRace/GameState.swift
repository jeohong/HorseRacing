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
    static let maxPenaltyLength = 20
}

// 벌칙을 받는 등수
enum PenaltyTarget: CaseIterable {
    case last
    case first
    
    var title: String {
        switch self {
        case .last: return "꼴등"
        case .first: return "1등"
        }
    }
    
    /// 순위표(빠른 순 정렬)에서 벌칙 대상의 인덱스
    func rankIndex(horseCount: Int) -> Int {
        switch self {
        case .last: return horseCount - 1
        case .first: return 0
        }
    }
}

enum Mode {
    case gameStart
    case firstGame
    case lastGame
    case rank
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
    @Published var mode: Mode = .gameStart
    @Published private(set) var horseCount = GameConfig.minHorseCount
    @Published var horseNames = Array(repeating: "", count: GameConfig.maxHorseCount)
    // 말별 최종 라운드 기록 (값이 작을수록 빠름)
    @Published private(set) var resultInfo: [Double] = []
    
    @Published var penalty = "" {
        didSet {
            if penalty.count > GameConfig.maxPenaltyLength {
                penalty = String(penalty.prefix(GameConfig.maxPenaltyLength))
            }
        }
    }
    @Published var penaltyTarget: PenaltyTarget = .last
    
    private let recordStore: RaceRecordStore
    
    init(recordStore: RaceRecordStore = .shared) {
        self.recordStore = recordStore
    }
    
    /// 벌칙이 입력되었는지 (공백만 있으면 없는 것으로 봄)
    var hasPenalty: Bool {
        !penalty.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
        mode = .firstGame
    }

    func finishFirstRound() {
        mode = .lastGame
    }

    func finishRace() {
        recordStore.add(makeRecord())
        mode = .rank
    }
    
    /// 현재 경주 결과로 경기 기록 생성
    func makeRecord(date: Date = Date()) -> RaceRecord {
        let ranking = RaceRanking.entries(from: resultInfo)
        return RaceRecord(
            date: date,
            ranking: ranking.map { RaceRecord.Entry(name: displayName(of: $0.horseNum), second: $0.second) },
            penalty: hasPenalty ? penalty : nil,
            penaltyRankIndex: hasPenalty ? penaltyTarget.rankIndex(horseCount: ranking.count) : nil
        )
    }

    func restart() {
        mode = .gameStart
    }
}
