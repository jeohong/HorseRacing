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
        // 1라운드 진행 타임라인, 화면이 사라지면 자동으로 취소됨
        .task {
            do {
                // 3 -> 2 -> 1 -> Start!
                for _ in 0..<3 {
                    try await Task.sleep(seconds: 1)
                    countDown()
                }
                // Start! 와 동시에 말 출발 (Scene도 3초 후 출발)
                SoundSetting.shared.play(.horseGallop)
                
                try await Task.sleep(seconds: 1)
                countDown() // Start! 문구 숨김
                
                try await Task.sleep(seconds: 7)
                game.finishFirstRound()
            } catch {
                // 취소됨
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
    
    private let horseCount: Int
    private var horseArray: [SKSpriteNode] = []
    
    private let horseStartX: CGFloat = 150
    // 1라운드가 끝날 때(11초) 말들이 화면 오른쪽 끝에 도착하도록 설계된 기준 화면 너비
    private let baseScreenWidth: CGFloat = 844
    
    private var start = false
    private var lastUpdateTime: TimeInterval?
    
    let gameCountdownSound = SKAction.playSoundFileNamed("gameCountdownSound.m4a", waitForCompletion: false)
    
    init(size: CGSize, horseCount: Int) {
        self.horseCount = horseCount
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        // 다리 애니메이션은 출발(3초) 직후부터
        for i in 1...horseCount {
            let horseNode = HorseNode.make(number: i, horseCount: horseCount, x: frame.minX + horseStartX, runDelay: 3.1)
            horseArray.append(horseNode)
            addChild(horseNode)
        }
        
        // 처음 시작 카운트다운 사운드 재생
        run(gameCountdownSound)
        
        // 3초 이후 배경 및 horse 이동
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run { [weak self] in self?.start = true }
        ]))
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
            // 기준 화면에서는 기존과 같은 random(-3...6), 앞으로 가는 평균 속도만 화면 너비에 비례
            let forwardScale = (size.width - horseStartX) / (baseScreenWidth - horseStartX)
            for horse in horseArray {
                horse.position.x += (1.5 * forwardScale + CGFloat.random(in: -4.5...4.5)) * frameScale
            }
        }
    }
}
