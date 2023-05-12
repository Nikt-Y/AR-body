//
//  BodySkeleton.swift
//  AR body
//
//  Created by Nik Y on 09.05.2023.
//

import Foundation
import RealityKit
import ARKit

class BodySkeleton: Entity {
    var joints: [String: Entity] = [:]
    var bones: [String: Entity] = [:]
    
    // Инициализатор класса BodySkeleton с ARBodyAnchor в качестве параметра - центра скелета
    required init(for bodyAnchor: ARBodyAnchor) {
        super.init()
        
        // Создание сфер для каждого сустава, используя jointNames из ARSkeletonDefinition.defaultBody3D
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            var jointRadius: Float = 0.05
            var jointColor: UIColor = .green
            
            // Установка цвета и размера сустава на основе конкретного имени сустава
            switch jointName {
            case "neck_1_joint", "neck_2_joint", "neck_3_joint", "neck_4_joint", "head_joint",
                "left_shoulder_1_joint", "right_shoulder_1_joint":
                jointRadius *= 0.5
            case "jaw_joint", "chin_joint", "left_eye_joint", "left_eyeLowerLid_joint", "left_eyeUpperLid_joint",
                "left_eyeball_joint", "nose_joint", "right_eye_joint", "right_eyeLowerLid_joint",
                "right_eyeUpperLid_joint", "right_eyeball_joint":
                jointRadius *= 0.2
                jointColor = .yellow
            case _ where jointName.hasPrefix("spine_"):
                jointRadius *= 0.75
            case "left_hand_joint", "right_hand_joint":
                jointRadius *= 1
                jointColor = .green
            case _ where jointName.hasPrefix("left_hand") || jointName.hasPrefix("right_hand"):
                jointRadius *= 0.25
                jointColor = .yellow
            case _ where jointName.hasPrefix("left_toes") || jointName.hasPrefix("right_toes"):
                jointRadius *= 0.5
                jointColor = .yellow
            default:
                jointRadius = 0.05
                jointColor = .green
            }
            
            // Создание сущности сустава с заданным радиусом и цветом
            let jointEntity = createJoint(radius: jointRadius, color: jointColor)
            joints[jointName] = jointEntity
            self.addChild(jointEntity)
        }
        
        // Создание кости для каждого элемента из перечисления Bones
        for bone in Bones.allCases {
            guard let skeletonBone = createSkeletonBone(bone: bone, bodyAnchor: bodyAnchor) else { continue }
            
            let boneEntity = createBoneEntity(for: skeletonBone)
            bones[bone.name] = boneEntity
            self.addChild(boneEntity)
        }
    }
    
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
    
    // Функция обновления позиции и ориентации суставов и костей на основе обновленного ARBodyAnchor
    func update(with bodyAnchor: ARBodyAnchor) {
        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        
        // Обновление позиции и ориентации каждого сустава
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            if let jointEntity = joints[jointName],
               let jointEntityTransform = bodyAnchor.skeleton.modelTransform(
                for: ARSkeleton.JointName(rawValue: jointName)
               ) {
                let jointEntityOffsetFromRoot = simd_make_float3(jointEntityTransform.columns.3)
                jointEntity.position = jointEntityOffsetFromRoot + rootPosition
                jointEntity.orientation = Transform(matrix: jointEntityTransform).rotation
            }
        }
        
        // Обновление позиции и ориентации каждой кости
        for bone in Bones.allCases {
            let boneName = bone.name
            guard let entity = bones[boneName],
                  let skeletonBone = createSkeletonBone(bone: bone, bodyAnchor: bodyAnchor)
            else { continue }
            
            entity.position = skeletonBone.centerPosition
            // Устанавливаем направление кости
            entity.look(at: skeletonBone.toJoint.position, from: skeletonBone.centerPosition, relativeTo: nil)
        }
    }
    
    // Функция создания сущности сустава с заданным радиусом и цветом
    private func createJoint(radius: Float, color: UIColor = .white) -> Entity {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }
    
    // Функция создания кости между двумя суставами на основе переданного объекта Bones и ARBodyAnchor
    private func createSkeletonBone(bone: Bones, bodyAnchor: ARBodyAnchor) -> SkeletonBone? {
        guard
            let fromJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointFromName)),
            let toJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointToName))
        else { return nil }
        
        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        
        // относительно корня (таза)
        let jointFromEntityOffsetFromRoot = simd_make_float3(fromJointEntityTransform.columns.3)
        // относительно мировой системы координат
        let jointFromEntityPosition = jointFromEntityOffsetFromRoot + rootPosition
        
        // относительно корня (таза)
        let jointToEntityOffsetFromRoot = simd_make_float3(toJointEntityTransform.columns.3)
        // относительно мировой системы координат
        let jointToEntityPosition = jointToEntityOffsetFromRoot + rootPosition
        
        
        let fromJoint = SkeletonJoint(name: bone.jointFromName, position: jointFromEntityPosition)
        let toJoint = SkeletonJoint(name: bone.jointToName, position: jointToEntityPosition)
        return SkeletonBone(fromJoint: fromJoint, toJoint: toJoint)
    }
    
    // Функция создания сущности кости на основе объекта SkeletonBone с заданным диаметром и цветом
    private func createBoneEntity(for skeletonBone: SkeletonBone, diameter: Float = 0.04, color: UIColor = .white) -> Entity {
        let mesh = MeshResource.generateBox(size: [diameter, diameter, skeletonBone.length], cornerRadius: diameter/2)
        let material = SimpleMaterial(color: color, roughness: 0.5, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }
}
