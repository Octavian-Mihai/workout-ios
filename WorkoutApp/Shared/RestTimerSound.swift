import AudioToolbox
import AVFoundation

enum RestTimerSound {
    private static let mailReceived: SystemSoundID = 1005

    static func play() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        AudioServicesPlaySystemSound(mailReceived)
    }
}
