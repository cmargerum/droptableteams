//
//  ARViewManager.swift
//  FreeRealEstate
//
//  Created by Artem Jivotovski on 11/14/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

@objc(ARViewManager)
class ARViewManager : RCTViewManager, ARSCNViewDelegate {
    
    var arView = ARSCNView()
    var sceneManager = ARSCNManager()
    var planes = [UUID : VirtualPlane]()
    var selectedPlane: VirtualPlane?
    var shipNode: SCNNode {
        let scnFileName = "art.scnassets/ship.scn"
        let objectScene = SCNScene(named: scnFileName)!
        let objectNode = objectScene.rootNode.childNode(withName: "ship", recursively: true)!
        return objectNode
    }
    
    // Returns an ARSCNView for React to present
    override func view() -> UIView {
        
        // Set the bounds of the view to be the screen
        arView.bounds = UIScreen.main.bounds
        
        // Get the scene and config from the SceneManager
        arView.delegate = self
        arView.scene = sceneManager.getScene()
        let config = sceneManager.getConfig()
        displayDebugInfo()
        
        // Run the ARView
        arView.session.run(config)
        
        let tapGesture = UITapGestureRecognizer(target: self, action:  #selector(scnTapped(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }
    
    @objc func scnTapped(_ sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: arView)
        let hits = arView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        
        //
        
        if hits.count > 0, let hitResult = hits.last, let identifier = hitResult.anchor?.identifier {
            selectedPlane = planes[identifier]
            let ship = shipNode.clone()
            let rotation = simd_float4x4(SCNMatrix4MakeRotation(arView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))
            let hitTransform = simd_mul(hitResult.worldTransform, rotation)
            ship.transform = SCNMatrix4(hitTransform)
            
            // let hitVector = SCNVector3(hitTransform.columns.3.x, hitTransform.columns.3.y, hitTransform.columns.3.z)
            // ship.position = hitVector
            
            ship.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
            // arView.session.add(anchor: ARAnchor(transform: hitTransform))
            sceneManager.scene.rootNode.addChildNode(ship)
        } else {
            print("Plane not touched or planes not yet detected")
        }
    }
    
    @objc func addObject(_ node: ARSCNView!,  count: NSNumber) {
        print(count);
        DispatchQueue.main.async {
            self.sceneManager.addObject(objectName: "ship")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor {
            let plane = VirtualPlane(anchor: arPlaneAnchor)
            planes[arPlaneAnchor.identifier] = plane
            node.addChildNode(plane)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let plane = planes[arPlaneAnchor.identifier] {
            plane.updateWithNewAnchor(arPlaneAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let index = planes.index(forKey: arPlaneAnchor.identifier) {
            planes.remove(at: index)
        }
    }
    
    func displayDebugInfo() {
        arView.showsStatistics = true
        arView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // , ARSCNDebugOptions.showWorldOrigin]
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
