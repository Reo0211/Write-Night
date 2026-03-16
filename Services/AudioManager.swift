import AVFoundation


final class AudioManager {
    static let shared = AudioManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let mixer  = AVAudioMixerNode()

    private init() {
        configureSession()
        configureEngine()
    }

    // MARK: - Session

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }

    // MARK: - Engine

    private func configureEngine() {
        engine.attach(player)
        engine.attach(mixer)

        mixer.outputVolume = 0
    }

    // MARK: - Playback


    func play(_ filename: String) {
        let name = (filename as NSString).deletingPathExtension
        let ext  = (filename as NSString).pathExtension

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("BGM file not found: \(filename)")
            return
        }

        currentFilename = filename
        do {
            let file   = try AVAudioFile(forReading: url)
            let format = file.processingFormat

            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(file.length)
            ) else { return }
            try file.read(into: buffer)


            engine.connect(player, to: mixer,               format: format)
            engine.connect(mixer,  to: engine.mainMixerNode, format: format)

            try engine.start()

            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            player.play()

            fadeVolume(to: 0.45, duration: 3.0)
            scheduleFadeLoop(duration: Double(file.length) / file.processingFormat.sampleRate)

        } catch {
            print("BGM error: \(error)")
        }
    }

    // 曲の終わり2秒前からフェードアウト → 先頭からフェードインで再生
    private var loopTimer: Timer?
    private var currentFilename: String = ""
    private var currentDuration: TimeInterval = 0

    private func scheduleFadeLoop(duration: TimeInterval) {
        currentDuration = duration
        loopTimer?.invalidate()
        let fadeOutDuration: TimeInterval = 1.0
        let delay = max(0, duration - fadeOutDuration)

        loopTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            // フェードアウト
            self.fadeVolume(to: 0.0, duration: fadeOutDuration) {
                // 停止して先頭から再生
                self.player.stop()
                guard let url = Bundle.main.url(
                    forResource: (self.currentFilename as NSString).deletingPathExtension,
                    withExtension: (self.currentFilename as NSString).pathExtension
                ) else { return }
                do {
                    let file = try AVAudioFile(forReading: url)
                    guard let buffer = AVAudioPCMBuffer(
                        pcmFormat: file.processingFormat,
                        frameCapacity: AVAudioFrameCount(file.length)
                    ) else { return }
                    try file.read(into: buffer)
                    self.player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                    self.player.play()
                    self.fadeVolume(to: 0.45, duration: 2.5)
                    self.scheduleFadeLoop(duration: Double(file.length) / file.processingFormat.sampleRate)
                } catch {
                    print("BGM restart error: \(error)")
                }
            }
        }
    }

    func stop() {
        loopTimer?.invalidate()
        fadeVolume(to: 0.0, duration: 2.0) { [weak self] in
            self?.player.stop()
            self?.engine.stop()
        }
    }

    func setVolume(_ volume: Float) {
        mixer.outputVolume = max(0, min(1, volume))
    }

    // MARK: - Sound Effects

    private let sfxFiles = ["sfx_star_1", "sfx_star_2", "sfx_star_3", "sfx_star_4"]
    private var sfxPlayers: [AVAudioPlayer] = []

    func playStarBirth()  { playSFX(name: "sfx_birth") }
    func playStarDelete() { playSFX(name: "sfx_delete") }
    func playPlanetTap() {
        let names = ["sfx_planet_tap_1", "sfx_planet_tap_2", "sfx_planet_tap_3"]
        playSFX(name: names.randomElement()!)
    }

    func playStarTap() {
        let name = sfxFiles.randomElement()!
        playSFX(name: name)
    }

    func playSpaceRipple() {
        playSFX(name: "sfx_space_ripple")
    }

    /// 効果音マスターボリューム
    private var sfxMasterVolume: Float {
        let stored = UserDefaults.standard.object(forKey: "sfxVolume")
        return stored == nil ? 0.35 : Float(UserDefaults.standard.double(forKey: "sfxVolume"))
    }

    private func playSFX(name: String) {
        let vol = sfxMasterVolume
        let exts = ["wav", "mp3", "aiff", "caf"]
        var url: URL?
        for ext in exts {
            if let u = Bundle.main.url(forResource: name, withExtension: ext) {
                url = u; break
            }
        }
        guard let url else { print("SFX not found: \(name)"); return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = vol
            player.prepareToPlay()
            player.play()
            sfxPlayers.append(player)
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.5) { [weak self] in
                self?.sfxPlayers.removeAll { !$0.isPlaying }
            }
        } catch {
            print("SFX error: \(error)")
        }
    }

    // MARK: - Fade

    private var fadeTimer: Timer?

    private func fadeVolume(to target: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        fadeTimer?.invalidate()
        let steps    = 60
        let interval = duration / Double(steps)
        let start    = mixer.outputVolume
        let delta    = (target - start) / Float(steps)
        var current  = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            current += 1
            self.mixer.outputVolume = start + delta * Float(current)
            if current >= steps {
                timer.invalidate()
                self.mixer.outputVolume = target
                completion?()
            }
        }
    }
}
