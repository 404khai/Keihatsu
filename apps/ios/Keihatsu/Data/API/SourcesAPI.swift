import Foundation

nonisolated enum SourcesAPI {
    static var sources: APIRequest<[SourceDTO]> { APIRequest(path: ["sources"]) }

    static func listing(sourceID: String, type: CatalogueListing, page: Int, query: String?) -> APIRequest<MangaPageDTO> {
        var items = [URLQueryItem(name: "type", value: type.rawValue), URLQueryItem(name: "page", value: String(page))]
        if type == .search { items.append(URLQueryItem(name: "q", value: query ?? "")) }
        return APIRequest(path: ["sources", sourceID, "manga"], query: items)
    }
}
