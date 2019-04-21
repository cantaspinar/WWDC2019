import UIKit
import SceneKit
import SpriteKit

public class HUD: SKScene {
    
    var timerNode: SKLabelNode!
    var scoreNode: SKLabelNode!

    var findPlaneNode: SKLabelNode!
    var placeGardenNode: SKLabelNode!
    
    var score = 0 {
        didSet {
            self.scoreNode.text = "Score: \(self.score)"
        }
    }
    
    var timer = 0 {
        didSet {
            self.timerNode.text = "Time: \(self.timer)"
        }
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        for node in self.children{
            let newPosition = CGPoint(x:node.position.x / oldSize.width * self.frame.size.width,y:node.position.y / oldSize.height * self.frame.size.height)
            node.position = newPosition
        }
    }
    
    public override init(size: CGSize) {
        super.init(size: size)
        
        self.isUserInteractionEnabled = false
        self.backgroundColor = UIColor.clear
        self.scene?.scaleMode = .resizeFill
        
        self.findPlaneNode = SKLabelNode(text: "MOVE AROUND TO FIND A SURFACE")
        self.findPlaneNode.fontName = "DINAlternate-Bold"
        self.findPlaneNode.fontColor = UIColor.white
        self.findPlaneNode.fontSize = 23
        self.findPlaneNode.position = CGPoint(x:  size.width/2, y:  64)
        
        self.placeGardenNode = SKLabelNode(text: "TOUCH TO PLACE THE GARDEN")
        self.placeGardenNode.fontName = "DINAlternate-Bold"
        self.placeGardenNode.fontColor = UIColor.white
        self.placeGardenNode.fontSize = 24
        self.placeGardenNode.position = CGPoint(x:  size.width/2, y:  64)
        
        self.timerNode = SKLabelNode(text: "Time: X")
        self.timerNode.fontName = "DINAlternate-Bold"
        self.timerNode.fontColor = UIColor.white
        self.timerNode.fontSize = 24
        self.timerNode.position = CGPoint(x:  128, y:  32)
        
        self.scoreNode = SKLabelNode(text: "Score: 0")
        self.scoreNode.fontName = "DINAlternate-Bold"
        self.scoreNode.fontColor = UIColor.white
        self.scoreNode.fontSize = 24
        self.scoreNode.position = CGPoint(x: (size.width-128), y: 32)
        
        self.addChild(self.timerNode)
        self.addChild(self.scoreNode)
        self.addChild(self.findPlaneNode)
        self.addChild(self.placeGardenNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
