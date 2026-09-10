import Foundation

nonisolated struct BundledJSONLoader: Sendable {
    let bundle: Bundle

    init(bundle: Bundle = .main) { self.bundle = bundle }

    func load<Value: Decodable>(_ name: String, as type: Value.Type = Value.self) throws -> Value {
        let locations: [String?] = [nil, "Resources/MockData", "MockData", "Resources/Content", "Content"]
        guard let url = locations.compactMap({ bundle.url(forResource: name, withExtension: "json", subdirectory: $0) }).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }
}
