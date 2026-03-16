import Foundation

final class PlanetStore {
    static let shared = PlanetStore()

    private let fileURL: URL

    private init() {
        let fm  = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("ThoughtSky", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("planets.json")
    }

    func load() -> [Planet] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Planet].self, from: data)) ?? []
    }

    func save(_ planets: [Planet]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting   = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        try? encoder.encode(planets).write(to: fileURL, options: .atomic)
    }
}
