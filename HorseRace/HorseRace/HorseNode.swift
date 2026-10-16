//
//  HorseNode.swift
//  HorseRace
//
//  Created by Hong jeongmin on 2026/10/16.
//

import SpriteKit
import UIKit

// 1라운드, 최종 라운드 Scene이 공통으로 쓰는 말 노드 생성
enum HorseNode {
    private static let size = CGSize(width: 188, height: 106)
    private static let legSpeed: Double = 40  // 다리 움직임 속도 (초당 프레임 수)

    /// - Parameters:
    ///   - number: 말 번호 (1부터 시작)
    ///   - horseCount: 전체 말 수 (세로 위치 계산용)
    ///   - x: 시작 x 위치
    ///   - runDelay: 다리 애니메이션 시작 전 대기 시간
    static func make(number: Int, horseCount: Int, x: CGFloat, runDelay: TimeInterval = 0) -> SKSpriteNode {
        let atlas = SKTextureAtlas(named: "horse\(number)Images")
        let runFrames = (1...atlas.textureNames.count).map {
            atlas.textureNamed("horse\(number)-\($0)")
        }

        let horseNode = SKSpriteNode(texture: runFrames[Int.random(in: 3...5)])
        horseNode.position = CGPoint(x: x, y: UIScreen.main.bounds.height / CGFloat(horseCount + 3) * CGFloat(number))
        horseNode.zPosition = -CGFloat(number)  // 위에 있는 말이 뒤로 가도록 zPosition 지정 필요
        horseNode.size = size

        let runningAction = SKAction.repeatForever(SKAction.animate(with: runFrames, timePerFrame: 1 / legSpeed))
        horseNode.run(SKAction.sequence([SKAction.wait(forDuration: runDelay), runningAction]),
                      withKey: "horse\(number)Running")

        return horseNode
    }
}
