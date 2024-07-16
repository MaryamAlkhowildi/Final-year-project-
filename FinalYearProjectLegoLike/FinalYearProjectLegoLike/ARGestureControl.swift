
import Foundation
import SceneKit
import ARKit

protocol ARGestureControlDelegate: AnyObject {
    func didPlaceARObject(named name: String, at position: SCNVector3)
    
}


class ARGestureControl: NSObject, UIGestureRecognizerDelegate {
    // References to the ViewController and an alertController for displaying messages.
    weak var viewController: ViewController?
    var alertController: ARAlertController?
    var planes: [UUID:ARPlane] = [:]
    var sidebarMessages: [String: String] = [:] 
    // var blocks: [ARBlockInfo] = []
    
    
    // Variables to keep track of the currently selected node and the initial hit test result for moving objects.
    // Gesture state
    var selectedNode: SCNNode?
    var initialWorldPosition: SCNVector3?
    weak var delegate: ARGestureControlDelegate?
    
    
    
    // Setup gesture recognizers for tap, pan, and pinch gestures on the ARSCNView.
    func setupGestureRecognizer() {
        guard let sceneView = viewController?.sceneView else { return }
        
        // Tap recognizer for adding new objects or selecting existing ones.
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(insertARBlocks(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Pan recognizer; for moving objects.
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.minimumNumberOfTouches = 1
        sceneView.addGestureRecognizer(panGestureRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 1.0 // Adjust this value for the desired press duration
        sceneView.addGestureRecognizer(longPressRecognizer)
        
        
        
    }
    
    @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began, // Ensure the gesture began to avoid multiple triggers
              let sceneView = viewController?.sceneView else { return }
        
        let pressLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(pressLocation, options: nil) // Adjust hitTest options as needed
        
        guard let hitNode = hitTestResults.first?.node, hitNode.name != "ARPlane" else {
            return // No node was pressed or the node is an ARPlane, which we don't want to remove
        }
        
        // Store the node for later removal
        selectedNode = hitNode
        
        // Show the remove button
        DispatchQueue.main.async {
            self.viewController?.removeButton.isHidden = false
        }
    }
    
    
    @objc func insertARBlocks(_ recognizer: UITapGestureRecognizer) {
        guard let sceneView = viewController?.sceneView else { return }
        
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        guard let hitTestResult = hitTestResults.first else { return }
        
        // Calculate the position where the node should be placed based on the hit test result.
        let insertionYOffset: Float = 0.02// Adjust this value as necessary.
        let position = SCNVector3(
            hitTestResult.worldTransform.columns.3.x,
            hitTestResult.worldTransform.columns.3.y  + insertionYOffset ,
            hitTestResult.worldTransform.columns.3.z
        )
        
        // Load the model node. Replace 'modelName' with the actual model name you want to use.
        guard let sceneName = viewController?.sceneName,
              let modelNode = ARBlocks.loadNode(from: sceneName) else {
            print("Failed to load the model")
            return
        }
        // Right after loading the modelNode, set its name explicitly if not already set
        modelNode.name = sceneName // Or set it to a more specific identifier if needed
        print("the node name is : ", modelNode.name! )
        modelNode.position = position
        print(position)
        modelNode.eulerAngles.x = 200 // Adjust as needed, converts 180 degrees to radians
        
        // Assuming `modelNode` is your SCNNode with an already set name
        if let modelName = modelNode.name {
            
            delegate?.didPlaceARObject(named: modelName, at: modelNode.position)
            
            
            //modelNode.eulerAngles.y  =
            //modelNode.eulerAngles.z  = 0
            
            // Create and assign the physics body
            //let physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil) // Example: dynamic type
            //modelNode.physicsBody = physicsBody // Correctly assign the physics body to the model node
            print ("done")
            
            // Create an ARBlockInfo instance and add it to the tracking array
            let blockInfo = ARBlockInfo(node: modelNode, position: position)
            viewController?.blocks.append(blockInfo)
            print("Added block: \(modelNode.name ?? "Unknown"), Position: \(position)")
            print (blockInfo)
            
            // Add the model node to the scene
            viewController?.sceneView.scene.rootNode.addChildNode(modelNode)
            
        }
    }
    
    
    // Allows multiple gestures to be recognized simultaneously.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let sceneView = viewController?.sceneView else { return }
        let location = gestureRecognizer.location(in: sceneView)
        
        switch gestureRecognizer.state {
        case .began:
            let hitTestResults = sceneView.hitTest(location, options: nil)
            if let hitTestResult = hitTestResults.first {
                // This assumes planes are identified by having their UUID as their name.
                // Adjust this logic if your plane identification method differs.
                if let nodeName = hitTestResult.node.name, !planes.keys.contains(UUID(uuidString: nodeName) ?? UUID()) {
                    var node = hitTestResult.node
                    // Traverse up to find the root node if a child node is picked
                    while let parentNode = node.parent, parentNode !== sceneView.scene.rootNode {
                        node = parentNode
                    }
                    
                    selectedNode = node
                    initialWorldPosition = node.position
                    //print("Node selected: \(node.name ?? "Unnamed Node")")
                }
            }
        case .changed:
            guard let selectedNode = selectedNode,
                  let blockInfo = viewController?.blocks.first(where: { $0.node === selectedNode }),
                  blockInfo.isMovable else { return }
            let location = gestureRecognizer.location(in: sceneView)
            let hitTestResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
            
            if let hitTestResult = hitTestResults.first {
                // Configure the block based on its name or identifier
                if let sceneName = viewController?.sceneName {
                    ARBlocks.configureBlockBasedOnName(selectedNode, with: sceneName)
                    //print("Successfully configured block: \(sceneName)")
                }
                
                // Use the hitTestResult to move the block along the plane
                let worldPosition = SCNVector3(
                    hitTestResult.worldTransform.columns.3.x,
                    hitTestResult.worldTransform.columns.3.y, // Adjust if you want vertical movement
                    hitTestResult.worldTransform.columns.3.z
                )
                // Instead of directly setting the position, we call updateBlockPosition
                updateBlockPosition(node: selectedNode, newPosition: worldPosition)
               // print("Node moved within the plane to \(selectedNode.position)")
                
                // Check for the closest block and adjust the position for connection
                // Check for the closest block and adjust the position for connection
                if let closestBlockInfo = findClosestBlock(to: selectedNode.position, excluding: selectedNode) {
               //     print("Closest block found: \(closestBlockInfo.node?.name ?? "Unknown") at position \(closestBlockInfo.position)")
                    // Pass the ID of the closest block instead of the block itself
                    adjustPositionForConnection(movingNode: selectedNode, stationaryBlockID: closestBlockInfo.id)
                //    print("Adjusted \(selectedNode.name ?? "Unknown") position to be on top of \(closestBlockInfo.node?.name ?? "Unknown")")
                    
                }
            } else {
                // Handle the case where the hit test does not intersect with the plane
             //   print("Hit test did not intersect with the AR plane.")
            }
            
            
        case .ended, .cancelled:
            print("Gesture ended or cancelled")
            if let selectedNode = selectedNode,
               let blockIndex = viewController?.blocks.firstIndex(where: { $0.node === selectedNode }) {
                viewController?.blocks[blockIndex].isMovable = false  // The block is now fixed in place

            }
            selectedNode = nil // Clear the selected node
        default:
            break
        }
    }
    
    func findClosestBlock(to position: SCNVector3, excluding excludedNode: SCNNode) -> ARBlockInfo? {
        guard let blocks = viewController?.blocks else { return nil }
        
        let proximityThreshold: Float = 0.01 // Adjust based on your scene scale
        var closestBlockInfo: ARBlockInfo?
        var minimumDistance: Float = Float.infinity
        
        for blockInfo in blocks where blockInfo.node != excludedNode {
            let distance = distanceBetween(position, and: blockInfo.position)
            if distance < minimumDistance && distance < proximityThreshold {
                minimumDistance = distance
                closestBlockInfo = blockInfo
            }
        }
        
        return closestBlockInfo
    }
    
    func updateChildrenPositions(forBlockWithID parentID: UUID) {
        guard let viewController = viewController,
              let parentIndex = viewController.blocks.firstIndex(where: { $0.id == parentID }),
              let parentNode = viewController.blocks[parentIndex].node else {
           // print("Parent block or node not found for updating children positions.")
            return
        }
        
        var visitedNodes = Set<UUID>()
        recursivelyUpdatePositions(forParentNode: parentNode, withParentIndex: parentIndex, visitedNodes: &visitedNodes)
    }
    
    private func recursivelyUpdatePositions(forParentNode parentNode: SCNNode, withParentIndex parentIndex: Int, visitedNodes: inout Set<UUID>) {
        guard let viewController = viewController else {
       //     print("ViewController not found for recursively updating positions.")
            return
        }
        
        let parentBlock = viewController.blocks[parentIndex]
     //   print("Starting to update positions for children of parentNode: \(parentNode.name ?? "Unnamed") with ID: \(parentBlock.id)")
        
        for childID in parentBlock.childrenIDs {
            // Safety check to avoid infinite loop
            if visitedNodes.contains(childID) {
        //        print("Warning: Detected a circular reference. Child with ID \(childID) has already been updated. Skipping to avoid infinite loop.")
                continue
            }
            
            guard let childIndex = viewController.blocks.firstIndex(where: { $0.id == childID }),
                  let childNode = viewController.blocks[childIndex].node else {
      //          print("Child block with ID \(childID) not found in blocks array or is already visited.")
                continue
            }
            
            let initialOffset = viewController.blocks[childIndex].initialOffset
            childNode.position = SCNVector3(parentNode.position.x + initialOffset.x,
                                            parentNode.position.y + initialOffset.y,
                                            parentNode.position.z + initialOffset.z)
            
            viewController.blocks[childIndex].position = childNode.position
      //      print("Updated position for childNode: \(childNode.name ?? "Unnamed") with ID: \(childID) to position: \(childNode.position)")
            
            // Mark this node as visited
            visitedNodes.insert(childID)
            
            // Recursively update this child's children
            recursivelyUpdatePositions(forParentNode: childNode, withParentIndex: childIndex, visitedNodes: &visitedNodes)
        }
    }
    
    
    func adjustPositionForConnection(movingNode: SCNNode, stationaryBlockID: UUID?) {
        guard let stationaryBlockID = stationaryBlockID,
              let stationaryBlockIndex = viewController?.blocks.firstIndex(where: { $0.id == stationaryBlockID }),
              let stationaryNode = viewController?.blocks[stationaryBlockIndex].node else {
       //     print("Stationary block or its node is not accessible.")
            return
        }
        
        // Presumably, you need to compute the initialOffset here when the connection is made
        let initialOffset = SCNVector3(x: movingNode.position.x - stationaryNode.position.x,
                                       y: movingNode.position.y - stationaryNode.position.y,
                                       z: movingNode.position.z - stationaryNode.position.z)
        
        // Then use the offset to adjust the moving node's position relative to the stationary node.
        movingNode.position = SCNVector3(stationaryNode.position.x + initialOffset.x,
                                         stationaryNode.position.y + initialOffset.y,
                                         stationaryNode.position.z + initialOffset.z)
        
        if var movingBlock = viewController?.blocks.first(where: { $0.node === movingNode }) {
            movingBlock.parentID = stationaryBlockID
            movingBlock.initialOffset = initialOffset
            
            // Since we can't mutate stationaryBlock directly, update it within the array.
            var updatedStationaryBlock = viewController!.blocks[stationaryBlockIndex]
            updatedStationaryBlock.childrenIDs.append(movingBlock.id)
            viewController?.blocks[stationaryBlockIndex] = updatedStationaryBlock
            
            if let movingIndex = viewController?.blocks.firstIndex(where: { $0.node === movingNode }) {
                viewController?.blocks[movingIndex] = movingBlock
            }
            
            // Set isMovable to false for the moving node
            movingBlock.isMovable = false
            
         //   print("Connected \(movingNode.name ?? "Unknown") to \(stationaryNode.name ?? "Unknown")")
        } else {
         //   print("Moving block is not found in the blocks array.")
        }
    }
    
    
    
    func distanceBetween(_ position1: SCNVector3, and position2: SCNVector3) -> Float {
        let dx = position1.x - position2.x
        let dy = position1.y - position2.y
        let dz = position1.z - position2.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    func updateBlockPosition(node: SCNNode, newPosition: SCNVector3) {
        guard let viewController = viewController else { return }
        
        // At the beginning of updateBlockPosition
     //   print("Attempting to update position for node: \(node.name ?? "Unknown")")
        
        // Assuming blocks is an array of ARBlockInfo in viewController
        if let index = viewController.blocks.firstIndex(where: { $0.node === node }) {
            // Update the position in the array
            viewController.blocks[index].position = newPosition
      //      print("Updated block position in array: \(viewController.blocks[index].node?.name ?? "Unknown") to \(newPosition)")
            
            // If this block has children, update their positions too
            updateChildrenPositions(forBlockWithID: viewController.blocks[index].id)
        } else {
    //        print("Block not found in tracking array.")
        }
    }
    /*    func connectBlocks(_ nodeA: SCNNode?, _ nodeB: SCNNode?) {
     guard let bodyA = nodeA?.physicsBody, let bodyB = nodeB?.physicsBody else { return }
     
     // Example: Create a fixed joint between nodeA and nodeB
     let joint = SCNPhysicsBallSocketJoint(bodyA: bodyA, anchorA: nodeA!.position, bodyB: bodyB, anchorB: nodeB!.position)
     viewController?.sceneView.scene.physicsWorld.addBehavior(joint)
     
     //drawLineBetween(nodeA!, nodeB!)
     
     print("Connected \(nodeA?.name ?? "Unknown") with \(nodeB?.name ?? "Unknown")")
     }
     */
    
    
    // Checks if an existing AR object was tapped to either select it for removal or to insert a new AR object at the tap location.
    private func checkExistingARObjectToInsertOrRemove(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: viewController?.sceneView)
        let hitResults = viewController?.sceneView.hitTest(location, options: nil)
        if let hitResult = hitResults?.first, hitResult.node != viewController?.sceneView.scene.rootNode {
            selectedNode = hitResult.node
            viewController?.removeButton.isHidden = false
        } else {
            selectedNode = nil
            viewController?.removeButton.isHidden = true
        }
    }
    
    func printSceneHierarchy(node: SCNNode, indent: String = "") {
        print("\(indent)\(node.name ?? "Unnamed Node")")
        for childNode in node.childNodes {
            printSceneHierarchy(node: childNode, indent: indent + "  ")
        }
    }


    
    func removeARObject(_ sender: Any) {
        guard let nodeToRemove = selectedNode, nodeToRemove.name != "ARPlane" else { return }

        print("Attempting to remove top-level node: \(nodeToRemove.name ?? "Unnamed")")

        // Assuming the top-level node is not an ARPlane, it should be the one to remove.
        // Check if the node to remove is the child of the rootNode or not.
        var topLevelNode = nodeToRemove
        while let parent = topLevelNode.parent, parent != viewController?.sceneView.scene.rootNode {
            topLevelNode = parent
        }
        
        // Check again if the topLevelNode is not an ARPlane
        guard topLevelNode.name != "ARPlane" else { return }
        
        print("Attempting to remove top-level node: \(nodeToRemove.name ?? "Unnamed")")
        handleNodeRemoval(nodeToRemove)
        print("Completed removal process for node: \(nodeToRemove.name ?? "Unnamed")")

        topLevelNode.enumerateHierarchy { (childNode, _) in
            print("Removing child node: \(childNode.name ?? "Unnamed")")
            print("Attempting to remove top-level node: \(childNode.name ?? "Unnamed")")
            handleNodeRemoval(childNode)
            print("Completed removal process for node: \(childNode.name ?? "Unnamed")")
            childNode.removeFromParentNode()

        }

        // Remove any physics body attached to the top-level node
        topLevelNode.physicsBody = nil
        
        // Now remove the top-level node itself
        topLevelNode.removeFromParentNode()

        
        // Hide the remove button and reset the selected node
        viewController?.removeButton.isHidden = true
        selectedNode = nil

        print("Scene after removal attempt:")
        printSceneHierarchy(node: viewController?.sceneView.scene.rootNode ?? SCNNode())
    }
    func handleNodeRemoval(_ node: SCNNode) {
        var nodesToCheck = [node]
        print("Starting node removal process...")

        while !nodesToCheck.isEmpty {
            let currentNode = nodesToCheck.removeFirst()
            
            // Log the current node being processed.
            print("Processing node: \(currentNode.name ?? "Unnamed")")

            // If the current node has a name, attempt to remove its associated sidebar message.
            if let nodeName = currentNode.name, !nodeName.isEmpty {
                print("Attempting to remove sidebar message for node: \(nodeName)")
                viewController?.removeSidebarMessage(forNodeName: nodeName)
            } else {
                print("Node \(currentNode) does not have a name or the name is empty.")
            }
            
            // Add child nodes to the list of nodes to check and log this action.
            let childNodes = currentNode.childNodes
            if !childNodes.isEmpty {
                print("Adding \(childNodes.count) child node(s) to check for removal.")
                nodesToCheck.append(contentsOf: childNodes)
            } else {
                print("No child nodes found for node: \(currentNode.name ?? "Unnamed")")
            }
        }
        
        // Log the final removal of the node from the parent node.
        print("Removing node: \(node.name ?? "Unnamed") from its parent node.")
        node.removeFromParentNode()
        print("Node removal process completed.")
    }


    
    


    
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
}

