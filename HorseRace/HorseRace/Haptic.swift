//
//  Haptic.swift
//  HorseRace
//
//  Created by Hong jeongmin on 2026/10/16.
//

import UIKit

enum Haptic {
    case light    // 버튼 탭, 카운트다운 숫자
    case medium   // 최종 라운드 돌입
    case heavy    // 출발
    case success  // 결과 발표
    case warning  // 말 수 최소/최대 도달

    // generator를 매번 만들지 않고 재사용 (만들 때마다 Taptic Engine 준비 지연이 생김)
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    func play() {
        guard AppSetting.isHapticOn else { return }
        switch self {
        case .light: Self.lightGenerator.impactOccurred()
        case .medium: Self.mediumGenerator.impactOccurred()
        case .heavy: Self.heavyGenerator.impactOccurred()
        case .success: Self.notificationGenerator.notificationOccurred(.success)
        case .warning: Self.notificationGenerator.notificationOccurred(.warning)
        }
    }
}
