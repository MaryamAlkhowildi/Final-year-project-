import UIKit
import SceneKit
import ARKit


class ARBlocks: SCNNode {
    
    
    // Utility method to load a node based on model name, supporting USDZ format
    static func loadNode(from modelName: String) -> SCNNode? {
        let fileName = modelName.replacingOccurrences(of: ".usdz", with: "")
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz"),
              let scene = try? SCNScene(url: url, options: nil) else {
            return nil
        }
        return scene.rootNode.childNodes.first
    }
    
    
    
    static func configureBlockBasedOnName(_ node: SCNNode?, with sceneName: String) {
        guard let node = node else {
            print("Node is nil, cannot configure")
            return
        }
        
       // print("Configuring node based on sceneName: \(sceneName)")
        
        let dimensions: (width: CGFloat, height: CGFloat, length: CGFloat)
        switch sceneName {
        case "Loop.usdz":
            dimensions = (0.06, 0.075, 0.015) // Size for Loop Block
        case "Start.usdz":
            dimensions = (0.066, 0.03, 0.015) // Size for Start Block
        case "Bool.usdz":
            dimensions = (0.03, 0.015, 0.015) // Size for Bool Block
        case "Input.usdz":
            dimensions = (0.05, 0.05, 0.015) // Size for Input Block
        case "int.usdz":
            dimensions = (0.03, 0.015, 0.015) // Size for Int Block
        case "String.usdz":
            dimensions = (0.03, 0.015, 0.015) // Size for String Block
        case "IfCondition.usdz":
            dimensions = (0.11, 0.04, 0.015) // Size for ifCondition Block
        case "Print.usdz":
            dimensions = (0.04, 0.01, 0.015) // Size for Print Block
        default:
            print("Unknown block type for sceneName: \(sceneName)")
            return // Return early for unknown types
        }
        
        configureBlock(node, width: dimensions.width, height: dimensions.height, length: dimensions.length) // Pass the dimensions when configuring the block
    }

    private static func configureBlock(_ node: SCNNode, width: CGFloat, height: CGFloat, length: CGFloat) {
        // Create the geometry for the cube with the specified dimensions
        let cubeGeometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0)
        
        // The rest of the method remains the same, using cubeGeometry for the physics shape
        let physicsShape = SCNPhysicsShape(geometry: cubeGeometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody.mass = 3
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.01
        physicsBody.damping = 0.01
        physicsBody.angularDamping = 0.99
        node.physicsBody = physicsBody
        physicsBody.categoryBitMask = ARCollision.block.rawValue
        physicsBody.collisionBitMask = ARCollision.bottom.rawValue | ARCollision.block.rawValue
      //  print("Configured Block with dimensions: \(width)m x \(height)m x \(length)m")
    }

    
    
 /*   // Method to detect proximity between this block and another block
    func isCloseTo(block: ARBlocks, withinThreshold threshold: Float) -> Bool {
        guard let otherBlockName = block.name, let thisBlockName = self.name, otherBlockName != thisBlockName else {
            return false // Ensure not to compare the block with itself
        }
        let distance = self.position.distance(from: block.position)
        return distance < threshold
    }
    
    func connectTo(block: ARBlocks, in scene: SCNScene) {
        guard let physicsBodyA = self.physicsBody, let physicsBodyB = block.physicsBody else {
            print("One or both blocks do not have physics bodies.")
            return
        }
        // Now use the passed 'scene' directly instead of self.scene
        let anchorPointInScene = scene.rootNode.convertPosition(self.position, from: self.parent)
        let joint = SCNPhysicsBallSocketJoint(bodyA: physicsBodyA, anchorA: anchorPointInScene, bodyB: physicsBodyB, anchorB: anchorPointInScene)
        scene.physicsWorld.addBehavior(joint)
    }
*/

    
/*   private static func configureIfBlock(_ node: SCNNode) {
        node.eulerAngles.x = 180 // Adjust as needed, converts 180 degrees to radians
        
        // Create and assign the physics body directly here
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil) // Example: dynamic type
        physicsBody.mass = 2.0
        physicsBody.categoryBitMask = 1 // Example bitmask, adjust as needed
        physicsBody.collisionBitMask = 1 // Example bitmask, adjust as needed
        node.physicsBody = physicsBody
        physicsBody.categoryBitMask = ARCollision.block.rawValue
        physicsBody.collisionBitMask = ARCollision.bottom.rawValue // Collide only with the plane
        print("Configuring Loop Block")
    }*/

    
    required override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
/*    func updatePhysicsBodyType(to type: SCNPhysicsBodyType, mass: CGFloat = 2.0, categoryBitMask: Int? = nil) {
        // Check if a physics body already exists and update it directly
        if let existingPhysicsBody = self.physicsBody {
            existingPhysicsBody.type = type
            existingPhysicsBody.mass = mass
            if let bitmask = categoryBitMask {
                existingPhysicsBody.categoryBitMask = bitmask
            }
        } else {
            // If no physics body exists, create a new one with the specified properties
            let physicsBody = SCNPhysicsBody(type: type, shape: nil)
            physicsBody.mass = mass
            if let bitmask = categoryBitMask {
                physicsBody.categoryBitMask = bitmask
            }
            self.physicsBody = physicsBody
        }
    }*/
// Setup physics body with specified type and mass
/*    func setupPhysicsBodyForNode(_ node: SCNNode, type: SCNPhysicsBodyType, mass: CGFloat, categoryBitMask: Int?) {
    let physicsBody = SCNPhysicsBody(type: type, shape: nil) // Shape is nil for simplicity; customize as needed
    physicsBody.mass = mass
    if let categoryBitMask = categoryBitMask {
        physicsBody.categoryBitMask = categoryBitMask
    }
    // Configure other physics body properties as needed
    
    node.physicsBody = physicsBody
}*/
private extension SCNVector3 {
    func distance(from vector: SCNVector3) -> Float {
        let dx = self.x - vector.x
        let dy = self.y - vector.y
        let dz = self.z - vector.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
}

