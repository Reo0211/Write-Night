import StoreKit
import Combine

// MARK: - Tip商品ID（App Store Connectで作成するConsumable IAPのID）
// 例: "art.nightthought.tip.small" など、実際のIDに合わせてください

enum TipProduct: String, CaseIterable {
    case small  = "art.nightthought.tip.small"   // 小さな星ひとつ
    case medium = "art.nightthought.tip.medium"  // 流れ星ひとつ
    case large  = "art.nightthought.tip.large"   // 惑星ひとつ

    var label: String {
        switch self {
        case .small:  return "小さな星"
        case .medium: return "中くらいの星"
        case .large:  return "大きな星"
        }
    }

    var icon: String {
        switch self {
        case .small:  return "star"
        case .medium: return "sparkle"
        case .large:  return "globe"
        }
    }
}

// MARK: - TipStore

@MainActor
final class TipStore: ObservableObject {
    static let shared = TipStore()

    @Published var products:   [Product] = []
    @Published var isPurchasing: Bool    = false
    @Published var thankYouVisible: Bool = false

    private init() {
        Task { await loadProducts() }
    }

    func loadProducts() async {
        do {
            let ids = TipProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            print("TipStore: product load failed: \(error)")
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let tx):
                    await tx.finish()
                    thankYouVisible = true
                    // 3秒後に自動消去
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    thankYouVisible = false
                case .unverified:
                    break
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("TipStore: purchase failed: \(error)")
        }
    }
}
