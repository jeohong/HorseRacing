//
//  ResultView.swift
//  HorseRace
//
//  Created by 김예훈 on 2022/08/27.
//

import SwiftUI
import SpriteKit
import LinkPresentation

struct ResultView: View {
    @ObservedObject var game: GameState
    
    typealias RankingInfo = RaceRanking.Entry
    @State private var capsuleWidth: CGFloat = .zero
    @State private var circleWidth: CGFloat = .zero
    // 공유 이미지 캡처 중 여부 (캡처하는 동안 버튼 숨김)
    @State private var isCapturing = false
    // 화면이 다시 그려져도 Scene은 처음 한 번만 생성
    @StateObject private var particleScene = EndParticlesScene(size: UIScreen.current.bounds.size)
    
    init(game: GameState) {
        self.game = game
        let entries = RaceRanking.entries(from: game.resultInfo)
        self.rankingInfo = entries
        self.preciseIndices = RaceRanking.preciseIndices(of: entries)
        self.penaltyIndex = game.hasPenalty ? game.penaltyTarget.rankIndex(horseCount: entries.count) : nil
    }
    
    private let rankingInfo: [RankingInfo]
    private let preciseIndices: Set<Int>
    // 벌칙을 받는 순위 인덱스 (벌칙이 없으면 nil)
    private let penaltyIndex: Int?
    
    private var columnCount: Int {
        (rankingInfo.count < 4) ? 1 : 2
    }
    
    var body: some View {
        ZStack {
            Color("bgColor")
                .ignoresSafeArea()
            
            // spriteKit view
            SpriteView(scene: particleScene, options: [.allowsTransparency])
            
            VStack(spacing: 12) {
                Image("Ranking")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 148)
                    // 벌칙 문구는 제목 오른쪽 빈 공간에 (세로 공간을 쓰지 않도록)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        if let penaltyIndex = penaltyIndex {
                            HStack(spacing: 0) {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                                Color.clear
                                    .frame(width: 148)
                                Text("벌칙: \(game.penalty)\n→ \(game.displayName(of: rankingInfo[penaltyIndex].horseNum))")
                                    .font(.subheadline.bold())
                                    .multilineTextAlignment(.trailing)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.6)
                                    .foregroundColor(Color("penaltyColor"))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        ForEach(0..<columnCount, id: \.self) { _ in
                            HStack(spacing: 15) {
                                Text("등수")
                                    .foregroundColor(.black)
                                    .font(.footnote.bold())
                                    .frame(width: circleWidth)
                                
                                HStack {
                                    Text("경주마")
                                        .foregroundColor(.black)
                                        .font(.footnote.bold())
                                        .frame(maxWidth: .infinity)
                                    
                                    Text("걸린시간")
                                        .foregroundColor(.black)
                                        .font(.footnote.bold())
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(width: capsuleWidth)
                            }
                        }
                    }
                    
                    RankingGridView(num: rankingInfo.count, rankingInfo: rankingInfo) { (ranking, num, second) in
                        HStack(spacing: 15) {
                            Circle()
                                .fill(Color.white)
                                .frame(maxHeight: 65)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Text("\(ranking+1)")
                                        .foregroundColor(.black)
                                        .font(.title2.bold())
                                )
                                .modifier(SizeModifier())
                                .onPreferenceChange(SizePreferenceKey.self) { size in
                                    circleWidth = size.width
                                }

                            HStack(spacing: 0) {
                                Image("horse\(num+1)\(rankingInfo.count < 4 ? "byOne" : "byTwo")")
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(Capsule())

                                Spacer()

                                HStack(spacing: 0) {
                                    Text(game.displayName(of: num))
                                        .bold()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                        .foregroundColor(Color("startBtnColor"))

                                    Spacer()

                                    Text(RaceRanking.formatTime(second, precise: preciseIndices.contains(ranking)))
                                        .font(preciseIndices.contains(ranking) ? .caption : .subheadline)
                                        .bold()
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .foregroundColor(Color("startBtnColor"))
                                        .padding(.trailing, 30)
                                        .frame(width: 100)

                                }
                            }
                            .frame(minWidth: 180, maxWidth: 280, maxHeight: 65)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .modifier(SizeModifier())
                                    .onPreferenceChange(SizePreferenceKey.self) { size in
                                        capsuleWidth = size.width
                                    }
                            )
                            // 벌칙 받는 말 강조
                            .overlay(
                                Capsule()
                                    .stroke(Color("penaltyColor"), lineWidth: 3)
                                    .opacity(ranking == penaltyIndex ? 1 : 0)
                            )
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button {
                        Haptic.light.play()
                        shareResult()
                    } label: {
                        buttonLabel("공유하기")
                    }
                    .buttonStyle(.plain)
                    .disabled(isCapturing)

                    Button {
                        withAnimation(.spring()) {
                            SoundSetting.shared.play(.startButton)
                            Haptic.light.play()
                            game.restart()
                        }
                    } label: {
                        buttonLabel("다시하기")
                    }
                    .buttonStyle(.plain)
                }
                // 공유 이미지에 버튼이 찍히지 않도록 캡처하는 동안만 숨김
                .opacity(isCapturing ? 0 : 1)

            }
            .padding(.horizontal, 60)
            .padding(.vertical, 38)
        }
        .ignoresSafeArea()
        .onAppear {
            Haptic.success.play()
        }
    }

    private func buttonLabel(_ title: String) -> some View {
        Text(title)
            .font(.body.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color("startBtnColor"))
            )
    }

    // iOS 15 지원을 위해 ImageRenderer/ShareLink 대신 window 캡처 + UIActivityViewController 사용
    private func shareResult() {
        isCapturing = true
        Task { @MainActor in
            // 버튼이 숨겨진 화면이 그려진 뒤 캡처
            await Task.yield()
            defer { isCapturing = false }
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow),
                  let rootViewController = window.rootViewController else { return }

            let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }

            let activityViewController = UIActivityViewController(activityItems: [ShareImageItem(image: image, title: "내가사마 경주 결과")],
                                                                  applicationActivities: nil)
            // iPad에서는 popover 기준 위치가 없으면 크래시
            activityViewController.popoverPresentationController?.sourceView = window
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.maxY, width: 0, height: 0)

            var presenter = rootViewController
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            presenter.present(activityViewController, animated: true)
        }
    }

    struct RankingGridView<ItemView: View>: View {
        
        var num: Int
        var rankingInfo: [RankingInfo]
        let content: (Int, Int, Double) -> ItemView

        init(num: Int, rankingInfo: [RankingInfo], @ViewBuilder content: @escaping (Int, Int, Double) -> ItemView) {
            self.num = num
            self.content = content
            self.rankingInfo = rankingInfo
        }
        
        private var leftCount: Int { (num + 1) / 2 }
        private var rightCount: Int { num - leftCount }
        private var needsPlaceholder: Bool { num >= 4 && rightCount < leftCount }

        var body: some View {
            if num < 4 {
                VStack(spacing: 15) {
                    ForEach(0..<num, id: \.self) { i in
                        content(i, rankingInfo[i].horseNum, rankingInfo[i].second)
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: num == 4 ? 15 : 8) {
                        ForEach(0..<leftCount, id: \.self) { i in
                            content(i, rankingInfo[i].horseNum, rankingInfo[i].second)
                        }
                    }
                    VStack(spacing: num == 4 ? 15 : 8) {
                        ForEach(leftCount..<num, id: \.self) { i in
                            content(i, rankingInfo[i].horseNum, rankingInfo[i].second)
                        }
                        if needsPlaceholder {
                            content(0, rankingInfo[0].horseNum, rankingInfo[0].second)
                                .opacity(0)
                        }
                    }
                }
                .padding(num == 4 ? [.bottom, .vertical] : [], num == 4 ? 16 : 0)
            }
        }
    }
}

// 공유창 상단 미리보기에 결과 이미지와 제목이 보이도록 메타데이터 제공
private final class ShareImageItem: NSObject, UIActivityItemSource {
    private let image: UIImage
    private let title: String

    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct SizeModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
        }
    }
    
    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}
