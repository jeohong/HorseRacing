//
//  ResultView.swift
//  HorseRace
//
//  Created by 김예훈 on 2022/08/27.
//

import SwiftUI
import SpriteKit

struct ResultView: View {
    @ObservedObject var game: GameState
    
    typealias RankingInfo = RaceRanking.Entry
    @State private var capsuleWidth: CGFloat = .zero
    @State private var circleWidth: CGFloat = .zero
    
    init(game: GameState) {
        self.game = game
        let entries = RaceRanking.entries(from: game.resultInfo)
        self.rankingInfo = entries
        self.preciseIndices = RaceRanking.preciseIndices(of: entries)
    }
    
    private let rankingInfo: [RankingInfo]
    private let preciseIndices: Set<Int>
    
    private var columnCount: Int {
        (rankingInfo.count < 4) ? 1 : 2
    }
    
    private func isUnderLineDisabled(_ num: Int) -> Bool {
        let num = num + 1
        let count = rankingInfo.count
        if count < 4 {
            return num == count
        } else {
            let leftCount = (count + 1) / 2
            return num == leftCount || num == count
        }
    }
    
    private func isDashboardDisabled(_ num: Int) -> Bool {
        let num = num + 1
        let count = rankingInfo.count
        if count < 4 {
            return num == 1
        } else {
            let leftCount = (count + 1) / 2
            return num == 1 || num == leftCount + 1
        }
    }
    
    private static let numberWords = ["one", "two", "three", "four", "five", "six", "seven", "eight"]

    private func numString(_ num: Int) -> String {
        guard num >= 1, num <= Self.numberWords.count else { return "one" }
        return Self.numberWords[num - 1]
    }
    
    @State private var gridWidth: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(hex: "EBDCCC")
                .ignoresSafeArea()
            
            // spriteKit view
            SpriteView(scene: EndParticlesScene(size: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)), options: [.allowsTransparency])
            
            VStack(spacing: 12) {
                Image("Ranking")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 148)
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
                                        .foregroundColor(Color(hex: "481B15"))

                                    Spacer()

                                    Text(RaceRanking.formatTime(second, precise: preciseIndices.contains(ranking)))
                                        .font(preciseIndices.contains(ranking) ? .caption : .subheadline)
                                        .bold()
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .foregroundColor(Color(hex: "481B15"))
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
                        }
                    }
                }
                
                Button {
                    withAnimation(.spring()) {
                        SoundSetting.shared.play(.startButton)
                        game.restart()
                    }
                } label: {
                    Text("다시하기")
                        .font(.body.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hex: "481B15"))
                        )
                }
                .buttonStyle(.plain)
                
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 38)
        }
        .ignoresSafeArea()
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
