//
//  ARViewManager.swift
//  FreeRealEstate
//
//

import UIKit
import ARKit
import SceneKit

@objc(ARViewManager)
class ARViewManager : RCTViewManager {
    
    var arView = ARView()
    
    // Returns an ARSCNView for React to present
    override func view() -> UIView {
        // Initialize defaults and member variables for ARView
        arView.bounds = UIScreen.main.bounds
        arView.delegate = self
        arView.scene = SCNScene()
        arView.autoenablesDefaultLighting = false
        arView.antialiasingMode = .multisampling4X
        arView.objectToPlace = "chair"
        arView.selectionBoxes = [SCNNode: BoundingBox]()
        
        // Add a tap gesture for object placement and selection
        let tapGesture = UITapGestureRecognizer(target: self, action:  #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Add a drag gesture for object movement
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        arView.addGestureRecognizer(dragGesture)
        
        // Add a rotate gesture for object rotation
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
        arView.addGestureRecognizer(rotateGesture)
        
        // Initialize the AWRTConfig
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.isLightEstimationEnabled = true
        
        // Run the ARView
        arView.session.run(config)
        
        return arView
    }
    
    func displayDebugInfo() {
        arView.showsStatistics = true
        arView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // , ARSCNDebugOptions.showWorldOrigin]
    }
    
    // Necessary for React Native
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
