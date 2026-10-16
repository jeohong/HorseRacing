//
//  FinalGameProcessingView.swift
//  HorseRace
//
//  Created by LeeChangHyeong on 2022/08/23.
//

import SwiftUI
import SpriteKit

struct FinalGameProcessingView: View {
    @ObservedObject var game: GameState
    // 화면이 다시 그려져도 Scene은 처음 한 번만 생성
    @StateObject private var scene: FinalHorseRunningScene
    
    init(game: GameState) {
        self.game = game
        _scene = StateObject(wrappedValue: FinalHorseRunningScene(size: UIScreen.current.bounds.size, horseCount: game.horseCount, randomSecond: game.resultInfo))
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
        }
        // 화면이 사라지면 자동으로 취소됨
        .task {
            Haptic.medium.play()
            SoundSetting.shared.play(.horseGallop)
            let isFinished = (try? await Task.sleep(seconds: 2.5)) != nil
            SoundSetting.shared.stop(.horseGallop)
            
            if isFinished {
                game.finishRace()
            }
        }
    }
}

class FinalHorseRunningScene: SKScene, ObservableObject {
    
    let backgroundFinish = SKSpriteNode(imageNamed: "backgroundFinish")
    private let horseCount: Int
    private let randomSecond: [Double]
    private var horseArray: [SKSpriteNode] = []
    private var lastUpdateTime: TimeInterval?
    
    init(size: CGSize, horseCount: Int, randomSecond: [Double]) {
        self.horseCount = horseCount
        self.randomSecond = randomSecond
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        // 배경 크기 조절
        backgroundFinish.anchorPoint = CGPoint.zero
        backgroundFinish.size = size
        backgroundFinish.zPosition = -10
        addChild(backgroundFinish)
        
        for i in 1...horseCount {
            let horseNode = HorseNode.make(number: i, horseCount: horseCount, sceneHeight: size.height, x: frame.minX - 10)
            horseArray.append(horseNode)
            addChild(horseNode)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard let lastUpdateTime = lastUpdateTime else { return }
        // 60fps 기준 1프레임 = 1.0 (120Hz 기기에서도 같은 속도로 이동)
        let frameScale = CGFloat(min(currentTime - lastUpdateTime, 0.1)) * 60
        
        // 60에서 180사이
        for (i, horse) in horseArray.enumerated() {
            horse.position.x += CGFloat(size.width / CGFloat(randomSecond[i])) * frameScale
        }
    }
}
