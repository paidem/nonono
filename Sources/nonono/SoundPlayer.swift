import AVFoundation
import CSounds

/// Two preloaded clips, embedded in the binary; starting one always cuts the other off.
final class SoundPlayer {
    private let wait: AVAudioPlayer
    private let phew: AVAudioPlayer

    init() throws {
        wait = try AVAudioPlayer(data: Data(bytes: nonono_wait_mp3(), count: nonono_wait_mp3_len()))
        phew = try AVAudioPlayer(data: Data(bytes: nonono_phew_mp3(), count: nonono_phew_mp3_len()))
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
