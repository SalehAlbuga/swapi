//
//  APIError.swift
//
//
//  Returned inside an APIResult on failure
//
//  Created by Saleh on 4/3/18.
//  Copyright © 2018 Saleh Albuga. All rights reserved.
//

import Foundation

public struct APIError {
    public var innerError: APIErrorType
    public var response: URLResponse?
}

public enum APIErrorType {
    case connectionError
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case responseUnsuccessful
    case jsonDecodingError(error: Error)
    case invalidEndpointAPIDefinition
    case unprocessableEntity
    case methodNotAllowed
    case other(error: Error)
    case noInternetConnection
    
    var debugDescription: String {
        switch self {
        case .connectionError: return "Request Failed"
        case .badRequest: return "Invalid Data"
        case .unauthorized: return "Unauthorized"
        case .forbidden: return "Forbidden"
        case .notFound: return "Not Found"
        case .responseUnsuccessful: return "Response Unsuccessful"
        case .jsonDecodingError(let error): return "JSON Deserialization Failure: \(error)"
        case .invalidEndpointAPIDefinition: return "malformed endpoint definition"
        case .noInternetConnection: return "No internet"
        case .unprocessableEntity: return "Unprocessable Entity"
        case .methodNotAllowed: return "Method Not Allowed"
        case .other(let error): return error.localizedDescription
        }
    }
    
}
