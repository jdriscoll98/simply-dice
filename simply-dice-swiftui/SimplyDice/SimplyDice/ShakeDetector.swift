import CoreMotion
import Combine

class ShakeDetector: ObservableObject {
    var onShake: (() -> Void)?

    private let motionManager = CMMotionManager()
    private var lastShakeTime: Date = .distantPast

    // 2.5g threshold, 500ms cooldown
    private let threshold: Double = 2.5
    private let cooldown: TimeInterval = 0.5

    func start() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0  // 60Hz
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            let a = data.acceleration
            let magnitude = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            if magnitude > self.threshold {
                let now = Date()
                if now.timeIntervalSince(self.lastShakeTime) > self.cooldown {
                    self.lastShakeTime = now
                    self.onShake?()
                }
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}
