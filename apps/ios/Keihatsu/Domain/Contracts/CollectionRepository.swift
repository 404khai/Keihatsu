import Foundation

@MainActor
protocol CollectionRepository {
    func load() throws -> CollectionSnapshot
    func save(_ snapshot: CollectionSnapshot) throws
}
