//
//  HorseRaceTests.swift
//  HorseRaceTests
//
//  Created by LeeChangHyeong on 2022/07/28.
//

import XCTest
@testable import HorseRace

// MARK: - RaceRanking

final class RaceRankingTests: XCTestCase {

    // MARK: formatTime

    func test_formatTime_2자리_표시() {
        XCTAssertEqual(RaceRanking.formatTime(1.234, precise: false), "11.23s")
    }

    func test_formatTime_3자리_표시() {
        XCTAssertEqual(RaceRanking.formatTime(1.2345, precise: true), "11.235s")
    }

    func test_formatTime_반올림이_초단위로_올라감() {
        // 예전에는 "11s 00ms"로 잘못 표시되던 케이스
        XCTAssertEqual(RaceRanking.formatTime(1.996, precise: false), "12.00s")
        XCTAssertEqual(RaceRanking.formatTime(1.9996, precise: true), "12.000s")
    }

    // MARK: entries

    func test_entries_빠른순으로_정렬() {
        let entries = RaceRanking.entries(from: [90, 60, 120])

        XCTAssertEqual(entries.map(\.horseNum), [1, 0, 2])
    }

    func test_entries_기록을_60으로_나눈_초로_변환() {
        let entries = RaceRanking.entries(from: [90])

        XCTAssertEqual(entries[0].second, 1.5, accuracy: 0.000_001)
    }

    func test_entries_빈_기록() {
        XCTAssertTrue(RaceRanking.entries(from: []).isEmpty)
    }

    // MARK: preciseIndices

    func test_preciseIndices_2자리가_같으면_해당_순위만_3자리_표시() {
        // 0.501s, 0.503s -> 둘 다 "10.50s", 0.9s는 다름
        let entries = RaceRanking.entries(from: [0.501 * 60, 0.503 * 60, 0.9 * 60])

        XCTAssertEqual(RaceRanking.preciseIndices(of: entries), [0, 1])
    }

    func test_preciseIndices_겹치는_시간이_없으면_빈_집합() {
        let entries = RaceRanking.entries(from: [60, 90, 120])

        XCTAssertTrue(RaceRanking.preciseIndices(of: entries).isEmpty)
    }

    func test_preciseIndices_말이_1마리여도_크래시_없음() {
        let entries = RaceRanking.entries(from: [60])

        XCTAssertTrue(RaceRanking.preciseIndices(of: entries).isEmpty)
    }
}

// MARK: - GameState

final class GameStateTests: XCTestCase {

    private var game: GameState!
    private var recordStore: RaceRecordStore!
    private let suiteName = "GameStateTests"

    override func setUp() {
        super.setUp()
        // 실제 경기 기록에 쓰이지 않도록 테스트 전용 저장소 사용
        UserDefaults().removePersistentDomain(forName: suiteName)
        recordStore = RaceRecordStore(defaults: UserDefaults(suiteName: suiteName)!)
        game = GameState(recordStore: recordStore)
    }

    override func tearDown() {
        game = nil
        recordStore = nil
        UserDefaults().removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_초기상태() {
        XCTAssertEqual(game.mode, .gameStart)
        XCTAssertEqual(game.horseCount, GameConfig.minHorseCount)
        XCTAssertEqual(game.horseNames.count, GameConfig.maxHorseCount)
        XCTAssertTrue(game.resultInfo.isEmpty)
    }

    // MARK: 말 수 조절

    func test_increaseHorseCount_최대치까지만_증가() {
        for _ in GameConfig.minHorseCount..<GameConfig.maxHorseCount {
            XCTAssertTrue(game.increaseHorseCount())
        }

        XCTAssertFalse(game.increaseHorseCount())
        XCTAssertEqual(game.horseCount, GameConfig.maxHorseCount)
    }

    func test_decreaseHorseCount_최소치_아래로_감소하지_않음() {
        XCTAssertFalse(game.decreaseHorseCount())
        XCTAssertEqual(game.horseCount, GameConfig.minHorseCount)
    }

    func test_decreaseHorseCount_증가후_감소() {
        _ = game.increaseHorseCount()

        XCTAssertTrue(game.decreaseHorseCount())
        XCTAssertEqual(game.horseCount, GameConfig.minHorseCount)
    }

    // MARK: displayName

    func test_displayName_이름이_없으면_기본이름() {
        XCTAssertEqual(game.displayName(of: 0), "1번마")
        XCTAssertEqual(game.displayName(of: 9), "10번마")
    }

    func test_displayName_입력한_이름() {
        game.horseNames[2] = "번개"

        XCTAssertEqual(game.displayName(of: 2), "번개")
    }

    // MARK: 경주 진행

    func test_startRace_말_수만큼_기록_생성() {
        _ = game.increaseHorseCount()
        _ = game.increaseHorseCount()

        game.startRace()

        XCTAssertEqual(game.mode, .firstGame)
        XCTAssertEqual(game.resultInfo.count, 4)
        XCTAssertTrue(game.resultInfo.allSatisfy { (60.0...120.0).contains($0) })
    }

    func test_startRace_다시하면_기록을_새로_생성() {
        for _ in GameConfig.minHorseCount..<GameConfig.maxHorseCount {
            _ = game.increaseHorseCount()
        }
        game.startRace()
        let first = game.resultInfo

        game.restart()
        game.startRace()

        // 10개의 랜덤 값이 전부 같을 확률은 사실상 0
        XCTAssertNotEqual(game.resultInfo, first)
    }

    func test_경주_흐름_모드_전환() {
        game.startRace()
        XCTAssertEqual(game.mode, .firstGame)

        game.finishFirstRound()
        XCTAssertEqual(game.mode, .lastGame)

        game.finishRace()
        XCTAssertEqual(game.mode, .rank)

        game.restart()
        XCTAssertEqual(game.mode, .gameStart)
    }

    // MARK: 경기 기록

    func test_finishRace_경기_기록_저장() {
        game.startRace()
        game.finishFirstRound()
        game.finishRace()

        XCTAssertEqual(recordStore.records.count, 1)
        XCTAssertEqual(recordStore.records[0].ranking.count, game.horseCount)
    }

    func test_makeRecord_빠른순_이름과_벌칙() {
        game.horseNames[0] = "번개"
        for _ in 0..<2 { _ = game.increaseHorseCount() }
        game.penalty = "커피 쏘기"
        game.penaltyTarget = .last
        game.startRace()

        let record = game.makeRecord()

        XCTAssertEqual(record.ranking.map(\.second), record.ranking.map(\.second).sorted())
        XCTAssertTrue(record.ranking.contains { $0.name == "번개" })
        XCTAssertTrue(record.ranking.contains { $0.name == "2번마" })
        XCTAssertEqual(record.penalty, "커피 쏘기")
        XCTAssertEqual(record.penaltyRankIndex, 3)
        XCTAssertEqual(record.penaltyName, record.ranking[3].name)
        XCTAssertEqual(record.winnerName, record.ranking[0].name)
    }

    func test_makeRecord_벌칙이_없으면_nil() {
        game.penalty = "   "
        game.startRace()

        let record = game.makeRecord()

        XCTAssertNil(record.penalty)
        XCTAssertNil(record.penaltyRankIndex)
        XCTAssertNil(record.penaltyName)
    }

    func test_restart_입력한_이름은_유지() {
        game.horseNames[0] = "번개"
        game.startRace()

        game.restart()

        XCTAssertEqual(game.horseNames[0], "번개")
    }
    
    // MARK: 벌칙
    
    func test_벌칙_기본값은_없음_꼴등() {
        XCTAssertFalse(game.hasPenalty)
        XCTAssertEqual(game.penaltyTarget, .last)
    }
    
    func test_벌칙_공백만_입력하면_없는것으로_봄() {
        game.penalty = "   "
        
        XCTAssertFalse(game.hasPenalty)
    }
    
    func test_벌칙_최대_길이까지만_입력됨() {
        game.penalty = String(repeating: "가", count: GameConfig.maxPenaltyLength + 5)
        
        XCTAssertEqual(game.penalty.count, GameConfig.maxPenaltyLength)
    }
    
    func test_restart_벌칙은_유지() {
        game.penalty = "커피 쏘기"
        game.penaltyTarget = .first
        game.startRace()
        
        game.restart()
        
        XCTAssertEqual(game.penalty, "커피 쏘기")
        XCTAssertEqual(game.penaltyTarget, .first)
    }
}

// MARK: - PenaltyTarget

final class PenaltyTargetTests: XCTestCase {
    
    func test_rankIndex_꼴등은_마지막_순위() {
        XCTAssertEqual(PenaltyTarget.last.rankIndex(horseCount: 10), 9)
        XCTAssertEqual(PenaltyTarget.last.rankIndex(horseCount: 2), 1)
    }
    
    func test_rankIndex_1등은_첫번째_순위() {
        XCTAssertEqual(PenaltyTarget.first.rankIndex(horseCount: 10), 0)
    }
}

// MARK: - AppSetting

final class AppSettingTests: XCTestCase {
    
    private let keys = [AppSetting.bgmKey, AppSetting.effectSoundKey, AppSetting.hapticKey]
    private var savedValues: [String: Any] = [:]
    
    override func setUp() {
        super.setUp()
        // 시뮬레이터에 저장된 실제 설정 값을 보관했다가 테스트 후 복원
        for key in keys {
            savedValues[key] = UserDefaults.standard.object(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    override func tearDown() {
        for key in keys {
            UserDefaults.standard.set(savedValues[key], forKey: key)
        }
        super.tearDown()
    }
    
    func test_저장된_값이_없으면_모두_켜짐() {
        XCTAssertTrue(AppSetting.isBGMOn)
        XCTAssertTrue(AppSetting.isEffectSoundOn)
        XCTAssertTrue(AppSetting.isHapticOn)
    }
    
    func test_배경음악과_효과음은_각각_설정을_따름() {
        UserDefaults.standard.set(false, forKey: AppSetting.bgmKey)
        
        XCTAssertFalse(Sound.bgm.isEnabled)
        XCTAssertTrue(Sound.startButton.isEnabled)
        
        UserDefaults.standard.set(true, forKey: AppSetting.bgmKey)
        UserDefaults.standard.set(false, forKey: AppSetting.effectSoundKey)
        
        XCTAssertTrue(Sound.bgm.isEnabled)
        XCTAssertFalse(Sound.horseGallop.isEnabled)
    }
}

// MARK: - RaceRecordStore

final class RaceRecordStoreTests: XCTestCase {

    private let suiteName = "RaceRecordStoreTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suiteName)
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeRecord(_ name: String) -> RaceRecord {
        RaceRecord(date: Date(), ranking: [.init(name: name, second: 1.5)], penalty: nil, penaltyRankIndex: nil)
    }

    func test_add_최신_기록이_맨_앞() {
        let store = RaceRecordStore(defaults: defaults)

        store.add(makeRecord("첫번째"))
        store.add(makeRecord("두번째"))

        XCTAssertEqual(store.records.map(\.winnerName), ["두번째", "첫번째"])
    }

    func test_add_최대_개수를_넘으면_오래된_기록부터_삭제() {
        let store = RaceRecordStore(defaults: defaults)

        for i in 0..<(RaceRecordStore.maxCount + 3) {
            store.add(makeRecord("\(i)"))
        }

        XCTAssertEqual(store.records.count, RaceRecordStore.maxCount)
        XCTAssertEqual(store.records.first?.winnerName, "\(RaceRecordStore.maxCount + 2)")
        XCTAssertEqual(store.records.last?.winnerName, "3")
    }

    func test_저장한_기록은_다시_불러와도_유지() {
        let record = makeRecord("번개")
        RaceRecordStore(defaults: defaults).add(record)

        let reloaded = RaceRecordStore(defaults: defaults)

        XCTAssertEqual(reloaded.records, [record])
    }

    func test_removeAll_기록_전체_삭제() {
        let store = RaceRecordStore(defaults: defaults)
        store.add(makeRecord("번개"))

        store.removeAll()

        XCTAssertTrue(store.records.isEmpty)
        XCTAssertTrue(RaceRecordStore(defaults: defaults).records.isEmpty)
    }
}
