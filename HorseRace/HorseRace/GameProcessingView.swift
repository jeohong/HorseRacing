//
//  GameProcessingView.swift
//  HorseRace
//
//  Created by DongKyu Kim on 2022/08/22.
//

import SwiftUI
import SpriteKit

struct GameProcessingView: View {
    @ObservedObject var game: GameState
    // 화면이 다시 그려져도 Scene은 처음 한 번만 생성
    @StateObject private var scene: HorseRunningScene
    
    @State private var count = 3 // countDown 숫자
    @State private var animationAmount = -90.0
    
    init(game: GameState) {
        self.game = game
        // 말 마리수 반영해서 Scene 생성
        _scene = StateObject(wrappedValue: HorseRunningScene(size: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height), horseCount: game.horseCount))
    }
    
    var body: some View {
        
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            if count > 0 {
                numView
            } else if count == 0{
                startMessage
            }
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                SoundSetting.shared.play(.horseGallop)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
                game.finishFirstRound()
            }
        }
        // 1초마다 카운트다운, 화면이 사라지면 자동으로 취소됨
        .task {
            while count >= 0 {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
                countDown()
            }
        }
    }
    
    private var numView: some View {
        Text("\(count)")
            .font(.custom("Copperplate", size: 120))
            .foregroundColor(.white)
            .rotation3DEffect(.degrees(animationAmount), axis: (x: 1.0, y: 0.0, z: 0.01))
            .onAppear {
                withAnimation {
                    animationAmount += 90
                }
            }
    }
    
    private var startMessage: some View {
        Text("Start!")
            .font(.custom("Copperplate", size: 80))
            .foregroundColor(.white)
    }
    
    private func countDown() {
        animationAmount = -90
        withAnimation {
            count -= 1
            animationAmount += 90
        }
    }
}


// MARK: Horse Running Animation SpriteKit Scene
class HorseRunningScene: SKScene, ObservableObject {
    let backgroundStart = SKSpriteNode(imageNamed: "backgroundStart")
    let backgroundMiddle = SKSpriteNode(imageNamed: "backgroundMiddle")
    
    var horseCount: Int = Int.random(in: 2...6)  // 말 마리 수 받아오기
    
    private var horseArray: [SKSpriteNode?] = []
    private var horseRunningFrames: [SKTexture] = []
    
    private var start = false
    private var lastUpdateTime: TimeInterval?
    
    let gameCountdownSound = SKAction.playSoundFileNamed("gameCountdownSound.m4a", waitForCompletion: false)
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 말 마리 수를 받아 올 수 있는 initializer
    convenience init(size: CGSize, horseCount: Int) {
        self.init(size: size)
        self.horseCount = horseCount
    }
    
    override func didMove(to view: SKView) {
        backgroundStart.anchorPoint = CGPoint.zero
        backgroundStart.position = CGPoint.zero
        backgroundStart.zPosition = -10
        backgroundStart.size.height = frame.height
        addChild(backgroundStart)
        
        backgroundMiddle.anchorPoint = CGPoint.zero
        backgroundMiddle.position.x = backgroundStart.size.width
        backgroundMiddle.position.y = 0
        backgroundMiddle.zPosition = -10
        backgroundMiddle.size.height = frame.height
        addChild(backgroundMiddle)
        
        for i in 1...horseCount {
            buildHorse(number: i)
        }
        
        // 처음 시작 카운트다운 사운드 재생
        run(gameCountdownSound)
    }
    
    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard let lastUpdateTime = lastUpdateTime else { return }
        // 60fps 기준 1프레임 = 1.0 (120Hz 기기에서도 같은 속도로 이동)
        let frameScale = CGFloat(min(currentTime - lastUpdateTime, 0.1)) * 60
        
        let backgroundSpeed: CGFloat = 20 * frameScale
        
        if start {
            backgroundStart.position.x -= backgroundSpeed
            backgroundMiddle.position.x -= backgroundSpeed
            
            if backgroundMiddle.position.x + backgroundMiddle.size.width < UIScreen.main.bounds.size.width {
                // backgroundStart 뒷부분 다시 활용
                backgroundStart.position.x = backgroundMiddle.position.x
                backgroundMiddle.position.x += backgroundMiddle.size.width
            }
            // 말의 움직임 속도 (x축 이동)
            for horse in horseArray {
                horse?.position.x += CGFloat.random(in: -3...6) * frameScale
            }
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
            horseNode.position = CGPoint(x: frame.minX + 150, y: UIScreen.main.bounds.height / CGFloat((horseCount) + 3) * CGFloat(number))
            horseNode.zPosition = -CGFloat(number)  // 위에 있는 말이 뒤로 가도록 zPosition 지정 필요
            horseNode.size = CGSize(width: 188, height: 106)
            addChild(horseNode)
            
            // 3초 이후 배경 및 horse 이동
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.start = true
            }
            animateHorse(number: number, speed: horseSpeed)
        }
    }
    
    // horse 다리 애니메이션 동작, speed는 말의 다리 움직임 속도(
    func animateHorse(number: Int, speed: Double) {
        let timePerFrame = 1 / speed
        
        // 3초간 대기하는 Action
        let waiting = SKAction.wait(forDuration: 3.1)
        
        // 달리는 Action
        let runningAction = SKAction.repeatForever(SKAction.animate(with: horseRunningFrames,timePerFrame: timePerFrame)
        )
        
        // 앞의 두 Action을 순서대로 수행
        if let horseNode = horseArray[number-1] {
            horseNode.run(SKAction.sequence([waiting, runningAction]),
                          withKey: "horse\(number)Running"
            )
        }
    }
}
