import UIKit
import SceneKit
import ARKit

public class GameViewController: UIViewController, ARSCNViewDelegate {
    
    // AR AND SCENE
    @IBOutlet var sceneView: ARSCNView!
    var placeholderNode: SCNNode?
    var foundSurface = false
    var tracking = true
    
    // NODES
    var planeNode:SCNNode!
    
    var holes:SCNNode!
    var environment:SCNNode!
    var controls:SCNNode!
    
    var startNode:SCNNode!
    var countdownTextNode: SCNNode!
    var restartNode:SCNNode!
    
    var holeNodes:[SCNNode] = []
    
    // GAME PREFS
    var sounds:[String:SCNAudioSource] = [:]
    var spawnTime:TimeInterval = 0
    var gameStarted = false
    var timer = 0
    var gameTime = 90
    var badMoleRate = 2
    var minSpawnRate: Float = 0.4
    var maxSpawnRate: Float = 0.8
    var moleStayTime: TimeInterval = 1.0
    
    // SPAWNABLES
    var moleNode:SCNNode!
    var badMoleNode:SCNNode!
    var spawnableHoleNodes:[SCNNode] = []
    var moles:[SCNNode] = []
    
    // PARTICLES
    var explosionGood:SCNParticleSystem!
    var explosionBad:SCNParticleSystem!
    
    // HUD
    var hud: HUD!
    
    func setupNodes(){
        
        // NODES
        planeNode = sceneView.scene.rootNode.childNode(withName: "plane", recursively: false)!
        
        holes = planeNode.childNode(withName: "holes", recursively: false)!
        environment = planeNode.childNode(withName: "environment", recursively: false)!
        controls = planeNode.childNode(withName: "controls", recursively: false)!
        
        startNode = controls.childNode(withName: "start", recursively: false)!
        countdownTextNode = controls.childNode(withName: "countdownText", recursively: false)!
        restartNode = controls.childNode(withName: "restart", recursively: false)!
        
        let startTextNode = startNode.childNode(withName: "text", recursively: false)!
        let startText = startTextNode.geometry as! SCNText
        let maxST, minST: SCNVector3
        maxST = startText.boundingBox.max
        minST = startText.boundingBox.min
        
        startTextNode.pivot = SCNMatrix4MakeTranslation((maxST.x-minST.x)/2,(maxST.y-minST.y)/2,0)
        
        let countdownText = countdownTextNode.geometry as! SCNText
        let maxCT, minCT: SCNVector3
        maxCT = countdownText.boundingBox.max
        minCT = countdownText.boundingBox.min
        
        countdownTextNode.pivot = SCNMatrix4MakeTranslation((maxCT.x-minCT.x)/2,0,0)
        
        let restartTextNode = restartNode.childNode(withName: "text", recursively: false)!
        let restartText = restartTextNode.geometry as! SCNText
        let maxRT, minRT: SCNVector3
        maxRT = restartText.boundingBox.max
        minRT = restartText.boundingBox.min
        
        restartTextNode.pivot = SCNMatrix4MakeTranslation((maxRT.x-minRT.x)/2,(maxRT.y-minRT.y)/2,0)

        let gameoverTextNode = restartNode.childNode(withName: "gameoverText", recursively: false)!
        let gameoverText = gameoverTextNode.geometry as! SCNText
        let maxGT, minGT: SCNVector3
        maxGT = gameoverText.boundingBox.max
        minGT = gameoverText.boundingBox.min
        
        gameoverTextNode.pivot = SCNMatrix4MakeTranslation(minGT.x + (maxGT.x - minGT.x)/2, minGT.y + (maxGT.y - minGT.y)/2, minGT.z + (maxGT.z - minGT.z)/2)
        
        sceneView.scene.rootNode.childNode(withName: "holes", recursively: true)!.childNodes.filter({ $0.name == "hole" }).forEach({
            
            holeNodes.append($0)
        })
        
        
        // SPAWNABLES
        let moleScene = SCNScene(named: "mole.scn")!
        moleNode = moleScene.rootNode.childNode(withName: "mole", recursively: false)!
        let badMoleScene = SCNScene(named: "badMole.scn")!
        badMoleNode = badMoleScene.rootNode.childNode(withName: "badMole", recursively: false)!
        
        //PARTICLES
        explosionGood = SCNParticleSystem(named: "explosionGood.scnp", inDirectory: nil)!
        explosionBad = SCNParticleSystem(named: "explosionBad.scnp", inDirectory: nil)!
        
    }
    
    func setupSounds(){
        
        let hitSound = SCNAudioSource(fileNamed: "hit.m4a")!
        hitSound.load()
        hitSound.volume = 0.3
        sounds["hit"] = hitSound
        
        let backgroundMusic = SCNAudioSource(fileNamed: "background.mp3")!
        backgroundMusic.load()
        backgroundMusic.volume = 0.4
        sounds["background"] = backgroundMusic
    }
    
    func setupHUD(){
        
        hud = HUD(size: self.view.bounds.size)
        sceneView.overlaySKScene = hud
        
        timer = gameTime
        hud.timer = timer
        
        hud.timerNode.isHidden = true
        hud.scoreNode.isHidden = true
        
        hud.findPlaneNode.isHidden = false
        hud.placeGardenNode.isHidden = true
    }
    
    func startGame(){
        
        let scaleAction = SCNAction.scale(to: CGFloat(0), duration: 0.25)
        scaleAction.timingMode = .linear
        
        startNode.runAction(SCNAction.sequence([scaleAction,SCNAction.removeFromParentNode()]))
        
        planeNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 30.0),SCNAction.run({ (_) in
            self.maxSpawnRate = 0.6
            self.moleStayTime = 0.75
        }), SCNAction.wait(duration: 30), SCNAction.run({ (_) in
            self.moleStayTime = 0.5
            self.maxSpawnRate = 0.5
        })]))
        
        startCounter()
    }
    
    func finishGame(){
        
        gameStarted = false
        holes.runAction(SCNAction.scale(to: 0, duration: 0.25))
        environment.runAction(SCNAction.scale(to: 0, duration: 0.25))
        
        planeNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.5), SCNAction.run({ (_) in
            self.planeNode.removeAllAudioPlayers()
            self.restartNode.position.x = 1
            self.restartNode.isHidden = false
            self.restartNode.runAction(SCNAction.moveBy(x: -1, y: 0, z: 0, duration: 0.3))
        })]))
    }
    
    func restartGame(){
        
        holes.runAction(SCNAction.scale(to: 1, duration: 0.25))
        environment.runAction(SCNAction.scale(to: 1, duration: 0.25))
        
        let restartNodePrevPos = restartNode.position
        restartNode.runAction(SCNAction.sequence([SCNAction.moveBy(x: -1, y: 0, z: 0, duration: 0.25),SCNAction.run({ (SCNNode) in
            self.restartNode.isHidden = true
            self.restartNode.position = restartNodePrevPos
            
            self.startCounter()
            
            self.timer = self.gameTime
            self.hud.timer = self.timer
            self.hud.score = 0
        })]))
    }
    
    func startCounter(){
        
        let countdownText = countdownTextNode.geometry as! SCNText
        
        countdownTextNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.50),SCNAction.run({ (SCNNode) in
            
            self.countdownTextNode.isHidden = false
            countdownText.string = "3"
            
        }),SCNAction.wait(duration: 1),SCNAction.run({ (SCNNode) in
            
            countdownText.string = "2"
            
        }),SCNAction.wait(duration: 1),SCNAction.run({ (SCNNode) in
            
            countdownText.string = "1"
            
        }),SCNAction.wait(duration: 1),SCNAction.run({ (SCNNode) in
            self.countdownTextNode.isHidden = true
            self.begin()
        })]))
    }
    
    func begin(){
        
        let musicPlayer = SCNAudioPlayer(source: sounds["background"]!)
        planeNode.addAudioPlayer(musicPlayer)

        spawnableHoleNodes = holeNodes
        
        for _ in 1...badMoleRate {
            moles.append(badMoleNode)
        }
        
        for _ in badMoleRate...10{
            moles.append(moleNode)
        }
        
        gameStarted = true
        let wait = SCNAction.wait(duration:1)
        let action = SCNAction.run {_ in
            if(self.timer == 0){
                self.planeNode.removeAction(forKey: "timer")
                self.finishGame()
                return
            }
            self.timer -= 1
            self.hud.timer = self.timer
        }
        planeNode.runAction(SCNAction.repeatForever(SCNAction.sequence([wait,action])), forKey: "timer")
    }
    
    func placePlane(){
        
        if tracking {
            guard foundSurface else { return }
            let trackingPosition = placeholderNode!.position
            placeholderNode?.removeFromParentNode()
            hud.placeGardenNode.isHidden = true
            planeNode.position = trackingPosition
            
            guard let frame = self.sceneView.session.currentFrame else {
                return
            }
            planeNode.eulerAngles.y = frame.camera.eulerAngles.y
            planeNode.isHidden = false
            tracking = false
            
            let prevScale = planeNode.scale
            planeNode.scale = SCNVector3(0, 0, 0)
            let scaleAction = SCNAction.scale(to: CGFloat(prevScale.x), duration: 0.5)
            scaleAction.timingMode = .linear
            planeNode.runAction(scaleAction, forKey: "scaleAction")
            
            holes.isHidden = false
            environment.isHidden = false
            
            let prevScaleForHoles = holes.scale
            holes.scale = SCNVector3(0, 0, 0)
            let scaleActionForHoles = SCNAction.scale(to: CGFloat(prevScaleForHoles.x), duration: 0.3)
            scaleActionForHoles.timingMode = .linear
            
            holes.runAction(SCNAction.sequence([SCNAction.wait(duration: 1),scaleActionForHoles]))
            
            let prevScaleForEnvironment = environment.scale
            environment.scale = SCNVector3(0, 0, 0)
            let scaleActionForEnvironment = SCNAction.scale(to: CGFloat(prevScaleForEnvironment.x), duration: 0.3)
            scaleActionForEnvironment.timingMode = .linear
            
            environment.runAction(SCNAction.sequence([SCNAction.wait(duration: 1.75),scaleActionForEnvironment]))
            
            let prevScaleForControls = controls.scale
            controls.scale = SCNVector3(0, 0, 0)
            let scaleActionForControls = SCNAction.scale(to: CGFloat(prevScaleForControls.x), duration: 0.3)
            scaleActionForControls.timingMode = .linear
            
            controls.isHidden = false
            
            controls.runAction(SCNAction.sequence([SCNAction.wait(duration: 2.25),scaleActionForControls, SCNAction.run({ (SCNNode) in
                self.hud.timerNode.isHidden = false
                self.hud.scoreNode.isHidden = false
            })]))
        }
    }
    
    func handlePlaceholder(){
        guard tracking else { return }
        let hitTest = self.sceneView.hitTest(CGPoint(x: self.view.frame.midX, y: self.view.frame.midY), types: .featurePoint)
        guard let result = hitTest.first else { return }
        let translation = SCNMatrix4(result.worldTransform)
        let position = SCNVector3Make(translation.m41, translation.m42, translation.m43)
        
        if placeholderNode == nil {
            let plane = SCNPlane(width: 0.15, height: 0.15)
            plane.firstMaterial?.diffuse.contents = UIImage(named: "circlePlaceholder.png")
            plane.firstMaterial?.isDoubleSided = true
            placeholderNode = SCNNode(geometry: plane)
            placeholderNode?.eulerAngles.x = -.pi * 0.5
            self.sceneView.scene.rootNode.addChildNode(self.placeholderNode!)
            foundSurface = true
            
            hud.findPlaneNode.isHidden = true
            hud.placeGardenNode.isHidden = false
        }
        self.placeholderNode?.position = position
    }
    
    func spawnMole() {
        
        if(spawnableHoleNodes.count == 0){
            
            spawnableHoleNodes = holeNodes
            
        }else{
            let randomIndex = Int(arc4random_uniform(UInt32(spawnableHoleNodes.count)))
            let randomHoleNode = spawnableHoleNodes[randomIndex]
            
            spawnableHoleNodes.remove(at: randomIndex)
            
            let newMoleNode = moles.randomElement()!.clone()
            newMoleNode.position.y = -0.032
            randomHoleNode.addChildNode(newMoleNode)
            
            let moveUp = SCNAction.move(by: SCNVector3Make(0, 0.056, 0), duration: 0.25)
            moveUp.timingMode = .linear
            
            let moveDown = SCNAction.move(by: SCNVector3Make(0, -0.056, 0), duration: 0.25)
            moveDown.timingMode = .linear
            
            newMoleNode.runAction(SCNAction.sequence([moveUp,SCNAction.wait(duration: moleStayTime),moveDown,SCNAction.removeFromParentNode()]))
        }
        
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if(gameStarted){
            if time > spawnTime {
                spawnMole()
                spawnTime = time + TimeInterval(Float.random(in: minSpawnRate...maxSpawnRate))
            }
        }
        handlePlaceholder()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        placePlane()
    }
    
    
    @objc func sceneViewTapped(recognizer: UITapGestureRecognizer){
        
        let location = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        
        if hitResults.count > 0 {
            let result = hitResults.first
            if let node = result?.node{
                if (node.name == "mole" ){
                    
                    let hitSound = sounds["hit"]!
                    planeNode.runAction(SCNAction.playAudio(hitSound, waitForCompletion: false))
                    
                    node.parent?.addParticleSystem(explosionGood)
                    node.removeFromParentNode()
                    
                    hud.score += 10
                    
                }else if(node.name == "badMole"){
                    let hitSound = sounds["hit"]!
                    
                    planeNode.runAction(SCNAction.playAudio(hitSound, waitForCompletion: false))
                    node.parent?.addParticleSystem(explosionBad)
                    node.removeFromParentNode()
                    
                    hud.score -= 50
                    
                }else if (node.name == "start"){
                    startGame()
                }else if (node.name == "restart"){
                    restartGame()
                }
            }
        }
    }
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView = ARSCNView(frame: self.view.frame)
        self.view.addSubview(self.sceneView)
        
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        sceneView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        sceneView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        sceneView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = false
        
        let scene = SCNScene(named: "MainScene.scn")!
        
        sceneView.scene = scene
        
        setupNodes()
        setupSounds()
        setupHUD()
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        
        tapRecognizer.addTarget(self, action: #selector(GameViewController.sceneViewTapped(recognizer:)))
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
}
