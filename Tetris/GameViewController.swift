//
//  GameViewController.swift
//  Tetris
//
//  Created by Mostafa Saleh on 8/2/17.
//  Copyright © 2017 Mostafa Saleh. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, GameControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    
    var scene: GameScene!
    var controller: GameController!
    var panPointReference:CGPoint?

    override func viewDidLoad() {
        super.viewDidLoad()
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        scene.tick = didTick
        
        controller = GameController()
        controller.delegate = self
        controller.beginGame()
        
        skView.presentScene(scene)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func didTick() {
        controller.letShapeFall()
    }
    
    func nextShape() {
        let newShapes = controller.newShape()
        guard let fallingShape = newShapes.fallingShape else {
            return
        }
        self.scene.addPreviewShapeToScene(shape: newShapes.nextShape!) {}
        self.scene.movePreviewShape(shape: fallingShape) {
            self.view.isUserInteractionEnabled = true
            self.scene.startTicking()
        }
    }
    
    func gameDidBegin(_ gameController: GameController) {
        levelLabel.text = "\(gameController.level)"
        scoreLabel.text = "\(gameController.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        // The following is false when restarting a new game
        if gameController.nextShape != nil && gameController.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(shape: gameController.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    func gameDidEnd(_ gameController: GameController) {
        view.isUserInteractionEnabled = false
        scene.stopTicking()
        scene.playSound(sound: "gameover.mp3")
        scene.animateCollapsingLines(linesToRemove: gameController.removeAllBlocks(), fallenBlocks: gameController.removeAllBlocks()) {
            gameController.beginGame()
        }
    }
    
    func gameDidLevelUp(_ gameController: GameController) {
        levelLabel.text = "\(gameController.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound(sound: "levelup.mp3")
    }
    
    func gameShapeDidDrop(_ gameController: GameController) {
        scene.stopTicking()
        scene.redrawShape(shape: gameController.fallingShape!) {
            gameController.letShapeFall()
        }
        scene.playSound(sound: "drop.mp3")
    }
    
    func gameShapeDidLand(_ gameController: GameController) {
        scene.stopTicking()
        self.view.isUserInteractionEnabled = false
        let removedLines = gameController.removeCompletedLines()
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(gameController.score)"
            scene.animateCollapsingLines(linesToRemove: removedLines.linesRemoved, fallenBlocks:removedLines.fallenBlocks) {
                // #11
                self.gameShapeDidLand(gameController)
            }
            scene.playSound(sound: "bomb.mp3")
        } else {
            nextShape()
        }    }
    
    func gameShapeDidMove(_ gameController: GameController) {
        scene.redrawShape(shape: gameController.fallingShape!) {}
    }
    
    
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        controller.rotateShape()
    }
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translation(in: self.view)
        if let originalPoint = panPointReference {
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
                if sender.velocity(in: self.view).x > CGFloat(0) {
                    controller.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    controller.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .began {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func didSwipe(_ sender: UISwipeGestureRecognizer) {
        controller.dropShape()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UISwipeGestureRecognizer {
            if otherGestureRecognizer is UIPanGestureRecognizer {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            if otherGestureRecognizer is UITapGestureRecognizer {
                return true
            }
        }
        return false
    }
}
