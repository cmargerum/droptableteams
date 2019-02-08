//
//  ARViewManager+MultipeerConnectivity.swift
//  FreeRealEstate
//
//  Created by Cole Margerum on 2/5/19.
//  Copyright © 2019 Facebook. All rights reserved.
//
import ARKit
import SceneKit
import MultipeerConnectivity

extension ARViewManager {

    @objc func sendMap(_ node: ARSCNView!) {
        print("PEER: Map attempting to be shared")
        arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); print("PEER Can't send map"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
            print("PEER: Map sent\n")
        }
    }
    
    func sendNodeUpdate(forNode node: SCNNode, withAction action: SCNAction?) {
        var hasher = Hasher()
        hasher.combine(node)
        let hashValue = hasher.finalize()
        let nodeUpdate = MultipeerUpdate(node: node, nodeHash: hashValue, action: action)
        
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: nodeUpdate, requiringSecureCoding: true)
        else { fatalError("can't encode node update") }
        
        multipeerSession.sendToAllPeers(data)
    }

    func receivedData(_ data: Data, from peer: MCPeerID) {
        let update = MultipeerUpdate(data: data)
        
        if let nodeHash = update?.nodeHash, arView.objectHashTable[nodeHash] == nil, let newNode = update?.node {
            // Add new node, objectHashTable does not contain hash
            arView.scene.rootNode.addChildNode(newNode)
            let appearAction = SCNAction.fadeOpacity(to: 1.0, duration: 0.2)
            appearAction.timingMode = .easeInEaseOut
            newNode.runAction(appearAction)
            
            arView.objects.append(newNode)
            arView.objectHashTable[nodeHash] = newNode
        } else if let nodeHash = update?.nodeHash, let action = update?.action {
            // Update node with new info
            let updateNode = arView.objectHashTable[nodeHash]
            updateNode?.runAction(action)
        } else if let nodeHash = update?.nodeHash, let deadNode = arView.objectHashTable[nodeHash], let index = arView.objects.index(of: deadNode) {
            // Delete node
            // Might be able to combine with above else if, if nodes can be removed with actions
            // and we can determine that it is a removing action
            arView.objects.remove(at: index)
            arView.objectHashTable.removeValue(forKey: nodeHash)
            deadNode.removeFromParentNode()
        }
        
        // Putting this after update code bc 170 taught me that try catch is costly, and the above will fail if it's not
        // a map (hopefully)
        do {
            if mapProvider == nil, let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                mapProvider = peer
                return
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }
    
    
    // Everything below this does nothing because the UI isn't ready -> useless
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            sendMapButtonEnabled = false
            print("PEERS: ", multipeerSession.connectedPeers.isEmpty)
        case .extending:
            sendMapButtonEnabled = !multipeerSession.connectedPeers.isEmpty
            print("PEERS: ", multipeerSession.connectedPeers.isEmpty)
        case .mapped:
            sendMapButtonEnabled = !multipeerSession.connectedPeers.isEmpty
            print("PEERS: ", multipeerSession.connectedPeers.isEmpty)
        }
        //
        // mappingStatusLabel.text = frame.worldMappingStatus.description
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        sessionInfoLabel = message
        //sessionInfoView.isHidden = message.isEmpty
    }
    // Stop all this does nothing because UI ins't ready

}