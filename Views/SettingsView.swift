import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var memoVM: MemoViewModel
    
    @AppStorage("bgmVolume")    private var bgmVolume:    Double = 0.6
    @AppStorage("sfxVolume")    private var sfxVolume:    Double = 0.35
    @AppStorage("preferredFPS") private var preferredFPS: Int    = 60
    @AppStorage("bgmEnabled")   private var bgmEnabled:   Bool   = true
    @State private var showTipView: Bool = false
    @State private var showGuide: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("設定")
                        .font(.custom("HiraMinProN-W6", size: 20))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 22))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        SettingsSection(title: "進捗") {
                            MilestoneProgressRow(memoCount: memoVM.memos.count)
                        }
                        
                        SettingsSection(title: "サウンド") {
                            SettingsSliderRow(
                                icon: "speaker.wave.2",
                                label: "BGM",
                                value: $bgmVolume,
                                range: 0...1
                            ) { v in
                                AudioManager.shared.setVolume(Float(v))
                            }
                            SettingsSliderRow(
                                icon: "waveform",
                                label: "効果音",
                                value: $sfxVolume,
                                range: 0...1
                            ) { _ in }
                        }
                        
                        SettingsSection(title: "パフォーマンス") {
                            HStack {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 20)
                                Text("フレームレート")
                                    .font(.custom("HiraMinProN-W3", size: 14))
                                    .foregroundColor(.white.opacity(0.75))
                                Spacer()
                                Picker("", selection: $preferredFPS) {
                                    Text("24").tag(24)
                                    Text("30").tag(30)
                                    Text("60").tag(60)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 120)
                                .colorScheme(.dark)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        SettingsSection(title: "情報") {
                            // 機能ガイド（タップで展開、解放済みのみ表示）
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    showGuide.toggle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(width: 22)
                                    Text("機能ガイド")
                                        .font(.custom("HiraMinProN-W3", size: 14))
                                        .foregroundColor(.white.opacity(0.75))
                                    Spacer()
                                    Image(systemName: showGuide ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11, weight: .light))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(.vertical, 4)
                            }
                            
                            if showGuide {
                                let m = MilestoneManager.shared
                                VStack(alignment: .leading, spacing: 14) {
                                    if m.isUnlocked(.emotionColor) {
                                        GuideRow(icon: "circle.fill", label: "感情の星",
                                                 desc: "記録を書くとき、カラーバーで今の気持ちを色として星に宿せます。")
                                    }
                                    if m.isUnlocked(.shootingStar) {
                                        GuideRow(icon: "sparkle", label: "言葉の流れ星",
                                                 desc: "夜空にときどき流れ星が現れます。すばやくタップして捕まえてください。")
                                    }
                                    if m.isUnlocked(.reminderMoon) {
                                        GuideRow(icon: "moon.fill", label: "想起の月",
                                                 desc: "月をタップするとリマインダーを設定できます。期限が近づくほど月は欠け、期限が来ると新月になります。*複数のリマインダーがある場合、期限が最も最短のものが月の満ち欠けに反映されます。（リマインド機能は全て有効です。）")
                                    }
                                    if [MilestoneKind.mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune].contains(where: { m.isUnlocked($0) }) {
                                        GuideRow(icon: "globe", label: "記憶の惑星",
                                                 desc: "星が増えるごとに惑星が解放されます。タップするとその頃の記憶を振り返れます。")
                                    }
                                    if m.isUnlocked(.comet) {
                                        GuideRow(icon: "camera.filters", label: "懐古の彗星",
                                                 desc: "夜空にときどき彗星が現れます。タップすると過去の記憶がひとつ浮かび上がります。")
                                    }
                                }
                                .padding(.top, 6)
                                .padding(.leading, 30)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            SettingsInfoRow(label: "アプリ名", value: "Write Night")
                            SettingsInfoRow(label: "バージョン", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            SettingsInfoRow(label: "開発・音楽", value: "A.R.t.")
                        }

                        SettingsSection(title: "その他") {
                            SettingsButtonRow(icon: "heart.fill", label: "開発者を応援する") {
                                showTipView = true
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .sheet(isPresented: $showTipView) {
                TipView()
            }
        }
    }
    
    // MARK: - Section
    
    private struct SettingsSection<Content: View>: View {
        let title: String
        @ViewBuilder let content: () -> Content
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("HiraMinProN-W3", size: 11))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.leading, 6)
                    .padding(.bottom, 6)
                
                VStack(spacing: 1) {
                    content()
                }
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
    
    // MARK: - Row types
    
    private struct SettingsToggleRow: View {
        let icon:  String
        let label: String
        @Binding var value: Bool
        var onChange: (() -> Void)? = nil
        
        var body: some View {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 20)
                Text(label)
                    .font(.custom("HiraMinProN-W3", size: 15))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Toggle("", isOn: $value)
                    .labelsHidden()
                    .tint(Color(red: 0.4, green: 0.6, blue: 1.0))
                    .onChange(of: value) { _, _ in onChange?() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
    
    private struct SettingsSliderRow: View {
        let icon:  String
        let label: String
        @Binding var value: Double
        let range: ClosedRange<Double>
        var onChange: ((Double) -> Void)? = nil
        
        var body: some View {
            VStack(spacing: 8) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 20)
                    Text(label)
                        .font(.custom("HiraMinProN-W3", size: 15))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(String(format: "%.0f%%", value * 100))
                        .font(.custom("HiraMinProN-W3", size: 13))
                        .foregroundColor(.white.opacity(0.35))
                }
                Slider(value: $value, in: range)
                    .tint(Color(red: 0.4, green: 0.6, blue: 1.0))
                    .onChange(of: value) { _, v in onChange?(v) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
    
    private struct SettingsButtonRow: View {
        let icon:  String
        let label: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 20)
                    Text(label)
                        .font(.custom("HiraMinProN-W3", size: 15))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.2))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }
    
    private struct SettingsInfoRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .font(.custom("HiraMinProN-W3", size: 15))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(value)
                    .font(.custom("HiraMinProN-W3", size: 14))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
    
    // MARK: - MilestoneProgressRow
    
    private struct MilestoneProgressRow: View {
        let memoCount: Int
        
        private let milestones = MilestoneKind.allCases.sorted { $0.rawValue < $1.rawValue }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("\(memoCount) 個の星")
                        .font(.custom("HiraMinProN-W3", size: 14))
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    if MilestoneManager.shared.stepsToNext(current: memoCount) == nil {
                        Text("すべて達成")
                            .font(.custom("HiraMinProN-W3", size: 12))
                            .foregroundColor(.white.opacity(0.30))
                    }
                }
                
                GeometryReader { geo in
                    let unlocked = MilestoneManager.shared.unlockedCount
                    let total    = MilestoneManager.shared.totalCount
                    let progress = total > 0 ? CGFloat(unlocked) / CGFloat(total) : 0
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.5, green: 0.7, blue: 1.0),
                                        Color(red: 0.8, green: 0.6, blue: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
                
                HStack(spacing: 6) {
                    ForEach(milestones, id: \.rawValue) { kind in
                        let done = MilestoneManager.shared.isUnlocked(kind)
                        Circle()
                            .fill(done
                                  ? Color(red: 0.6, green: 0.8, blue: 1.0)
                                  : Color.white.opacity(0.12))
                            .frame(width: 7, height: 7)
                            .shadow(color: done
                                    ? Color(red: 0.5, green: 0.7, blue: 1.0).opacity(0.8)
                                    : .clear,
                                    radius: 3)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
    
    // MARK: - GuideRow
    
    private struct GuideRow: View {
        let icon:  String
        let label: String
        let desc:  String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                    Text(label)
                        .font(.custom("HiraMinProN-W6", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                Text(desc)
                    .font(.custom("HiraMinProN-W3", size: 12))
                    .foregroundColor(.white.opacity(0.38))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
