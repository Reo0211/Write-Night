import Foundation
import UserNotifications
import Combine

final class PlanetViewModel: ObservableObject {
    @Published private(set) var planets:      [Planet] = []
    @Published              var planetVisible: Bool     = MilestoneManager.shared.isUnlocked(.reminderMoon)

    private let store = PlanetStore.shared

    var isUnlocked: Bool { MilestoneManager.shared.isUnlocked(.reminderMoon) }

    init() {
        planets = store.load()
        requestNotificationPermission()
    }

    // MARK: - Milestone

    /// MilestoneManager 経由で解放されたあと呼ぶ（表示フラグを立てる）
    func syncUnlockState() {
        if isUnlocked { planetVisible = true }
    }

    /// 現在アクティブなリマインダー（未完了・期限が最も近いもの）
    var activeReminder: Planet? {
        planets.filter { !$0.isCompleted }.min(by: { $0.deadline < $1.deadline })
    }

    /// 全アクティブリマインダー（期限近い順）
    var activeReminders: [Planet] {
        planets.filter { !$0.isCompleted }.sorted { $0.deadline < $1.deadline }
    }

    // MARK: - CRUD

    func addPlanet(title: String, body: String, deadline: Date) {
        let planet = Planet(title: title, body: body, deadline: deadline)
        planets.append(planet)
        store.save(planets)
        scheduleNotification(for: planet)
    }

    // MARK: - 期限監視（毎分チェック）

    private var deadlineTimer: AnyCancellable?

    func startDeadlineMonitoring() {
        deadlineTimer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.checkDeadlines() }
        checkDeadlines()  // 即時チェック
    }

    private func checkDeadlines() {
        let now = Date()
        for planet in planets where !planet.isCompleted {
            if planet.deadline <= now {
                NotificationCenter.default.post(name: .moonExpired, object: planet)
                NotificationCenter.default.post(name: .moonShake, object: nil)
                // 期限切れを completed に
                complete(planet)
                break  // 一度に1件ずつ処理
            }
        }
    }

    func complete(_ planet: Planet) {
        guard let idx = planets.firstIndex(where: { $0.id == planet.id }) else { return }
        planets[idx].isCompleted = true
        store.save(planets)
        cancelNotification(for: planet)
        // 完了後少し待って削除（エフェクト演出のため）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.planets.removeAll { $0.id == planet.id }
            self.store.save(self.planets)
        }
    }

    func delete(_ planet: Planet) {
        planets.removeAll { $0.id == planet.id }
        store.save(planets)
        cancelNotification(for: planet)
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func scheduleNotification(for planet: Planet) {
        let content         = UNMutableNotificationContent()
        content.title       = "⭘ \(planet.title)"
        content.body        = planet.body.isEmpty ? "期限が来ました!" : planet.body
        content.sound       = .default

        let comps    = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: planet.deadline)
        let trigger  = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request  = UNNotificationRequest(identifier: planet.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification(for planet: Planet) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [planet.id.uuidString])
    }
}
