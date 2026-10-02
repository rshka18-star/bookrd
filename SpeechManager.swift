import Foundation
import AVFoundation
import MediaPlayer

final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var progress: Double = 0
    @Published var currentPage = 1
    @Published var rate: Float = 0.48

    private let synth = AVSpeechSynthesizer()
    private var segments: [(page: Int, text: String)] = []
    private var segmentIndex = 0
    private var currentTitle = "Spfive Reader"
    private var totalSegments = 1

    override init() {
        super.init()
        synth.delegate = self
        configureAudioSession()
        configureRemoteCommands()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .allowAirPlay, .allowBluetoothA2DP]
            )
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func read(book: LoadedBook, fromPage: Int) {
        stop()
        configureAudioSession()

        currentTitle = book.title
        currentPage = max(1, min(fromPage, book.pages.count))

        let selected = book.pages.filter { $0.number >= currentPage }
        segments = selected.flatMap { page in
            Self.chunk(page.text).map { (page: page.number, text: $0) }
        }
        totalSegments = max(segments.count, 1)
        segmentIndex = 0
        progress = 0

        speakNext()
    }

    func readSinglePage(book: LoadedBook, page: Int) {
        stop()
        configureAudioSession()

        let pageNum = max(1, min(page, book.pages.count))
        currentTitle = book.title
        currentPage = pageNum

        guard let selected = book.pages.first(where: {$0.number == pageNum}) else { return }
        segments = Self.chunk(selected.text).map { (page: pageNum, text: $0) }
        totalSegments = max(segments.count, 1)
        segmentIndex = 0
        progress = 0

        speakNext()
    }

    func pause() {
        if synth.pauseSpeaking(at: .word) {
            isPaused = true
            isSpeaking = false
            updateNowPlaying()
        }
    }

    func resume() {
        configureAudioSession()
        if synth.continueSpeaking() {
            isPaused = false
            isSpeaking = true
            updateNowPlaying()
        }
    }

    func toggle() {
        if isSpeaking { pause() }
        else if isPaused { resume() }
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        progress = 0
        segments.removeAll()
        segmentIndex = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func skipForwardSegment() {
        synth.stopSpeaking(at: .immediate)
        segmentIndex = min(segmentIndex + 1, segments.count)
        speakNext()
    }

    func skipBackSegment() {
        synth.stopSpeaking(at: .immediate)
        segmentIndex = max(segmentIndex - 1, 0)
        speakNext()
    }

    private func speakNext() {
        guard segmentIndex < segments.count else {
            isSpeaking = false
            isPaused = false
            progress = 1
            updateNowPlaying()
            return
        }

        configureAudioSession()

        let seg = segments[segmentIndex]
        currentPage = seg.page

        let u = AVSpeechUtterance(string: seg.text)
        u.voice = AVSpeechSynthesisVoice(language: "en-IE")
            ?? AVSpeechSynthesisVoice(language: "en-GB")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        u.rate = rate
        u.volume = 1.0
        u.pitchMultiplier = 1.0

        synth.speak(u)
    }

    private static func chunk(_ text: String) -> [String] {
        let clean = text.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !clean.isEmpty else { return [] }

        let words = clean.split(separator: " ")
        var result: [String] = []
        var current = ""

        for word in words {
            let candidate = current.isEmpty ? String(word) : current + " " + word
            if candidate.count > 900 {
                if !current.isEmpty { result.append(current) }
                current = String(word)
            } else {
                current = candidate
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    private func configureRemoteCommands() {
        let remote = MPRemoteCommandCenter.shared()

        remote.playCommand.isEnabled = true
        remote.pauseCommand.isEnabled = true
        remote.stopCommand.isEnabled = true
        remote.skipForwardCommand.isEnabled = true
        remote.skipBackwardCommand.isEnabled = true

        remote.skipForwardCommand.preferredIntervals = [15]
        remote.skipBackwardCommand.preferredIntervals = [15]

        remote.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }

        remote.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        remote.stopCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }

        remote.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForwardSegment()
            return .success
        }

        remote.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackSegment()
            return .success
        }
    }

    private func updateNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: currentTitle,
            MPMediaItemPropertyArtist: "Spfive Book Reader • Page \(currentPage)",
            MPNowPlayingInfoPropertyPlaybackRate: isSpeaking ? 1.0 : 0.0
        ]
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.isPaused = false
            self.updateNowPlaying()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = true
            self.updateNowPlaying()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.isPaused = false
            self.updateNowPlaying()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.segmentIndex += 1
            self.progress = min(Double(self.segmentIndex) / Double(self.totalSegments), 1.0)
            self.speakNext()
        }
    }
}
