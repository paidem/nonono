import AVFoundation

/// Two preloaded clips; starting one always cuts the other off.
final class SoundPlayer {
    private let wait: AVAudioPlayer
    private let phew: AVAudioPlayer

    init(soundsDir: URL) throws {
        wait = try AVAudioPlayer(contentsOf: soundsDir.appendingPathComponent("no-no-wait-wait.mp3"))
        phew = try AVAudioPlayer(contentsOf: soundsDir.appendingPathComponent("luigi-phew-mamma-mia.mp3"))
        wait.prepareToPlay()
        phew.prepareToPlay()
    }

    func playWait() { play(wait, stopping: phew) }
    func playPhew() { play(phew, stopping: wait) }

    private func play(_ player: AVAudioPlayer, stopping other: AVAudioPlayer) {
        other.stop()
        other.currentTime = 0
        player.stop()
        player.currentTime = 0
        player.play()
    }
}
