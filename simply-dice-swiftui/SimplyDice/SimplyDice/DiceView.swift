import SwiftUI
import SceneKit

// MARK: - Pip drawing (port of drawPips() from ThreeDice.vue)

private func makeDiceFaceTexture(value: Int, size: CGFloat = 512) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
    return renderer.image { ctx in
        let context = ctx.cgContext

        // White face background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))

        // Pip colour: dark grey (matches #1a1a1a from Vue)
        context.setFillColor(UIColor(white: 0.1, alpha: 1).cgColor)

        let r = size / 9      // pip radius
        let c = size / 2      // center
        let q = size / 4      // quarter
        let tq = size * 0.75  // three-quarter

        func drawDot(_ x: CGFloat, _ y: CGFloat) {
            context.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }

        if value % 2 == 1 { drawDot(c, c) }           // center pip (1, 3, 5)
        if value > 1 {
            drawDot(q, q)                              // top-left
            drawDot(tq, tq)                            // bottom-right
        }
        if value > 3 {
            drawDot(tq, q)                             // top-right
            drawDot(q, tq)                             // bottom-left
        }
        if value == 6 {
            drawDot(q, c)                              // mid-left
            drawDot(tq, c)                             // mid-right
        }
    }
}

// MARK: - Face-to-euler mapping (from getTargetRotation() in ThreeDice.vue)

private func eulerAngles(for face: Int) -> SCNVector3 {
    switch face {
    case 1: return SCNVector3(0, -Float.pi / 2, 0)
    case 2: return SCNVector3(Float.pi / 2, 0, 0)
    case 3: return SCNVector3(0, 0, 0)
    case 4: return SCNVector3(Float.pi, 0, 0)
    case 5: return SCNVector3(-Float.pi / 2, 0, 0)
    case 6: return SCNVector3(0, Float.pi / 2, 0)
    default: return SCNVector3(0, 0, 0)
    }
}

// MARK: - SceneKit die node factory

private func makeDieNode() -> SCNNode {
    // SCNBox with chamferRadius matches RoundedBoxGeometry(1.5, 1.5, 1.5, 8, 0.2)
    let box = SCNBox(width: 1.5, height: 1.5, length: 1.5, chamferRadius: 0.2)

    // Six materials, one per face — order: +X, -X, +Y, -Y, +Z, -Z
    // Three.js face order (right, left, top, bottom, front, back) → values 1,6,2,5,3,4
    let faceValues = [1, 6, 2, 5, 3, 4]
    box.materials = faceValues.map { val in
        let mat = SCNMaterial()
        mat.diffuse.contents = makeDiceFaceTexture(value: val)
        mat.lightingModel = .lambert
        return mat
    }

    let node = SCNNode(geometry: box)
    return node
}

// MARK: - UIViewRepresentable wrapper

class DiceSceneCoordinator: NSObject {
    var scene: SCNScene!
    var dieNodes: [SCNNode] = []
    var isRolling = false
    var onRollComplete: (() -> Void)?

    func roll() -> Bool {
        guard !isRolling else { return false }
        isRolling = true

        let dieCount = dieNodes.count
        var completedDice = 0

        dieNodes.enumerated().forEach { (index, die) in
            let result = Int.random(in: 1...6)
            let target = eulerAngles(for: result)
            let spins = Float(2 + Int.random(in: 0...2)) * 2 * .pi

            let currentX = die.eulerAngles.x
            let currentY = die.eulerAngles.y

            // Total target = faceOffset + enough full spins to always spin forward
            let targetX = target.x + ceil(currentX / (2 * .pi)) * 2 * .pi + spins
            let targetY = target.y + ceil(currentY / (2 * .pi)) * 2 * .pi + spins

            // Rotation animation — CABasicAnimation on eulerAngles
            let duration: CFTimeInterval = index == 0 ? 1.2 : 1.4

            let rotAnim = CABasicAnimation(keyPath: "eulerAngles")
            rotAnim.fromValue = die.presentation.eulerAngles
            rotAnim.toValue = SCNVector3(targetX, targetY, target.z)
            rotAnim.duration = duration
            rotAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
            rotAnim.fillMode = .forwards
            rotAnim.isRemovedOnCompletion = false

            SCNTransaction.begin()
            SCNTransaction.animationDuration = duration
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            SCNTransaction.completionBlock = {
                die.eulerAngles = SCNVector3(targetX, targetY, target.z)
                die.removeAllAnimations()
                completedDice += 1
                if completedDice == dieCount {
                    self.isRolling = false
                    self.onRollComplete?()
                }
            }
            die.eulerAngles = SCNVector3(targetX, targetY, target.z)
            SCNTransaction.commit()

            // Z-bounce — move forward then back (matches GSAP yoyo)
            let originalZ = die.position.z
            let bounceOut = SCNAction.move(to: SCNVector3(die.position.x, die.position.y, originalZ + 1.5),
                                           duration: 0.4)
            bounceOut.timingMode = .easeOut
            let bounceBack = SCNAction.move(to: SCNVector3(die.position.x, die.position.y, originalZ),
                                            duration: 0.4)
            bounceBack.timingMode = .easeIn
            die.runAction(SCNAction.sequence([bounceOut, bounceBack]))
        }

        return true
    }
}

struct DiceView: UIViewRepresentable {
    var coordinator: DiceSceneCoordinator

    func makeCoordinator() -> DiceSceneCoordinator { coordinator }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = false

        let scene = SCNScene()
        context.coordinator.scene = scene

        // Camera — FOV 40, position z=12 (matches Three.js setup)
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 40
        cameraNode.position = SCNVector3(0, 0, 12)
        scene.rootNode.addChildNode(cameraNode)

        // Lighting — ambient 0.6, directional 1.2 at (5,10,8), point 1.0 at (-5,5,5)
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light!.intensity = 600
        scene.rootNode.addChildNode(ambient)

        let dirLight = SCNNode()
        dirLight.light = SCNLight()
        dirLight.light!.type = .directional
        dirLight.light!.intensity = 1200
        dirLight.position = SCNVector3(5, 10, 8)
        scene.rootNode.addChildNode(dirLight)

        let pointLight = SCNNode()
        pointLight.light = SCNLight()
        pointLight.light!.type = .omni
        pointLight.light!.intensity = 1000
        pointLight.position = SCNVector3(-5, 5, 5)
        scene.rootNode.addChildNode(pointLight)

        // Two dice — positioned like Vue: y=1.2 (die1), y=-1.2 (die2)
        let die1 = makeDieNode()
        die1.position = SCNVector3(0, 1.2, 0)
        die1.eulerAngles = SCNVector3(Float.random(in: 0..<Float.pi * 2),
                                      Float.random(in: 0..<Float.pi * 2), 0)

        let die2 = makeDieNode()
        die2.position = SCNVector3(0, -1.2, 0)
        die2.eulerAngles = SCNVector3(Float.random(in: 0..<Float.pi * 2),
                                      Float.random(in: 0..<Float.pi * 2), 0)

        scene.rootNode.addChildNode(die1)
        scene.rootNode.addChildNode(die2)
        context.coordinator.dieNodes = [die1, die2]

        scnView.scene = scene
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
