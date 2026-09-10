import Foundation

/// Explicit sample collections until authenticated/local collection repositories are connected.
@MainActor
final class FixtureCollectionRepository: CollectionRepository {
    private let loader: BundledJSONLoader
    private var snapshot: CollectionSnapshot?
    init(loader: BundledJSONLoader = BundledJSONLoader()) { self.loader = loader }
    func load() throws -> CollectionSnapshot {
        if let snapshot { return snapshot }
        let value = try loader.load("collections", as: CollectionSnapshot.self)
        snapshot = value
        return value
    }
    func save(_ snapshot: CollectionSnapshot) { self.snapshot = snapshot }
}
