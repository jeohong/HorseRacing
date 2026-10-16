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

    override func setUp() {
        super.setUp()
        game = GameState()
    }

    override func tearDown() {
        game = nil
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

    func test_restart_입력한_이름은_유지() {
        game.horseNames[0] = "번개"
        game.startRace()

        game.restart()

        XCTAssertEqual(game.horseNames[0], "번개")
    }
}
