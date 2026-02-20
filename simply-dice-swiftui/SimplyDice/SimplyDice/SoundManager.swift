import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    private var player: AVAudioPlayer?
    private var fadeTimer: Timer?

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play() {
        // Cancel any in-progress fade
        fadeTimer?.invalidate()
        fadeTimer = nil

        guard let url = Bundle.main.url(forResource: "dice_roll", withExtension: "mp3") else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 1.0
            player?.play()
        } catch {
            // Silently ignore audio errors
        }
    }

    func fadeOut() {
        guard let player = player, player.isPlaying else { return }

        fadeTimer?.invalidate()
        // Matches 50ms interval, -0.1 per tick from Vue original
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, let p = self.player else {
                timer.invalidate()
                return
            }
            if p.volume > 0.1 {
                p.volume = max(0, p.volume - 0.1)
            } else {
                p.stop()
                timer.invalidate()
                self.fadeTimer = nil
            }
        }
    }
}
