import SwiftUI
import Combine
import UIKit

struct ContentView: View {
    @EnvironmentObject private var memoVM:   MemoViewModel
    @EnvironmentObject private var skyVM:    SkyViewModel
    @EnvironmentObject private var planetVM: PlanetViewModel
    @EnvironmentObject private var memoryPlanetVM: MemoryPlanetViewModel

    @State private var showingAddMemo    = false
    @State private var showingMemoList   = false
    @State private var showingSettings   = false
    @State private var birthTarget:       CGPoint? = nil
    @State private var planetTapTarget:   CGPoint? = nil
    @State private var spaceRippleTarget: CGPoint? = nil
    @State private var birthMemo:         Memo?    = nil
    @State private var screenSize:        CGSize   = .zero
    @State private var supernovaTarget:   CGPoint? = nil
    @State private var pendingTitle:      String   = ""
    @State private var pendingBody:       String   = ""
    @State private var pendingEmotionHue: Double   = 0.5
    @State private var pendingPosition:   CGPoint  = .zero
    @State private var pendingTarget:     CGPoint  = .zero
    @State private var selectedMemo:      Memo?    = nil
    @State private var currentTime:       Date     = Date()
    @State private var popupLabel:        String   = ""
    @State private var popupOpacity:      Double   = 0
    @State private var showShootingStar:  Bool     = false
    @State private var showPromptCard:    Bool     = false
    @State private var currentPrompt:     String   = ""
    @State private var showComet:         Bool     = false
    @State private var cometMemo:         Memo?    = nil
    @State private var showAddPlanet:         Bool     = false
    @State private var selectedPlanet:        Planet?  = nil
    @State private var showingPlanetList:      Bool     = false
    @State private var selectedMemoryPlanet:  MemoryPlanetType? = nil
    @State private var pendingMilestones:     [MilestoneKind]  = []
    @State private var showingMilestone:      MilestoneKind?   = nil
    @State private var formingPlanet:         MemoryPlanetType? = nil
    @State private var showEndRoll:           Bool             = false

    @AppStorage("userName") private var userName: String = ""

    @State private var isLandscape: Bool = false

    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Computed

    private var currentTimeText: String {
        let f = DateFormatter()
        f.calendar   = Calendar(identifier: .gregorian)
        f.dateFormat = "HH:mm"
        return f.string(from: currentTime)
    }

    private var lastMemoText: String {
        guard let last = memoVM.memos.sorted(by: { $0.createdAt > $1.createdAt }).first else { return "–" }
        let f = DateFormatter()
        f.calendar   = Calendar(identifier: .gregorian)
        f.dateFormat = "MM/dd  HH:mm"
        return f.string(from: last.createdAt)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            SkyView(selectedMemo: $selectedMemo)
                .environmentObject(memoryPlanetVM)
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(!isLandscape)

            titleBar

            if let memo = selectedMemo {
                MemoDetailCard(memo: memo) {
                    selectedMemo = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }

            if let planet = selectedMemoryPlanet {
                MemoryPlanetDetailView(
                    planet: planet,
                    memos:  memoryPlanetVM.memos(for: planet, allMemos: memoVM.memos)
                ) {
                    selectedMemoryPlanet = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(7)
            }

            if showAddPlanet {
                AddPlanetView { title, note, deadline in
                    planetVM.addPlanet(title: title, body: note, deadline: deadline)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showAddPlanet = false
                    }
                } onCancel: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showAddPlanet = false
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(6)
            }

            if showingPlanetList {
                PlanetListView(
                    onClose: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showingPlanetList = false
                        }
                    },
                    onSelect: { planet in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showingPlanetList = false
                            selectedPlanet = planet
                        }
                    },
                    onAddNew: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showingPlanetList = false
                            showAddPlanet = true
                        }
                    }
                )
                .environmentObject(planetVM)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(7)
            }

            if let planet = selectedPlanet {
                PlanetDetailView(planet: planet) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        selectedPlanet = nil
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        planetVM.complete(planet)
                    }
                } onDelete: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        selectedPlanet = nil
                    }
                    planetVM.delete(planet)
                }
                .environmentObject(planetVM)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(7)
            }

            if let target = birthTarget {
                birthOverlay(target)
                    .zIndex(4)
            }

            if let target = planetTapTarget {
                PlanetTapOverlay(position: target) {
                    planetTapTarget = nil
                }
                .ignoresSafeArea()
                .zIndex(5)
            }

            // 宇宙タップのさざ波
            if let target = spaceRippleTarget {
                SpaceRippleOverlay(position: target) {
                    spaceRippleTarget = nil
                }
                .zIndex(2)
            }

            if showShootingStar {
                ShootingStarView { prompt in
                    showShootingStar = false
                    currentPrompt    = prompt
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showPromptCard = true
                    }
                } onMissed: {
                    showShootingStar = false
                }
                .allowsHitTesting(true)
                .zIndex(3)
            }

            if showComet {
                CometView(memos: memoVM.memos) { memo in
                    showComet  = false
                    cometMemo  = memo
                } onMissed: {
                    showComet = false
                }
                .allowsHitTesting(true)
                .zIndex(3)
            }

            if let memo = cometMemo {
                CometMemoryCard(memo: memo) {
                    cometMemo = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(4)
            }

            if showPromptCard {
                PromptCard(prompt: currentPrompt) {
                    showPromptCard = false
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(3)
            }

            if let sCenter = supernovaTarget {
                SupernovaOverlay(center: sCenter) {
                    supernovaTarget = nil
                }
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .zIndex(5)
            }

            if let planet = formingPlanet {
                let archiveMemos = memoryPlanetVM.memos(for: planet, allMemos: memoVM.memos)
                PlanetFormationOverlay(planet: planet, memos: archiveMemos) {
                    formingPlanet = nil
                    if showingMilestone == nil, !pendingMilestones.isEmpty {
                        showingMilestone = pendingMilestones.removeFirst()
                    }
                }
                .zIndex(8)
                .transition(.opacity)
            }

            if let kind = showingMilestone {
                MilestoneUnlockOverlay(kind: kind) {
                    showingMilestone = nil
                    guard !pendingMilestones.isEmpty else { return }
                    let next = pendingMilestones.removeFirst()
                    let isPlanet = MemoryPlanetType.allCases.contains { $0.milestonekind == next }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        if isPlanet, let p = MemoryPlanetType.allCases.first(where: { $0.milestonekind == next }) {
                            formingPlanet = p
                        } else {
                            showingMilestone = next
                        }
                    }
                }
                .zIndex(9)
                .transition(.opacity)
            }

            bottomBar
                .allowsHitTesting(!isLandscape)

            if showEndRoll {
                EndRollView(
                    memoCount:     memoVM.memos.count,
                    firstMemoDate: memoVM.memos.sorted { $0.createdAt < $1.createdAt }.first?.createdAt
                ) {
                    showEndRoll = false
                }
                .transition(.opacity)
                .zIndex(25)
            }

            if isLandscape {
                StandClockOverlay(currentTime: currentTime)
                    .transition(.opacity)
                    .zIndex(20)
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showingAddMemo)  { addMemoSheet }
        .sheet(isPresented: $showingMemoList) { MemoListView().environment(\.colorScheme, .dark) }
        .sheet(isPresented: $showingSettings) { SettingsView().environmentObject(memoVM).environment(\.colorScheme, .dark) }
        .onReceive(clockTimer) { t in currentTime = t }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let o = UIDevice.current.orientation
            withAnimation(.easeInOut(duration: 0.4)) {
                isLandscape = o.isLandscape
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spaceRipple)) { notif in
            guard let pos = notif.object as? CGPoint else { return }
            spaceRippleTarget = pos
        }
        .onReceive(NotificationCenter.default.publisher(for: .showMemoryPlanet)) { notif in
            if let planet = notif.object as? MemoryPlanetType {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    selectedMemoryPlanet = planet
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPlanetList)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                showingPlanetList = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPlanetDetail)) { notif in
            if let planet = notif.object as? Planet {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    selectedPlanet = planet
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddPlanet)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                showAddPlanet = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .starSupernova)) { notif in
            guard let pos = notif.object as? CGPoint else { return }
            supernovaTarget = pos
        }
        .onReceive(NotificationCenter.default.publisher(for: .planetTap)) { notif in
            guard let pos = notif.object as? CGPoint else { return }
            planetTapTarget = pos
        }
        .onAppear {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            skyVM.syncFromMemos(memoVM.memos)
            memoryPlanetVM.sync(memoCount: memoVM.memos.count)
            MilestoneManager.shared.checkAndUnlock(memoCount: memoVM.memos.count)
            planetVM.syncUnlockState()
            scheduleShootingStar()
            scheduleComet()
        }
        .onChange(of: memoVM.memos.count) { count in
            skyVM.syncFromMemos(memoVM.memos)
            memoryPlanetVM.sync(memoCount: count)
            let newly = MilestoneManager.shared.checkAndUnlock(memoCount: count)
            if newly.contains(.reminderMoon) { planetVM.syncUnlockState() }
            if newly.contains(.endroll) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation { showEndRoll = true }
                }
            }
            for kind in newly {
                guard kind != .endroll else { continue }
                let isPlanetKind = MemoryPlanetType.allCases.contains { $0.milestonekind == kind }
                if isPlanetKind {
                    if let planet = MemoryPlanetType.allCases.first(where: { $0.milestonekind == kind }) {
                        if formingPlanet == nil && showingMilestone == nil {
                            formingPlanet = planet
                            pendingMilestones.append(kind)
                        } else {
                            pendingMilestones.append(kind)
                        }
                    }
                } else {
                    if showingMilestone == nil && formingPlanet == nil {
                        showingMilestone = kind
                    } else {
                        pendingMilestones.append(kind)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedMemo?.id)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedMemoryPlanet)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedPlanet)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showingPlanetList)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showAddPlanet)
    }

    // MARK: - Sub Views

    private var titleBar: some View {
        VStack {
            HStack {
                Text(userName.isEmpty ? "日記で作る夜空" : "\(userName)の夜空")
                    .font(.custom("HiraMinProN-W6", size: 20))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.leading, 20)
                    .padding(.top, 12)
                Spacer()
            }
            Spacer()
        }
    }

    private var bottomBar: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                infoPanel
                    .padding(.leading, 22)
                    .padding(.bottom, 36)
                Spacer()
                sparkleMenu
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
            }
        }
    }

    private var infoPanel: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(memoVM.memos.count)")
                    .font(.custom("HiraMinProN-W3", size: 28))
                    .foregroundColor(.white.opacity(0.85))
                    .onTapGesture { showPopup("星の数") }
                Rectangle()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 72, height: 0.5)
                    .padding(.vertical, 2)
                Text(lastMemoText)
                    .font(.custom("HiraMinProN-W3", size: 11))
                    .foregroundColor(.white.opacity(0.50))
                    .onTapGesture { showPopup("最後に作成した時刻") }
                Text(currentTimeText)
                    .font(.custom("HiraMinProN-W3", size: 11))
                    .foregroundColor(.white.opacity(0.50))
                    .onTapGesture { showPopup("現在時刻") }
            }
            if !popupLabel.isEmpty {
                Text(popupLabel)
                    .font(.custom("HiraMinProN-W3", size: 12))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                            )
                    )
                    .opacity(popupOpacity)
                    .transition(.opacity)
            }
        }
    }

    private var sparkleMenu: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Menu {
                Button { showingSettings = true } label: { Label("設定", systemImage: "gearshape") }
                Button { showingMemoList = true  } label: { Label("星一覧", systemImage: "list.star") }
                Button { showingAddMemo  = true  } label: { Label("星を作成", systemImage: "star.fill") }
            } label: {
                Image(systemName: "sparkle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .glassEffect(.regular.interactive(), in: Circle())
            }
        }
    }

    @ViewBuilder
    private func birthOverlay(_ target: CGPoint) -> some View {
        StarBirthOverlay(target: target) {
            let memo = memoVM.createMemo(
                title: pendingTitle,
                body: pendingBody,
                emotionHue: pendingEmotionHue,
                at: pendingPosition
            )
            skyVM.registerMemo(memo)
            birthMemo = memo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let sd = skyVM.memoStars.first(where: { $0.id == memo.id }) {
                    let sel = SIMD3<Float>(Float(sd.position.x), Float(sd.position.y), 0.0)
                    NotificationCenter.default.post(name: .starBirthSparkle, object: sel)
                }
                birthTarget = nil
                birthMemo   = nil
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: - Sheets

    private var addMemoSheet: some View {
        AddMemoView { title, body, emotionHue in
            pendingTitle      = title
            pendingBody       = body
            pendingEmotionHue = emotionHue
            let existingPos   = memoVM.memos.map { $0.starPosition }
            let pos           = GalaxyStarPlacer.generatePosition(existing: existingPos)
            pendingPosition   = pos
            let sw = screenSize.width  > 0 ? screenSize.width  : 393
            let sh = screenSize.height > 0 ? screenSize.height : 852
            pendingTarget  = CGPoint(x: pos.x * sw, y: (1.0 - pos.y) * sh)
            showingAddMemo = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                birthTarget = pendingTarget
            }
        } onCancel: {
            showingAddMemo = false
        }
    }

    // MARK: - Helpers

    private func scheduleShootingStar() {
        let interval = Double.random(in: 20...60)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            if !showShootingStar, !showPromptCard,
               selectedMemo == nil, !memoVM.memos.isEmpty,
               MilestoneManager.shared.isUnlocked(.shootingStar) {
                showShootingStar = true
            }
            scheduleShootingStar()
        }
    }

    private func scheduleComet() {
        let interval = Double.random(in: 90...240)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            if !showComet, !showShootingStar, cometMemo == nil,
               selectedMemo == nil, memoVM.memos.count >= 3,
               MilestoneManager.shared.isUnlocked(.comet) {
                showComet = true
            }
            scheduleComet()
        }
    }

    private func showPopup(_ label: String) {
        popupLabel = label
        withAnimation(.easeIn(duration: 0.15)) { popupOpacity = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.6)) { popupOpacity = 0.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            popupLabel = ""
        }
    }
}
