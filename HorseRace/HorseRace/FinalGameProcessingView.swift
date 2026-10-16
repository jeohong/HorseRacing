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
        _scene = StateObject(wrappedValue: FinalHorseRunningScene(size: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height), horseCount: game.horseCount, randomSecond: game.resultInfo))
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
        }
        // 화면이 사라지면 자동으로 취소됨
        .task {
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
    private var horseArray: [SKSpriteNode?] = []
    var randomSecond: [Double] = []
    var getResult: () -> Void = {}
    private var lastUpdateTime: TimeInterval?
    
    private var horseRunningFrames: [SKTexture] = []
    var horseCount: Int = Int.random(in: 2...6)  // 말 마리 수 받아오기
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 말 마리 수를 받아 올 수 있는 initializer
    convenience init(size: CGSize, horseCount: Int, randomSecond: [Double]) {
        self.init(size: size)
        self.horseCount = horseCount
        self.randomSecond = randomSecond
    }
    
    override func didMove(to view: SKView) {
        // 배경 크기 조절
        backgroundFinish.anchorPoint = CGPoint.zero
        backgroundFinish.size.width = UIScreen.main.bounds.size.width
        backgroundFinish.size.height = UIScreen.main.bounds.size.height
        backgroundFinish.zPosition = -10
        addChild(backgroundFinish)
        
        for i in 1...horseCount {
            buildHorse(number: i)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard let lastUpdateTime = lastUpdateTime else { return }
        // 60fps 기준 1프레임 = 1.0 (120Hz 기기에서도 같은 속도로 이동)
        let frameScale = CGFloat(min(currentTime - lastUpdateTime, 0.1)) * 60
        
        // 60에서 180사이
        for (i, horse) in horseArray.enumerated() {
            horse?.position.x += CGFloat(UIScreen.main.bounds.size.width / CGFloat(randomSecond[i])) * frameScale
        }
    }
    
    // horse Atlas를 생성
    func buildHorse(number: Int) {
        let horseAnimatedAtlas = SKTextureAtlas(named: "horse\(number)Images")
        var runFrames: [SKTexture] = []
        
        let horseSpeed: Double = 40
        let numImages = horseAnimatedAtlas.textureNames.count
        
        for i in 1...numImages {
            let horseTextureName = "horse\(number)-\(i)"
            runFrames.append(horseAnimatedAtlas.textureNamed(horseTextureName))
        }
        horseRunningFrames = runFrames
        
        let firstFrameTexture = horseRunningFrames[Int.random(in: 3...5)]
        horseArray.append(SKSpriteNode(texture: firstFrameTexture))
        
        if let horseNode = horseArray[number-1] {
            horseNode.position = CGPoint(x: frame.minX - 10, y: UIScreen.main.bounds.height / CGFloat((horseCount) + 3) * CGFloat(number))
            
            horseNode.zPosition = -CGFloat(number)  // 위에 있는 말이 뒤로 가도록 zPosition 지정 필요
            horseNode.size = CGSize(width: 188, height: 106)
            addChild(horseNode)
            
            animateHorse(number: number, speed: horseSpeed)
        }
    }
    
    // horse 다리 애니메이션 동작, speed는 말의 다리 움직임 속도(
    func animateHorse(number: Int, speed: Double) {
        let timePerFrame = 1 / speed
        
        // 달리는 Action
        let runningAction = SKAction.repeatForever(SKAction.animate(with: horseRunningFrames,timePerFrame: timePerFrame)
        )
        
        // 앞의 두 Action을 순서대로 수행
        if let horseNode = horseArray[number-1] {
            horseNode.run(SKAction.sequence([runningAction]),
                          withKey: "horse\(number)Running"
            )
        }
    }
}
