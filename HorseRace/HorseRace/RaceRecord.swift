//
//  RaceRecord.swift
//  HorseRace
//
//  Created by Hong jeongmin on 2026/10/16.
//

import Foundation

// 끝난 경기 하나의 기록 (이름은 경기 당시 표시 이름 그대로 저장)
struct RaceRecord: Codable, Identifiable, Equatable {
    struct Entry: Codable, Equatable {
        let name: String
        let second: Double
    }

    var id = UUID()
    let date: Date
    /// 빠른 순으로 정렬된 순위
    let ranking: [Entry]
    /// 벌칙 내용 (벌칙이 없었으면 nil)
    let penalty: String?
    /// 벌칙을 받은 순위 인덱스 (벌칙이 없었으면 nil)
    let penaltyRankIndex: Int?

    var winnerName: String {
        ranking.first?.name ?? ""
    }

    var penaltyName: String? {
        guard let index = penaltyRankIndex, ranking.indices.contains(index) else { return nil }
        return ranking[index].name
    }

    /// 2자리로 표시하면 같은 시간이 되는 순위 인덱스 (결과 화면과 같은 규칙)
    var preciseIndices: Set<Int> {
        RaceRanking.preciseIndices(of: ranking.map { (horseNum: 0, second: $0.second) })
    }
}

// 최근 경기 기록을 UserDefaults에 저장 (최신순)
final class RaceRecordStore: ObservableObject {
    static let shared = RaceRecordStore()
    static let maxCount = 50

    @Published private(set) var records: [RaceRecord] = []

    private let defaults: UserDefaults
    private let key = "raceRecords"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let records = try? JSONDecoder().decode([RaceRecord].self, from: data) {
            self.records = records
        }
    }

    /// 가장 앞에 추가하고, 최대 개수를 넘으면 오래된 기록부터 삭제
    func add(_ record: RaceRecord) {
        records.insert(record, at: 0)
        if records.count > Self.maxCount {
            records.removeLast(records.count - Self.maxCount)
        }
        save()
    }

    func removeAll() {
        records.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }
}
