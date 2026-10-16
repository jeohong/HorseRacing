//
//  Extension+Task.swift
//  HorseRace
//
//  Created by Hong jeongmin on 2026/10/16.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    /// 초 단위 sleep, Task가 취소되면 CancellationError를 던짐
    static func sleep(seconds: Double) async throws {
        try await sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
