//
//  ARViewManager.swift
//  FreeRealEstate
//
//

import UIKit
import ARKit
import SceneKit
import MultipeerConnectivity

@objc(ARViewManager)
class ARViewManager : RCTViewManager {
    
    var arView = ARView()
    var arViewModel = ARViewModel()
    
    var mapProvider: MCPeerID?
    lazy var multipeerSession: MultipeerSession = MultipeerSession()
    
    // REPLACE WITH REACT BUTTONS
    var sendMapButtonEnabled: Bool = false
    
    // Returns an ARSCNView for React to present
    override func view() -> UIView {
        // Configure dataHandler
        multipeerSession.receivedDataHandler = receivedData
        
        // Initialize defaults and member variables for ARView
        arView.bounds = UIScreen.main.bounds
        arView.delegate = self
        arView.scene = SCNScene()
        arView.autoenablesDefaultLighting = true
        arView.antialiasingMode = .multisampling4X
        
        arViewModel.arView = arView
        arViewModel.objectToPlace = "chair_1"
        arViewModel.peerLabelHidden = true
        arViewModel.selectionBoxes = [SCNNode: BoundingBox]()
        
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
        arView.session.delegate = self
        setupDirectionalLighting(queue: DispatchQueue.main)
        addPlaceButton()
        addConfirmButton()
        addRemoveButton()
        addPeersLabel()
        
        let displayName = multipeerSession.myPeerID.displayName
        if displayName == "Michael’s iPad" { arViewModel.canSendMap = true }
        
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
