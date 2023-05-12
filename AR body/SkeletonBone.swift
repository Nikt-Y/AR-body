//
//  SkeletonBone.swift
//  AR body
//
//  Created by Nik Y on 09.05.2023.
//

import Foundation
import RealityKit

struct SkeletonBone {
    var fromJoint: SkeletonJoint
    var toJoint: SkeletonJoint
    
    // Середина кости
    var centerPosition: SIMD3<Float> {
        [(fromJoint.position.x + toJoint.position.x)/2, (fromJoint.position.y + toJoint.position.y)/2, (fromJoint.position.z + toJoint.position.z)/2]
    }
    
    // Длина кости
    var length: Float {
        simd_distance(fromJoint.position, toJoint.position)
    }
}
