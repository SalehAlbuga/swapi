//
//  APIDefinition.swift
//
//
//  A protocol that API definitions should conform to in order to be consumed by APIRequester
//
//  Created by Saleh on 4/1/18.
//  Copyright © 2018 Saleh Albuga. All rights reserved.
//

import Foundation

protocol APIDefinitionProtocol {
    var method : HttpMethod { get }
    var baseURL : String { get }
    var path: String { get }
    var url : String { get }
    var paramsType: ParamsType { get }
    var queryString: [String : String]? { get }
    var apiKeyRequired: Bool { get }
    var apiKey: String? { get }
    var apiKeyName: String? { get }
    var apiKeyLocation: valueLocation? { get }
    var parameters: [String: String]? { get }
    var headers: [String: String]? { get }
    var sharedHeaders: [String: String]? { get }
}

enum ParamsType {
    case URLParams
    case JSONBody
}

enum HttpMethod : String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
}

enum valueLocation {
    case Header
    case QueryString
}
