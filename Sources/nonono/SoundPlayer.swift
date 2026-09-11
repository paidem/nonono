import AVFoundation
import CSounds
import NonoCore

/// Preloaded clips, embedded in the binary; starting one always cuts the others off.
final class SoundPlayer {
    private let players: [Clip: AVAudioPlayer]

    init() throws {
        players = [
            .wait: try AVAudioPlayer(data: Data(bytes: nonono_wait_mp3(), count: nonono_wait_mp3_len())),
            .phew: try AVAudioPlayer(data: Data(bytes: nonono_phew_mp3(), count: nonono_phew_mp3_len())),
            .violin: try AVAudioPlayer(data: Data(bytes: nonono_violin_mp3(), count: nonono_violin_mp3_len())),
        ]
        players.values.forEach { $0.prepareToPlay() }
    }

    func play(_ clip: Clip) {
        stopAll()
        guard let p = players[clip] else { return }
        p.play()
    }

    func stopAll() {
        for p in players.values {
            p.stop()
            p.currentTime = 0
        }
    }

    func perform(_ action: SoundAction) {
        switch action {
        case .play(let clip): play(clip)
        case .stop: stopAll()
        }
    }
}
