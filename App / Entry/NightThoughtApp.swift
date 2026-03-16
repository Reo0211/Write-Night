import SwiftUI

extension Notification.Name {
    static let showTutorial     = Notification.Name("showTutorial")
    static let showGuide        = Notification.Name("showGuide")
    static let showPlanetDetail = Notification.Name("showPlanetDetail")
    static let showPlanetList   = Notification.Name("showPlanetList")
    static let showAddPlanet    = Notification.Name("showAddPlanet")
    static let showMemoryPlanet = Notification.Name("showMemoryPlanet")
    static let planetTap        = Notification.Name("planetTap")
    static let moonExpired      = Notification.Name("moonExpired")   // object: Planet（期限切れ）
    static let moonShake        = Notification.Name("moonShake")     // 月シェイク
    static let showComet        = Notification.Name("showComet")     // 彗星カード表示
    static let spaceRipple      = Notification.Name("spaceRipple")   // 宇宙タップ
    static let cometTap         = Notification.Name("cometTap")      // 彗星タップエフェクト
}

@main
struct NightThoughtApp: App {
    @StateObject private var memoViewModel      = MemoViewModel()
    @StateObject private var skyViewModel       = SkyViewModel()
    @StateObject private var planetVM           = PlanetViewModel()
    @StateObject private var memoryPlanetVM     = MemoryPlanetViewModel()
    @State private var showLaunch:      Bool   = true
    @State private var showOnboarding:  Bool   = false
    @State private var showTutorial:    Bool   = false
    @State private var showGuide:       Bool   = false
    @State private var mainOverlay:     Double = 1
    @State private var expiredPlanet:   Planet? = nil

    @AppStorage("userName")         private var userName: String = ""
    @AppStorage("tutorialDone")     private var tutorialDone: Bool = false

    init() {
        AudioManager.shared.play("Night Thought.wav")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(memoViewModel)
                    .environmentObject(skyViewModel)
                    .environmentObject(planetVM)
                    .environmentObject(memoryPlanetVM)
                    .onAppear { memoViewModel.loadMemosIfNeeded() }
                



                // メイン画面フェードイン用オーバーレイ
                Color.black
                    .ignoresSafeArea()
                    .opacity(mainOverlay)
                    .allowsHitTesting(false)
                    .zIndex(1)

                // チュートリアル（メイン画面の上に重ねる）
                if showTutorial {
                    TutorialOverlay{
                        tutorialDone  = true
                        showTutorial  = false
                    }
                    .zIndex(8)
                }
//
//                if showGuide {
//                    TutorialOverlay(mode: .guide) {
//                        showGuide = false
//                    }
//                    .zIndex(9)
//                }

                // オンボーディング（初回のみ）
                if showOnboarding {
                    OnboardingView { name in
                        userName      = name
                        showOnboarding = false
                        showLaunch    = true
                    }
                    .zIndex(20)
                }

                // ローンチ画面
                if showLaunch && !showOnboarding {
                    LaunchView(
                        onFadeStart: {
                            withAnimation(.easeInOut(duration: 2.2)) { mainOverlay = 0 }
                            NotificationCenter.default.post(name: .startZoomIn, object: nil)
                        },
                        onComplete: {
                            showLaunch = false
                            // チュートリアル未完なら表示
                            if !tutorialDone {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showTutorial = true
                                }
                            }
                        }
                    )
                    .zIndex(10)
                }
                // 期限切れバナー（最前面）
                if let planet = expiredPlanet {
                    MoonExpiredBanner(planet: planet) {
                        expiredPlanet = nil
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(30)
                }
            }
            .onAppear {
                if userName.trimmingCharacters(in: .whitespaces).isEmpty {
                    showOnboarding = true
                    showLaunch     = false
                }
                planetVM.startDeadlineMonitoring()
            }
            .onReceive(NotificationCenter.default.publisher(for: .showTutorial)) { _ in
                showTutorial = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .showGuide)) { _ in
                showGuide = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .moonExpired)) { notif in
                guard let planet = notif.object as? Planet else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    expiredPlanet = planet
                }
            }
        }
    }
}
