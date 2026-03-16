import SwiftUI
import StoreKit

struct TipView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = TipStore.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Text("開発者を応援する")
                        .font(.custom("HiraMinProN-W6", size: 18))
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
                        // メッセージ
                        VStack(spacing: 10) {
                            Text("より良い体験のために。")
                                .font(.custom("HiraMinProN-W3", size: 13))
                                .foregroundColor(.white.opacity(0.35))
                                .tracking(2)

                            Text("このアプリは完全に広告なしで無料で使えます。\n以下のボタンを押すと、開発者にチップを\n送ることができます。\nいつもアプリをご愛用していただき、\n本当にありがとうございます！")
                                .font(.custom("HiraMinProN-W3", size: 13))
                                .foregroundColor(.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                                .lineSpacing(5)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 4)

                        // 商品リスト
                        if store.products.isEmpty {
                            // ローディング or 未取得
                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white.opacity(0.4))
                                Text("読み込み中...")
                                    .font(.custom("HiraMinProN-W3", size: 12))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(.vertical, 30)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(store.products, id: \.id) { product in
                                    TipRow(product: product, isPurchasing: store.isPurchasing) {
                                        Task { await store.purchase(product) }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // 注記
                        Text("チップは返金・返還できません。*この購入は開発者を応援するためのものであり、新アイテム・機能の追加はありません。")
                            .font(.custom("HiraMinProN-W3", size: 10))
                            .foregroundColor(.white.opacity(0.22))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                            .padding(.bottom, 40)
                    }
                }
            }

            // ありがとうオーバーレイ
            if store.thankYouVisible {
                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(red: 0.75, green: 0.88, blue: 1.0))
                        .shadow(color: Color(red: 0.6, green: 0.82, blue: 1.0).opacity(0.8), radius: 8)
                    Text("ありがとうございます。感極まる思いです。")
                        .font(.custom("HiraMinProN-W6", size: 17))
                        .foregroundColor(.white.opacity(0.9))
                    Text("あなたのおかげで新機能開発・体験の改善に尽力できます。\nぜひ、次回のアップデートをお待ちください！")
                        .font(.custom("HiraMinProN-W3", size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .environment(\.colorScheme, .dark)
        .task { await store.loadProducts() }
    }
}

// MARK: - TipRow

private struct TipRow: View {
    let product:      Product
    let isPurchasing: Bool
    let onTap:        () -> Void

    // productIDからTipProductを逆引き
    private var tipProduct: TipProduct? {
        TipProduct(rawValue: product.id)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: tipProduct?.icon ?? "star")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Color(red: 0.65, green: 0.85, blue: 1.0).opacity(0.8))
                    .frame(width: 24)

                Text(tipProduct?.label ?? product.displayName)
                    .font(.custom("HiraMinProN-W3", size: 14))
                    .foregroundColor(.white.opacity(0.80))

                Spacer()

                Text(product.displayPrice)
                    .font(.custom("HiraMinProN-W3", size: 14))
                    .foregroundColor(.white.opacity(0.50))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isPurchasing ? 0.5 : 1.0)
        }
        .disabled(isPurchasing)
    }
}
