//
//  ARViewContainer.swift
//  AR body
//
//  Created by Nik Y on 09.05.2023.
//

import SwiftUI
import ARKit
import RealityKit

private var bodySkeleton: BodySkeleton?
private let bodySkeletonAnchor = AnchorEntity()

struct ARViewContainer: UIViewRepresentable {
    typealias UIViewType = ARView
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        
        arView.setupForBodyTracking()
        arView.scene.addAnchor(bodySkeletonAnchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }
}

extension ARView: ARSessionDelegate {
    func setupForBodyTracking() {
        let configuration = ARBodyTrackingConfiguration()
        self.session.run(configuration)
        
        self.session.delegate = self
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                if let skeleton = bodySkeleton {
                    // // Body Skeleton already exists, update all joints and bones
                    skeleton.update(with: bodyAnchor)
                } else {
                    // // Body Skeleton doesn't yet exist. This means a body has been detected for the first time.
                    // // Create body Skeleton entity and add it to the body Skeleton Anchor
                    bodySkeleton = BodySkeleton(for: bodyAnchor)
                    bodySkeletonAnchor.addChild(bodySkeleton!)
                }
            }
        }
    }
}
