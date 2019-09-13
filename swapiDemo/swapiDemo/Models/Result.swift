//
//  Result.swift
//  swapiDemo
//
//  Created by Saleh on 9/13/19.
//  Copyright © 2019 Saleh. All rights reserved.
//

import Foundation

struct ResultResponse: Decodable {
    
    var count: Int
    var results: [Result]
    
    private enum codingKeys: String, CodingKey {
        case count = "resultCount"
        case results = "results"
    }
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: codingKeys.self)
        
        count = try container.decode(Int.self, forKey: .count)
        results = try container.decode([Result].self, forKey: .results)
    }
}



struct Result: Decodable {
    
    var artistId: Int
    var trackId: Int
    var kind: String
    var artist: String
    var collection: String
    var trackName: String
    
    
    private enum codingKeys: String, CodingKey {
        case artistId = "artistId"
        case trackId = "trackId"
        case kind = "kind"
        case artist = "artistName"
        case collection = "collectionName"
        case trackName = "trackName"
    }
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: codingKeys.self)
        
        artistId = try container.decode(Int.self, forKey: .artistId)
        trackId = try container.decode(Int.self, forKey: .trackId)
        trackName = try container.decode(String.self, forKey: .trackName)
        artist = try container.decode(String.self, forKey: .artist)
        collection = try container.decode(String.self, forKey: .collection)
        kind = try container.decode(String.self, forKey: .kind)
        
    }
    
}
