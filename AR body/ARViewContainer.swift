//
//  ARViewContainer.swift
//  AR body
//
//  Created by Nik Y on 09.05.2023.
//

import SwiftUI
import ARKit
import RealityKit

// Объявление переменной для хранения экземпляра BodySkeleton
private var bodySkeleton: BodySkeleton?
private let bodySkeletonAnchor = AnchorEntity()

struct ARViewContainer: UIViewRepresentable {
    typealias UIViewType = ARView
    
    // Создание и настройка ARView при инициализации
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        
        // Настройка ARView для отслеживания тела
        arView.setupForBodyTracking()
        // Добавление якоря скелета
        arView.scene.addAnchor(bodySkeletonAnchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }
}

// Расширение ARView для поддержки ARSessionDelegate и настройки отслеживания тела
extension ARView: ARSessionDelegate {
    // Функция настройки ARView для отслеживания тела
    func setupForBodyTracking() {
        // Создание конфигурации сессии AR для отслеживания тела
        let configuration = ARBodyTrackingConfiguration()
        // Запуск сессии с созданной конфигурацией
        self.session.run(configuration)
        
        // Установка делегата сессии на текущий экземпляр ARView
        self.session.delegate = self
    }
    
    // Функция делегата, вызываемая при обновлении якорей ARSession
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Обработка каждого обновленного якоря
        for anchor in anchors {
            // Если якорь является ARBodyAnchor (якорь для отслеживания тела)
            if let bodyAnchor = anchor as? ARBodyAnchor {
                // Если скелет уже существует
                if let skeleton = bodySkeleton {
                    // Обновление суставов и костей существующего BodySkeleton
                    skeleton.update(with: bodyAnchor)
                } else {
                    // Если экземпляра BodySkeleton еще не существует, это означает, что тело было обнаружено в первый раз.
                    // Создание экземпляра BodySkeleton и добавление его к якорю bodySkeletonAnchor
                    bodySkeleton = BodySkeleton(for: bodyAnchor)
                    bodySkeletonAnchor.addChild(bodySkeleton!)
                }
            }
        }
    }
}
