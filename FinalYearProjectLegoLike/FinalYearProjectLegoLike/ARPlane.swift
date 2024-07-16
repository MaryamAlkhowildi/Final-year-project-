import UIKit
import ARKit


// Materials dictionary to cache materials for reuse
var materials: [String:SCNMaterial] = [:]

// PBRMaterial class for creating and managing physically based materials
class PBRMaterial: NSObject {
    class func materialNamed(name: String) -> SCNMaterial {
        var material = materials[name]
        if let material = material {
            return material
        }
        
        material = SCNMaterial()
        material!.lightingModel = SCNMaterial.LightingModel.physicallyBased
        material!.diffuse.contents = UIImage(named: "plane.png") // Ensure this image exists in your assets
        material!.diffuse.wrapS = SCNWrapMode.repeat
        material!.diffuse.wrapT = SCNWrapMode.repeat
        materials[name] = material
        return material!
    }
}

class ARPlane: SCNNode {
    
    var anchor: ARPlaneAnchor
    var planeGeometry: SCNBox
    
    
    init(anchor: ARPlaneAnchor, isHidden hidden: Bool, withMaterial material: SCNMaterial) {
        self.anchor = anchor
        let width = CGFloat(anchor.extent.x)
        let length = CGFloat(anchor.extent.z)
        
        // Using a SCNBox and not SCNPlane to make it easy for the geometry we add to the
        // scene to interact with the plane.
        
        // For the physics engine to work properly give the plane some height so we get interactions
        // between the plane and the gometry we add to the scene
        let planeHeight: CGFloat = 0.01
        
        planeGeometry = SCNBox(width: width, height: planeHeight, length: length, chamferRadius: 0)
        
        super.init()
        self.name = "ARPlane"
        
        // Since we are using a cube, we only want to render the tron grid
        // on the top face, make the other sides transparent
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        
        if hidden {
            self.planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial]
        } else {
            self.planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, material, transparentMaterial]
        }
        
        let planeNode = SCNNode(geometry: planeGeometry)
        
        // Since our plane has some height, move it down to be at the actual surface
        planeNode.position = SCNVector3Make(0, Float(-planeHeight / 2), 0)
        
        // Give the plane a physics body so that items we add to the scene interact with it
        planeNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.static, shape: SCNPhysicsShape(geometry: self.planeGeometry, options: nil))
        
        planeNode.physicsBody?.categoryBitMask = ARCollision.bottom.rawValue
        planeNode.physicsBody?.collisionBitMask = ARCollision.block.rawValue // Collide with blocks
     
        self.addChildNode(planeNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func currentMaterial() -> SCNMaterial? {
        var materialName: String
        materialName = "plane"
        
        return PBRMaterial.materialNamed(name: materialName)
    }
    
    func update(anchor: ARPlaneAnchor) {
        // As the user moves around the extend and location of the plane
        // may be updated. We need to update our 3D geometry to match the
        // new parameters of the plane.
        self.planeGeometry.width = CGFloat(anchor.extent.x)
        self.planeGeometry.length = CGFloat(anchor.extent.z)
        
        // When the plane is first created it's center is 0,0,0 and the nodes
        // transform contains the translation parameters. As the plane is updated
        // the planes translation remains the same but it's center is updated so
        // we need to update the 3D geometry position
        self.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        
        let node = self.childNodes.first
        node?.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: SCNPhysicsShape(geometry: self.planeGeometry, options: nil))
        
        node?.physicsBody?.categoryBitMask = ARCollision.bottom.rawValue
        node?.physicsBody?.collisionBitMask = ARCollision.block.rawValue // Ensure it collides with blocks
    }
    
    
    func hide() {
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        self.planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial]
    }
    
    
}
