//
//  SettingView.swift
//  HorseRace
//
//  Created by Hong jeongmin on 2026/10/16.
//

import SwiftUI

// UserDefaults에 저장되는 설정 값 (저장된 값이 없으면 모두 켜짐)
enum AppSetting {
    static let bgmKey = "isBGMOn"
    static let effectSoundKey = "isEffectSoundOn"
    static let hapticKey = "isHapticOn"

    static var isBGMOn: Bool { value(forKey: bgmKey) }
    static var isEffectSoundOn: Bool { value(forKey: effectSoundKey) }
    static var isHapticOn: Bool { value(forKey: hapticKey) }

    private static func value(forKey key: String) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }
}

// 시작 화면 위에 띄우는 설정 창
struct SettingView: View {
    @Binding var isPresented: Bool

    @AppStorage(AppSetting.bgmKey) private var isBGMOn = true
    @AppStorage(AppSetting.effectSoundKey) private var isEffectSoundOn = true
    @AppStorage(AppSetting.hapticKey) private var isHapticOn = true

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 16) {
                HStack {
                    Text("설정")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(Color("startBtnColor"))
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.bold())
                            .foregroundColor(Color("startBtnColor"))
                    }
                }

                settingToggle("배경음악", isOn: $isBGMOn)
                settingToggle("효과음", isOn: $isEffectSoundOn)
                settingToggle("진동", isOn: $isHapticOn)
            }
            .padding(24)
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color("bgColor"))
            )
        }
        .onChange(of: isBGMOn) { _ in
            SoundSetting.shared.updateBGM()
            playFeedback()
        }
        .onChange(of: isEffectSoundOn) { _ in playFeedback() }
        .onChange(of: isHapticOn) { _ in playFeedback() }
    }

    private func settingToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Color("startBtnColor"))
        }
        .tint(Color("startBtnColor"))
    }

    // 바뀐 설정이 반영된 상태로 재생 (끈 항목은 울리지 않음)
    private func playFeedback() {
        SoundSetting.shared.play(.change)
        Haptic.light.play()
    }
}
