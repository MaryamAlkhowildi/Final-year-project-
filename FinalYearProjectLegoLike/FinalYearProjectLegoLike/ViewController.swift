import UIKit
import SceneKit
import ARKit
import Photos
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate, SCNPhysicsContactDelegate, UIPopoverPresentationControllerDelegate, ARGestureControlDelegate {
    
    // Custom classes for managing alerts, AR scene controls, and gesture interactions.
    var alertController: ARAlertController!
    var gestureControl: ARGestureControl!
    var programmingBlock: ProgrammingBlock!
    var codeManager = CodeManager()
    var planes: [UUID:ARPlane] = [:]
    var planeEntities: [UUID: SCNNode] = [:]
    var blocks: [ARBlockInfo] = []
    // Arrays to hold the nodes and blocks within your AR scene.
    var sceneNode: [SCNNode] = []
    var sceneName: String?
    var currentYAngle: CGFloat = 0.0 // Used to track the current rotation angle of an object.
    var arConfig = ARWorldTrackingConfiguration()
    var detectPlanes = false
    var mmsg: [String] = []
    let messagesLabel = UILabel()
    var currentStepIndex: Int = 0
    var steps: [CodeStep] = []
    var blockNameToMessageMap: [String: String] = [:]
    var savedBlockStates = [ARBlockState]()
    

    
    
    // Outlets for the AR scene and UI buttons.
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var addNodeButton: UIButton!
    @IBOutlet weak var runButton: UIButton!
    @IBOutlet weak var textViewL: UITextView!
    // Refreshes the AR session, resetting tracking and removing existing anchors.
    @IBOutlet weak var pathView: UIView!
    @IBOutlet weak var pathLabel: UILabel!
    @IBOutlet weak var nextButtonPressed: UIButton!
    @IBOutlet weak var backButtonPressed: UIButton!
    @IBOutlet weak var challengeMassege: UITextView!
    
    @IBOutlet weak var TutorialButton: UIButton!
    
    @IBOutlet weak var switchButton: UISwitch!
    @IBAction func refreshSessionAction(_ sender: Any) {
        refreshSession()
    }

    // Calls the gesture control's method to remove a selected AR object.
    @IBAction func removeAction(_ sender: Any) {
        gestureControl.removeARObject(sender)
    }

    // Displays an alert to add a new AR node to the scene.
    @IBAction func addNodeAction(_ sender: Any) {
        alertController.showAddARNodeAlert()
    }
    
    @IBAction func runButton(_ sender: Any) {
        // Execute the challenge and get the result.
        
        let result = codeManager.runChallenge()
        displayGeneratedCode(result) // A method to display the result in your UI.
        
        if !result.contains("Error:") {

        // Assuming `intValue` has been correctly set in the `codeManager` when the VariableBlock was added.
        // Make sure you have captured and stored intValue somewhere accessible before this point.
        // This call will initialize steps for the explanation part, using the captured integer input.
        if let intValue = codeManager.intValue, let variableName = codeManager.variableName {
            initializeSteps(withUserInput: intValue, variableName: variableName)
            currentStepIndex = 0
            displayCurrentStep()
            pathView.isHidden = false
        } else {
            print("Error: No valid input provided.")
        }
    } else {
        // If the result contains an error, possibly handle this case (e.g., show an alert or message to the user)
        print(result) // Optionally replace this with user feedback, such as an alert
    }
}

    
    @IBAction func TutorialButton(_ sender: Any){
        alertController?.presentTutorial()
        
    }

        
    
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
            displayCurrentStep()
        }
    }

    
    @IBAction func backButtonPressed(_ sender: Any) {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
            displayCurrentStep()
        }
    }
    



    // Called after the controller's view is loaded into memory. Sets up the scene and gesture recognizers.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupPhysics()
        initialGetter()
        
        gestureControl.setupGestureRecognizer()
        gestureControl.delegate = self // Set the delegate
        // Create a ARSession configuration object we can re-use
        arConfig = ARWorldTrackingConfiguration()
        arConfig.isLightEstimationEnabled = true
        arConfig.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        // Initial setup for the pathView
        pathView.isHidden = true
        pathView.layer.cornerRadius = 10 // Optional for rounded corners
        pathView.layer.opacity = 0.8 // Optional for slight transparency
        
        
        
        UIApplication.shared.isIdleTimerDisabled = true
        // Enable debug options to show physics shapes
        sceneView.debugOptions = [.showPhysicsShapes, .showPhysicsFields]
        alertController.presentChallengeExplanation()
        // Set the challenge message
        
        let challengeText = "START the program, declare an INTEGER variable then check IF the variable is greater than a 0. If TRUE, print 'positive'; if ELSE, print 'negative'. Explore the ITERATE and inside PRINT 'Hello World'. 3 Times"
        
        // Set the attributed text to the UITextView
        challengeMassege.text = challengeText
    }

    func initialGetter() {
        if alertController == nil {
            alertController = ARAlertController()
            alertController.viewController = self
        }
        
        if gestureControl == nil {
            gestureControl = ARGestureControl()
            gestureControl.viewController = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.sceneView.session.run(self.arConfig)
        checkMediaPermissionAndButtonState()

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    
    func hidePlanes() {
        for (planeID, _) in self.planes {
            self.planes[planeID]?.hide()
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
    func disableTracking(disabled: Bool) {
        // Stop detecting new planes or updating existing ones.
        
        if disabled {
            self.arConfig.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.init(rawValue: 0)
        } else {
            self.arConfig.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        }
        
        self.sceneView.session.run(self.arConfig)
    }
    
    @IBAction func detectPlanesChanged(_ sender: Any) {
        let enabled = (sender as! UISwitch).isOn
        
        if enabled == detectPlanes {
            return
        }
        
        detectPlanes = enabled
        if enabled {
            self.disableTracking(disabled: false)
        } else {
            self.disableTracking(disabled: true)
        }
    }
    
    
    
    
    func setupPhysics() {
        let bottomPlane = SCNBox(width: 1000, height: 0.5, length: 1000, chamferRadius: 0)
        let bottomMaterial = SCNMaterial()
        

        bottomMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0)
        bottomPlane.materials = [bottomMaterial]
        let bottomNode = SCNNode(geometry: bottomPlane)
        
        bottomNode.position = SCNVector3Make(0, -10, 0)
        bottomNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: nil)
        bottomNode.physicsBody?.categoryBitMask = ARCollision.bottom.rawValue
        bottomNode.physicsBody?.collisionBitMask = ARCollision.block.rawValue // Collide with blocks

        
        let scene = self.sceneView.scene
        scene.rootNode.addChildNode(bottomNode)
        scene.physicsWorld.contactDelegate = self
    }

    
    // Sets up the initial scene for the ARSCNView including enabling default lighting and statistics.
    func setupScene() {
        // to render something you need to add it here
        self.sceneView.delegate = self
        planes = [:]
        blocks = []
        sceneNode = []
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = []
        sceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X
        let scene = SCNScene()
        sceneView.scene = scene
    }
    
    // MARK: - SCNPhysicsContactDelegate
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
       
        guard let physicsBodyA = contact.nodeA.physicsBody, let physicsBodyB = contact.nodeB.physicsBody else {
            return
        }
        
        let categoryA = ARCollision.init(rawValue: physicsBodyA.categoryBitMask)
        let categoryB = ARCollision.init(rawValue: physicsBodyB.categoryBitMask)
        
        let contactMask: ARCollision? = [categoryA, categoryB]
        
        if contactMask == [ARCollision.bottom, ARCollision.block] {
            if categoryA == ARCollision.bottom {
                contact.nodeB.removeFromParentNode()
            } else {
                contact.nodeA.removeFromParentNode()
            }
        }
    }
    

    
    func refreshSession() {
        // Remove all nodes from the scene
        for block in sceneNode {
            block.removeFromParentNode()
        }

        // Reset AR session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        // Check media permissions and button state (assuming this is relevant to your app's logic)
        checkMediaPermissionAndButtonState()

        // Reset sidebar messages
        mmsg.removeAll()
        updateSidebarUI()
        pathView.isHidden = true
        initializeSteps()

        
    }



    
    // Checks the camera permission status and updates the UI accordingly.
    func checkMediaPermissionAndButtonState() {
        DispatchQueue.main.async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .authorized || status == .notDetermined {
                self.alertController.showOverlyText("STARTING A NEW SESSION, TRY MOVING LEFT OR RIGHT", withDuration: 2)
            } else {
                let accessDescription = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String
                //self.alertController.showPermissionAlertWithDescription(accessDescription!)
            }
            self.currentYAngle = 0.0
            self.removeButton.isHidden = true
            self.addNodeButton.isHidden = true
            self.TutorialButton.isHidden = true

        }
    }
    
    // Utility function to refresh the sidebar's UI based on the current state of `mmsg`
    func updateSidebarUI() {
        DispatchQueue.main.async { [weak self] in
            self?.textViewL.text = self?.mmsg.joined(separator: "\n") ?? ""
        }
    }
  
    func updateSidebarWithMessage(_ message: String) {
        print("Updating sidebar with message: \(message)")
            mmsg.append(message)
            updateSidebarUI()
    }
    func removeSidebarMessage(forNodeName nodeName: String) {
        print("Current sidebar messages: \(mmsg)")
        // Use the blockNameToMessageMap to find the message associated with nodeName
        if let messageToRemove = blockNameToMessageMap[nodeName] {
            print("Found sidebar message for node \(nodeName). Removing it: \(messageToRemove)")
            if let index = mmsg.firstIndex(of: messageToRemove) {
                mmsg.remove(at: index)
                updateSidebarUI() // Refresh the sidebar to reflect the removal
                // Also, remove the mapping once the message is removed
                blockNameToMessageMap.removeValue(forKey: nodeName)
            }
        } else {
            print("No sidebar message found for node \(nodeName).")
        }
    }

    
    enum CodeStep {
        case start
        case userInput(variableName: String, value: Int)
        case ifStatementCheck(Int)
        case loopIteration(Int)
        case printHelloWorld
        case end
    }

    
    func updateExplanation(forStep step: CodeStep) {
        switch step {
        case .start:
            pathLabel.text = "Now we are at the START of the code."
        case .userInput(let variableName, let number):
            pathLabel.text = "Second, The user defined \(variableName) with value \(number)."
        case .ifStatementCheck(let number):
            pathLabel.text = "Is the number entered more than 0? \(number > 0 ? "Yes, print positive." : "No, print negative.")"
        case .loopIteration(let iteration):
            pathLabel.text = "Loop iteration \(iteration): Is \(iteration) less than 3? Yes, then i++, and print 'Hello World'."
        case .printHelloWorld:
            pathLabel.text = "Printing: Hello World 3 times as its inside the loop."
        case .end:
            pathLabel.text = "The challenge has ended, Next lesson will be added SOON"
        }
        pathView.isHidden = false // Show the view with the current explanation
    }


    
    // Function to handle the placement of AR objects
     func didPlaceARObject(named objectName: String, at position: SCNVector3) {
         print("didPlaceARObject called with objectName: \(objectName)")
         //let programmingBlock: ProgrammingBlock

         // Determine which programming block is associated with the AR object
         switch objectName {
         case "Start.usdz":
             programmingBlock = StartBlock()
             codeManager.addBlock(programmingBlock, to: nil, at: .top)
             let message = programmingBlock.generateSidebarMessage(indentationLevel: 0)
             updateSidebarWithMessage(message)
             blockNameToMessageMap[objectName] = message
         case "Input.usdz":
             // Inside your case for adding an InputBlock
             alertController.promptForInput { inputType, variableName, userInput in
                 let inputBlock = InputBlock(variableName: variableName, userInput: userInput, inputType: inputType)
                 self.codeManager.addBlock(inputBlock, to: nil, at: .top)
                 
                 // Generate the sidebar message specific to the newly created InputBlock
                 let message = inputBlock.generateSidebarMessage()
                 
                 // Update the sidebar UI with the new message
                 self.updateSidebarWithMessage(message)
                 
                 // Update the mapping with the association between the InputBlock's unique identifier and its message
                 // Assuming 'objectName' uniquely identifies the InputBlock, but you might want to use or generate
                 // a more specific identifier if 'objectName' isn't unique enough.
                 self.blockNameToMessageMap[objectName] = message
             }

         case "int.usdz":
             alertController.promptForIntAndVariableName() { [weak self] variableName, intValue in
                 guard let self = self, let intValue = intValue else {
                     print("Input is not a valid integer or was not provided")
                     return
                 }
                 
                 self.codeManager.intValue = intValue
                 self.codeManager.variableName = variableName

                 let programmingBlock = VariableBlock(variableName: variableName, value: intValue)
                 DispatchQueue.main.async {
                     self.codeManager.addBlock(programmingBlock, to: nil, at: .top)
                     let message = programmingBlock.generateSidebarMessage()
                     self.updateSidebarWithMessage(message)
                     self.initializeSteps(withUserInput: intValue, variableName: variableName)
                     self.blockNameToMessageMap[objectName] = message
                     //self.displayCurrentStep() // Optionally, immediately display the first step
                 }
             }


         // String example
         case "String.usdz":
             alertController.promptForStringAndVariableName() { [weak self] variableName, stringValue in
                 guard let stringValue = stringValue, !stringValue.isEmpty else {
                     print("No string input provided")
                     return
                 }
                 
                 let programmingBlock = VariableBlock(variableName: variableName, value: stringValue)
                 DispatchQueue.main.async {
                     self?.codeManager.addBlock(programmingBlock, to: nil, at: .top)
                     let message = programmingBlock.generateSidebarMessage()
                     self?.updateSidebarWithMessage(message)
                     self?.blockNameToMessageMap[objectName] = message
                 }
             }

         // Bool example
         case "Bool.usdz":
             alertController.promptForBoolAndVariableName() { [weak self] variableName, boolValue in
                 let programmingBlock = VariableBlock(variableName: variableName, value: boolValue as Any)
                 DispatchQueue.main.async {
                     self?.codeManager.addBlock(programmingBlock, to: nil, at: .top)
                     let message = programmingBlock.generateSidebarMessage()
                     self?.updateSidebarWithMessage(message)
                     self?.blockNameToMessageMap[objectName] = message
                 }
             }
             
         case "Print.usdz":
             alertController.promptForPrint() { [weak self] message in
                 let programmingBlock = PrintStatementBlock(message: message)
                 DispatchQueue.main.async {
                     self?.codeManager.addBlock(programmingBlock, to: nil, at: .top)
                     let message = programmingBlock.generateSidebarMessage()
                     self?.updateSidebarWithMessage(message)
                     self?.blockNameToMessageMap[objectName] = message
                 }
             }
         case "IfCondition.usdz":
             alertController.promptForCondition { condition, trueBranchCode, falseBranchCode in
                 let ifBlock = IfStatementBlock(condition: condition, trueBranchOutput: trueBranchCode, falseBranchOutput: falseBranchCode)
                 // Adjust the following line according to your updated method signature
                 self.codeManager.addBlock(ifBlock, to: nil, at: .top)
                 DispatchQueue.main.async {
                     let message = ifBlock.generateSidebarMessage()
                     self.updateSidebarWithMessage(message)
                 }}
         case "Loop.usdz":
             alertController.promptForLoopDetails { [weak self] variableName, startValue, endCondition, increment in
                  let programmingBlock = ForLoopBlock(
                      variableName: variableName,
                      startValue: startValue,
                      endCondition: endCondition,
                      increment: increment
                  )
                  DispatchQueue.main.async {
                      self?.codeManager.addBlock(programmingBlock, to: nil, at: .top)
                      let message = programmingBlock.generateSidebarMessage()
                      self?.updateSidebarWithMessage(message)
                      self?.blockNameToMessageMap[objectName] = message
                  }
              }

         default:
             // Handle unknown block with a default implementation
             self.codeManager.addBlock(programmingBlock, to: nil, at: .top)
             programmingBlock = DefaultBlock()
             let message = programmingBlock.generateSidebarMessage(indentationLevel: 0)
             updateSidebarWithMessage(message)
             blockNameToMessageMap[objectName] = message
         }
         // Here we add the block to the codeManager

             
             // Print statement at the en
        print("Finished handling AR object placement for: \(objectName). Current total blocks: \(codeManager.blocks.count)")
         

     }
 

    // Function to display the generated code on the screen
    func displayGeneratedCode(_ code: String) {
        // Display the code in a text view or any other UI element designated for code output
        updateSidebarWithMessage(code)
    }
    
    func initializeSteps(withUserInput intValue: Int? = nil, variableName: String? = nil) {
        var initialSteps: [CodeStep] = [
            .start
        ]

        if let intValue = intValue, let variableName = variableName {
            initialSteps.append(.userInput(variableName: variableName, value: intValue))
            initialSteps.append(.ifStatementCheck(intValue))
        }

        let loopSteps: [CodeStep] = (1...3).map { .loopIteration($0) }
        let finalSteps: [CodeStep] = [.printHelloWorld, .end]

        initialSteps += loopSteps + finalSteps

        steps = initialSteps
    }


    
    func displayCurrentStep() {
        guard currentStepIndex >= 0 && currentStepIndex < steps.count else { return }
        let step = steps[currentStepIndex]
        updateExplanation(forStep: step)    }
    
    func evaluateCondition(_ condition: String, withInput input: Int) -> Bool {
        let components = condition.split(separator: " ")
        guard components.count == 3 else { return false }

        let variable = String(components[0])
        let operatorCondition = String(components[1])
        let value = Int(components[2])

        // Ensure the variable is 'n', and we have a valid comparison value
        guard variable == "n", let value = value else { return false }

        // Evaluate the condition based on the operator
        switch operatorCondition {
        case ">":
            return input > value
        case "<":
            return input < value
        default:
            return false
        }
    }
    

    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let estimate = self.sceneView.session.currentFrame?.lightEstimate else {
            return
        }
    
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.classForCoder()) {
            return
        }
        
        // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
        let plane = ARPlane(anchor: anchor as! ARPlaneAnchor, isHidden: false, withMaterial: ARPlane.currentMaterial()!)
        planes[anchor.identifier] = plane
        node.addChildNode(plane)
        
        DispatchQueue.main.async {
            self.addNodeButton.isHidden = false
            self.removeButton.isHidden = true
            self.pathView.isHidden = true
            self.TutorialButton.isHidden = false
            self.alertController?.showOverlyText("plane is Added to the scene! select the Block and tap to the screen to START working ", withDuration: 3)
        }

    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = planes[anchor.identifier] else {
            return
        }
        plane.update(anchor: anchor as! ARPlaneAnchor)
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {

        self.planes.removeValue(forKey: anchor.identifier)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.alertController?.showOverlyText("Something went wrong, restart the App", withDuration: 2)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        
        savedBlockStates.removeAll()

            for block in sceneNode {
                let state = ARBlockState(identifier: block.name ?? UUID().uuidString, position: block.position)
                savedBlockStates.append(state)
            }
        DispatchQueue.main.async { [weak self] in
            self?.alertController?.showOverlyText("Session Was Interrupted!", withDuration: 2)
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Freeze physics
        sceneView.scene.physicsWorld.speed = 0
        
        for state in savedBlockStates {
            if let block = sceneNode.first(where: { $0.name == state.identifier }) {
                block.position = state.position
                // Restore blocks here
            }
        }
        
        // Unfreeze physics after a delay to ensure blocks are settled
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sceneView.scene.physicsWorld.speed = 1
        }
    }

    
}
