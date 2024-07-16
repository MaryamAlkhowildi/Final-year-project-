import ARKit

class ARSCNViewControl: NSObject, ARSCNViewDelegate, ARSessionDelegate {
    weak var viewController: ViewController?
    weak var alertController: ARAlertController?

    //var planes = [UUID: ARPlane]() // Dictionary to keep track of all planes

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
        let plane = ARPlane(anchor: planeAnchor, isHidden: false, withMaterial: ARPlane.currentMaterial()!)
        viewController?.planes[anchor.identifier] = plane // Store the plane
        node.addChildNode(plane) // Add the ARPlane node to the scene
        
        // Notify the user a plane has been detected
        DispatchQueue.main.async {
            self.viewController?.addNodeButton.isHidden = false
            self.viewController?.snapshotButton.isHidden = false
            self.alertController?.showOverlyText("SURFACE DETECTED, TAP TO PLACE AN OBJECT", withDuration: 2)
        }
    }


    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let plane = viewController?.planes[anchor.identifier] else { return }
        
        // Update the plane's position and dimensions
        plane.update(anchor: planeAnchor)
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Remove the plane from the dictionary if it's merged or removed
        viewController?.planes.removeValue(forKey: anchor.identifier)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let estimate = viewController?.sceneView.session.currentFrame?.lightEstimate else {
            return
        }
        
        // A value of 1000 is considered neutral, lighting environment intensity normalizes
        // 1.0 to neutral so we need to scale the ambientIntensity value
        let intensity = estimate.ambientIntensity / 1000.0
        viewController?.sceneView.scene.lightingEnvironment.intensity = intensity
    }


    // MARK: - ARSessionObserver Methods

    // Called when the AR session fails (e.g., due to a lack of device capabilities).
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.alertController?.showOverlyText("PLEASE TRY RESETTING THE SESSION", withDuration: 1)
        }
    }

    // Called when the AR session is interrupted (e.g., by presenting a different app or locking the device).
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            self?.alertController?.showOverlyText("SESSION INTERRUPTED", withDuration: 1)
        }
    }

    // Called when the interruption of an AR session ends, suggesting to refresh or restart the session.
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.refreshSession()
        }
    }
}
