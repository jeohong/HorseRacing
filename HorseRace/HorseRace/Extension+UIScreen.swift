//
//  Extension+UIScreen.swift
//  HorseRace
//
//  Created by Hong jeongmin on 2026/10/16.
//

import UIKit

extension UIScreen {
    /// UIScreen.main(deprecated 예정) 대신 현재 window scene의 화면
    static var current: UIScreen {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = windowScenes.first { $0.activationState == .foregroundActive } ?? windowScenes.first
        // 앱 실행 후에는 항상 window scene이 있으므로 fallback은 실행되지 않음
        return activeScene?.screen ?? .main
    }
}
