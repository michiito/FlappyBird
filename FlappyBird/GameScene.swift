//
//  GameScane.swift
//  FlappyBird
//
//  Created by 伊藤倫 on 2020/06/17.
//  Copyright © 2020 michi.ito. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {

    
        var scrollNode:SKNode!
        var wallNode:SKNode!
        var coinNode:SKNode!  //課題
        var bird:SKSpriteNode!
        
    
        let birdCategory: UInt32 = 1 << 0     //0...00001
        let groundCategory: UInt32 = 1 << 1     //0...00010
        let wallCategory: UInt32 = 1 << 2     //0...00100
        let scoreCategory: UInt32 = 1 << 3      // 0...01000    //スコア用
        let coinCategory: UInt32 = 1 << 4     //課題用
    
    var score = 0
    var score1 = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var score1LabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    //課題用　効果音系
    let action = SKAction.playSoundFileNamed("bird_sound.mp3", waitForCompletion: true)
    
    //SKView上にシーンが表示された時に呼ばれるメゾット
        override func didMove(to view:SKView){
            
            //重力を設定
            physicsWorld.gravity = CGVector(dx: 0, dy: -4)
            physicsWorld.contactDelegate = self
            
            //背景色を設定
            backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
            
            //スクロールするスプライドの親ノード
            scrollNode = SKNode()
            addChild(scrollNode)
            
            //壁用のノード
            wallNode = SKNode()
            scrollNode.addChild(wallNode)
            
            //コイン用のノード
            coinNode = SKNode()
            scrollNode.addChild(coinNode)
            
            //各種スプライドを生成する処理をメゾットに分割
            setupGround()
            setupCloud()
            setupWall()
            setupCoin()  //課題用
            setupBird()
          
            
            setupScoreLabel()
    }
    func setupGround(){
            //地面の画像読み込み
            let groundTexture = SKTexture(imageNamed: "ground")
            groundTexture.filteringMode = .nearest
            
            //必要な枚数を計算
            let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
            
            // スクロールするアクションを作成
            // 左方向に画像一枚分スクロールさせるアクション
            let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5)
        print(-groundTexture.size().width)
            //元の位置に戻すアクション
            let resetGround = SKAction.moveBy(x: groundTexture.size().width , y: 0, duration: 0)
            
            // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
            let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
            
            //groundのスプライトを配置する
            for i in 0..<needNumber {
                let sprite = SKSpriteNode(texture: groundTexture)
                
                //スプライトの表示する位置を指定する
                sprite.position = CGPoint(
                    x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                    y: groundTexture.size().height / 2
                )
                //スプライトにアクションを追加する
                sprite.run(repeatScrollGround)
                
                //スプライトに物理演算を設定する
                sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
                
                //衝突のカテゴリー設定
                sprite.physicsBody?.categoryBitMask = groundCategory
                
                //衝突の際に動かないように設定する
                sprite.physicsBody?.isDynamic = false
                
                //スプライトを追加する
                scrollNode.addChild(sprite)
            }
        
        }
    
    func setupCloud() {
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0, duration: 20)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール、元の位置、左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろになるようにする
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            //スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    func setupWall(){
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //画面がいあで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //２つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜けられる隙間のサイズを三倍とする
        let slit_length = birdSize.height * 3
        
        //隙間位置の上下の振れ幅を鳥のサイズの三倍とする
        let random_y_range = birdSize.height * 3
        
        //下の壁のY軸下限位置（中央位置から下方向までの最大振れ幅で下の壁を表示する位置）を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            //壁関連のノードを載せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50
            
            //0〜random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            //Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            //下の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の際に動かないようにする
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の際に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //スコアUP用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        //次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 1.9)
        
        //壁を作成ー時間待ちー壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
        
    }
    
    //課題用
    func setupCoin() {
        //コインの画像を読み込む
        let coinTexture = SKTexture(imageNamed: "coin")
        coinTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + coinTexture.size().width)
        //画面外まで移動するアクションを作成
        let moveCoin = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        //自身を取り除くアクションを作成
        let removeCoin = SKAction.removeFromParent()
        //二つのアニメーションを順に実行するアクションを作成
        let coinAnimation = SKAction.sequence([moveCoin, removeCoin])

        
        //コインの移動位置の上限
        let random_y_range_up = self.frame.size.height / 1.5
        
        //コインの移動位置の下限
        let random_y_range_low = self.frame.size.height / 2.5
        //ここで壁は下の壁のY軸下限位置を計算しているが、今回は割愛
        
        //コインを生成するアクションを作成
        let createCoinAnimation = SKAction.run({
            //コイン関係のノードを載せるノードを作成
            let coin = SKNode()
            //コインのx軸y軸の設定方法が分からないので、我部の数値を代用。除数は数字を変更。(2->4)
            coin.position = CGPoint(x: self.frame.size.width + coinTexture.size().width / 2, y: 0)
            coin.zPosition = -50
            
            //0〜random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: random_y_range_low..<random_y_range_up)
            //ここで壁は下の壁のY座標を決定しているが、今回は明確なY座標はいらないので割愛
            
            //コインを作成
            let coin1 = SKSpriteNode(texture: coinTexture)
            coin1.position = CGPoint(x: 0, y:random_y)
            
             //物理演算を設定
            coin1.physicsBody = SKPhysicsBody(circleOfRadius: coin1.size.height / 2)
            coin1.physicsBody?.affectedByGravity = false
            coin1.physicsBody?.categoryBitMask = self.coinCategory
            coin1.physicsBody?.contactTestBitMask = self.birdCategory
            
            
            coin.addChild(coin1)
            coin.run(coinAnimation)
            self.coinNode.addChild(coin)
        })
        //次のコイン作成ませの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2.4)
        //コイン作成->時間待ち->コイン作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createCoinAnimation, waitAnimation]))
        
       
        
        coinNode.run(repeatForeverAnimation)
    }

    
    func setupBird() {
        //鳥の画像を二種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //二種類のテスクチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
        
    }
    
    
    
    
    
    
    
    //画面をタップした際に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        if scrollNode.speed > 0{
        //鳥の速度をゼロにする
              bird.physicsBody?.velocity = CGVector.zero
        
        //鳥に縦方向の力を与える
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
    }else if bird.speed == 0{
            restart()
    }
    }
    //SKPhysicsContactDelegateのメゾット。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
         
        //ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        }else if (contact.bodyA.categoryBitMask & coinCategory) == coinCategory {
            //課題用　衝突したらコインが消える
            contact.bodyA.node?.removeFromParent()
            score1 += 1
            score1LabelNode.text = "ItemScore\(score1)"
            self.run(action)
            
        }else if (contact.bodyB.categoryBitMask & coinCategory) == coinCategory{
            //課題用　衝突したらコインが消える
            contact.bodyB.node?.removeFromParent()
            score1 += 1
            score1LabelNode.text = "ItemScore\(score1)"
            self.run(action)
        }else{
            //壁か地面と衝突した
            print("GameOver")
            
            //スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
                
            })
        }
    }
    func restart() {
        score = 0
        score1 = 0
        scoreLabelNode.text = "Score:\(score)"
        score1LabelNode.text = "ItemScore\(score1)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 //一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100//1番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        //課題用
        score1LabelNode = SKLabelNode()
        score1LabelNode.fontColor = UIColor.black
        score1LabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        score1LabelNode.zPosition = 100
        score1LabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        score1LabelNode.text = "ItemScore:\(score1)"
        self.addChild(score1LabelNode)
        
        
    }

  
}
    

 

