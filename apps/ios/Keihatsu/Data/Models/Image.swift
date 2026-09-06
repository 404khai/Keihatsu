//
//  Image.swift
//  Keihatsu
//
//  Created by admin on 6/3/26.
//


import SwiftUI
import CryptoKit

nonisolated struct ImageModel: Identifiable, Hashable, Codable, Sendable {
    var id: UUID = .init()
    var image: String
    var title: String
    var category: String
    var metadataLine: String
    var summary: String
    var manga: Manga? = nil
}

var images: [ImageModel] = [
    ImageModel(
        image: "Image1",
        title: "The Regressed Mercenary's Machinations",
        category: "Manhwa",
        metadataLine: "Action • School • Thriller",
        summary: "A former child soldier returns to civilian life and tries to protect the only family he has left."
    ),
    ImageModel(
        image: "Image2",
        title: "Latna Saga",
        category: "Fantasy",
        metadataLine: "Adventure • Action • Isekai",
        summary: "A reluctant hero is pulled into a harsh world where survival, leveling, and fate are tightly linked."
    ),
    ImageModel(
        image: "Image3",
        title: "The World After the Fall",
        category: "Sci-Fi",
        metadataLine: "Fantasy • Survival • Mystery",
        summary: "After the tower collapses, one man chooses to keep climbing and uncover what the world really is."
    ),
    ImageModel(
        image: "Image4",
        title: "Player",
        category: "Action",
        metadataLine: "Fantasy • Game • Adventure",
        summary: "A normal student is thrown into a game-like world and forced to grow stronger with every battle."
    ),
    ImageModel(
        image: "Image5",
        title: "Ordeal",
        category: "Superhero",
        metadataLine: "Action • Drama • Fantasy",
        summary: "Gifted fighters and powerful bloodlines collide in a world where strength comes with a heavy cost."
    ),
    ImageModel(
        image: "Image6",
        title: "Superhuman Battlefield",
        category: "Thriller",
        metadataLine: "Action • Dark Fantasy • Survival",
        summary: "Each choice has consequences as the protagonist faces escalating dangers in a brutal world."
    ),
    ImageModel(
        image: "Image7",
        title: "Return of the SSS Class Ranker",
        category: "Action",
        metadataLine: "Action • Mythology • Survival",
        summary: "Each choice has consequences as the protagonist faces escalating dangers in a brutal world."
    ),
    ImageModel(
        image: "Image8",
        title: "Legend of the Northern Blade",
        category: "Thriller",
        metadataLine: "Action • Murim • Survival",
        summary: "Jin Muwon must take revenge for his father's murder while rebuilding the lost Northern Blade Sect."
    ),

    
    ImageModel(
        image: "Image9",
        title: "Pick Me Up Infinite Gacha",
        category: "Superhero",
        metadataLine: "Action • Drama • Fantasy",
        summary: "Gifted fighters and powerful bloodlines collide in a world where strength comes with a heavy cost."
    ),
    ImageModel(
        image: "Image10",
        title: "Regressed Bastard of the Sword Clan",
        category: "Action",
        metadataLine: "Action • Mythology • Survival",
        summary: "Theo Ragnar has regressed back in time, to correct those wrongs and take revenge, he must get stronger."
    ),
    ImageModel(
        image: "Image11",
        title: "Graymark",
        category: "Thriller",
        metadataLine: "Action • Murim • Survival",
        summary: "Jin Muwon must take revenge for his father's murder while rebuilding the lost Northern Blade Sect."
    ),
    ImageModel(
        image: "Image12",
        title: "My Bias on the Last Train",
        category: "Romance",
        metadataLine: "Action • Mythology • Survival",
        summary: "Theo Ragnar has regressed back in time, to correct those wrongs and take revenge, he must get stronger."
    ),
    ImageModel(
        image: "Image13",
        title: "The Regressed Son of a Duke is an Assassin",
        category: "Thriller",
        metadataLine: "Action • Murim • Survival",
        summary: "Jin Muwon must take revenge for his father's murder while rebuilding the lost Northern Blade Sect."
    ),

]

// A narrow adapter keeps the existing card/detail composition while Phase 3 migrates details.
extension ImageModel {
    nonisolated init(manga: Manga) {
        let key = (try? JSONEncoder().encode([manga.id.sourceID, manga.id.mangaID])) ?? Data()
        let bytes = Array(SHA256.hash(data: key).prefix(16))
        id = UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
        image = ""
        title = manga.title
        category = manga.language ?? ""
        metadataLine = manga.genres.isEmpty ? manga.id.sourceID : manga.genres.joined(separator: " • ")
        summary = manga.description ?? "No description available."
        self.manga = manga
    }
}
