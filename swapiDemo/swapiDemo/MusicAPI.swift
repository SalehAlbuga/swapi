//
//  API.swift
//  swapiDemo
//
//  Created by Saleh on 7/7/19.
//  Copyright © 2019 Saleh. All rights reserved.
//

import Foundation
import swapi

enum MusicAPI {
    case search(term: String, limit: Int)
}

extension MusicAPI: APIDefinitionProtocol {
    var method: HttpMethod {
        switch self {
        case .search(_,_):
            return .GET
        }
    }
    
    var baseURL: String {
        return "https://itunes.apple.com/"
    }
    
    var path: String {
        switch self {
        case .search(_,_):
            return "search"
        }
    }
    
    var url: String {
        return "\(self.baseURL)\(self.path)"
    }
    
    var paramsType: ParamsType {
        switch self {
        case .search(_,_):
            return .URLParams
        }
    }
    
    var queryString: [String : String]? {
        switch self {
        case let .search(term, limit):
            return ["term": term, "limit": "\(limit)"]
        }
    }
    
    var apiKeyRequired: Bool {
        return false
    }
    
    var apiKey: String? {
        return nil
    }
    
    var apiKeyName: String? {
        return ""
    }
    
    var apiKeyLocation: valueLocation? {
        return .none
    }
    
    var parameters: [String : String]? {
       return nil
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var sharedHeaders: [String : String]? {
        return nil
    }
    
    
}
