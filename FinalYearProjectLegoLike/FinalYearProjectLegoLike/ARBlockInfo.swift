import Foundation
import SceneKit

struct ConnectionPoint {
    var position: SCNVector3
}

protocol ARBlockInfoDelegate: AnyObject {
    func updateChildrenPositions(forBlockWithID id: UUID)
    func updateLoopChildrenPositions(forLoopWithID id: UUID)
}

struct ARBlockInfo {
    let id: UUID
    var node: SCNNode?
    // Inside ARBlockInfo when a block is moved
    var position: SCNVector3 {
        didSet {
            node?.position = position
            delegate?.updateChildrenPositions(forBlockWithID: id)
            
            // Additional check for loop blocks
            if isLoopBlock {
                delegate?.updateLoopChildrenPositions(forLoopWithID: id)
            }
        }
    }
    var relativePosition: SCNVector3?
    var initialOffset: SCNVector3 = SCNVector3Zero
    var isConnected: Bool = false
    var parentID: UUID?
    var childrenIDs: [UUID] = []
    var isMovable: Bool
    var topConnectionPoint: ConnectionPoint
    var bottomConnectionPoint: ConnectionPoint
    
    var isLoopBlock: Bool // Flag to indicate if this is a LoopBlock
    var rightConnectionPoint: ConnectionPoint?
    var topIndicatorNode: SCNNode?
    var bottomIndicatorNode: SCNNode?
    var rightIndicatorNode: SCNNode?
    
    weak var delegate: ARBlockInfoDelegate?
    
    private func createIndicatorNode() -> SCNNode {
        let geometry = SCNSphere(radius: 0.01)
        geometry.firstMaterial?.diffuse.contents = UIColor.clear
        let indicatorNode = SCNNode(geometry: geometry)
        indicatorNode.name = "indicator"
        return indicatorNode
    }
    
    init(node: SCNNode, position: SCNVector3, delegate: ARBlockInfoDelegate? = nil) {
        self.id = UUID()
        self.node = node
        self.position = position
        self.delegate = delegate
        self.isMovable = true
        self.isConnected = false
        self.isLoopBlock = (node.name == "Loop.usdz")
        
        // Set up default connection points
        self.topConnectionPoint = ConnectionPoint(position: SCNVector3(0, 0.02, 0))
        self.bottomConnectionPoint = ConnectionPoint(position: SCNVector3(0, -0.02, 0))
        self.rightConnectionPoint = nil // Only for loop blocks
        
        
        if self.isLoopBlock {
            print("Loop block recognized, setting up the right connecting point.")
            
            // Assuming the node's pivot is centered, position the right connection point to the right
            let rightPosition = SCNVector3(0.02, 0, 0.0)  // Adjust this as necessary
            self.rightConnectionPoint = ConnectionPoint(position: rightPosition)
            
            // Create and add the right indicator node
            self.rightIndicatorNode = createIndicatorNode()
            self.rightIndicatorNode?.position = rightPosition
            node.addChildNode(rightIndicatorNode!)
            
            print("Set rightConnectionPoint: \(rightPosition)")
        }
        else {
            
            
            // Initialize top and bottom indicators for all blocks
            self.topIndicatorNode = createIndicatorNode()
            self.bottomIndicatorNode = createIndicatorNode()
            
            // Assign positions and add as children
            self.topIndicatorNode?.position = self.topConnectionPoint.position
            self.bottomIndicatorNode?.position = self.bottomConnectionPoint.position
            node.addChildNode(topIndicatorNode!)
            node.addChildNode(bottomIndicatorNode!)
            
            
            // Set up default connection points for top and bottom
            self.topConnectionPoint = ConnectionPoint(position: self.topIndicatorNode?.position ?? SCNVector3Zero)
            self.bottomConnectionPoint = ConnectionPoint(position: self.bottomIndicatorNode?.position ?? SCNVector3Zero)
        }
        // Debug print to check the final setup
        print("Final setup - topConnectionPoint: \(self.topConnectionPoint.position), bottomConnectionPoint: \(self.bottomConnectionPoint.position), rightConnectionPoint: \(String(describing: self.rightConnectionPoint?.position))")
    }
}
