
//  APIRequester.swift
//
//
//  Implementation of APIRequester.
//
//  Created by Saleh on 4/3/18.
//  Copyright © 2018 Saleh Albuga. All rights reserved.


import Foundation

struct APIRequester {
    
    // request a U endpoint defined as APIDefinition & deserialize the response as a T Decodable model & return the result
    static func request<U, T>(endpoint: U, deserialize: T.Type, completionHandler: @escaping (APIResult<T>) -> ()) where U : APIDefinitionProtocol, T : Decodable {
        sendRequest(endpoint: endpoint) { (data, res, error) in
            if error == nil {
                if let resData = data {
                    deserializeData(deserialize, data: resData, FromEndpoint: endpoint, completionHandler: { (dataError, deserializedData) in
                        if dataError == nil {
                            return completionHandler(APIResult.success(deserializedData))
                        } else {
                            return completionHandler(APIResult.failure(dataError!))
                        }
                    })
                } else {
                    
                }
            } else {
                 return completionHandler(APIResult.failure(error!))
            }
        }
    }
    
    // request a U endpoint defined as APIDefinition & return the raw result
    static func requestRaw<U>(endpoint: U, completionHandler: @escaping (_ data: Data?, _ response: URLResponse?, _ error: APIError?) ->()) where U : APIDefinitionProtocol {
        sendRequest(endpoint: endpoint) { (data, res, error) in
            return completionHandler(data, res, error)
        }
    }
    
    
    // Deserialize data returned by API
    private static func deserializeData<U, T>(_ deserialize: T.Type, data: Data?, FromEndpoint endpoint: U, completionHandler: @escaping (_ error: APIError?, _ data: T?) -> ()) where T: Decodable, U: APIDefinitionProtocol {
            if let resData = data {
                do {

                    let obj = try JSONDecoder().decode(T.self, from: resData)
                    return completionHandler(nil, obj)
                } catch {
                    return completionHandler(APIError(innerError: .jsonDecodingError(error: error), response: nil), nil)
                }
            } else {
                return completionHandler(nil, nil)
            }
    }

    // Get the url as string out of an APIDefinition endpoint
    private static func stringUrl<T>(ForEndpoint endpoint: T) -> String? where T: APIDefinitionProtocol {
        return self.url(ForEndpoint: endpoint)?.absoluteString
    }
    
    // Get the URL out of an APIDefinition endpoint
    private static func url<T>(ForEndpoint endpoint: T) -> URL? where T: APIDefinitionProtocol {
        guard var comps : URLComponents = URLComponents(string: endpoint.url) else {
            return nil
        }
        
        
        if endpoint.paramsType == .URLParams && endpoint.parameters != nil {
            var queryItems : [URLQueryItem] = []
            for queryParam in endpoint.parameters! {
                queryItems.append(URLQueryItem(name: "\(queryParam.key)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!, value: (queryParam.value as AnyObject).stringValue))
            }
            if endpoint.apiKeyRequired && endpoint.apiKey != nil && endpoint.apiKeyName != nil && endpoint.apiKeyLocation == .QueryString {
                queryItems.append(URLQueryItem(name: endpoint.apiKeyName!, value: endpoint.apiKey))
            }
            comps.queryItems = queryItems
        }
        
        if endpoint.queryString != nil {
            var queryItems : [URLQueryItem] = []
            for queryParam in endpoint.queryString! {
                queryItems.append(URLQueryItem(name: "\(queryParam.key)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!, value: queryParam.value))
            }
            if let _ = comps.queryItems {
                comps.queryItems?.append(contentsOf: queryItems)
            } else {
                comps.queryItems = queryItems
            }
        }
        
        return comps.url
    }
    
    // Build an URLRequest out of an APIDefinition endpoint
    
    static func buildRequest<T>(endpoint: T) -> URLRequest? where T: APIDefinitionProtocol {
        guard let url = self.url(ForEndpoint: endpoint) else {
            return nil
        }
        var req : URLRequest = URLRequest(url: url)
        req.httpMethod = endpoint.method.rawValue
        
        if endpoint.headers != nil {
            for header in endpoint.headers! {
                req.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        if endpoint.sharedHeaders != nil {
            for header in endpoint.sharedHeaders! {
                req.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        if endpoint.apiKeyRequired && endpoint.apiKey != nil && endpoint.apiKeyName != nil && endpoint.apiKeyLocation == .Header {
            req.addValue(endpoint.apiKey!, forHTTPHeaderField: endpoint.apiKeyName!)
        }
        
        if let params = endpoint.parameters, req.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded" {
            let parameterArray = params.map { (arg) -> String in
                let (key, value) = arg
                return "\(key)=\(self.percentEscapeString(value))"
            }
             req.httpBody = parameterArray.joined(separator: "&").data(using: String.Encoding.utf8)
        } else {
            if endpoint.paramsType == .JSONBody, let params = endpoint.parameters {
                req.httpBody = try? Data(JSONSerialization.data(withJSONObject: params, options: .prettyPrinted))
            }
        }
        
        return req
        
    }
    
    // Send the request defined by an APIDefinition endpoint
    private static func sendRequest<T>(endpoint: T, completionHandler: @escaping (_ data: Data?, _ response: URLResponse?, _ error: APIError?) ->()) where T: APIDefinitionProtocol {
        guard let request = buildRequest(endpoint: endpoint) else {
            return completionHandler(nil, nil, APIError(innerError: .invalidEndpointAPIDefinition, response: nil))
        }
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error == nil {
                let httpRes = response as! HTTPURLResponse
                if httpRes.statusCode >= 500 {
                    completionHandler(nil, response, APIError(innerError: .responseUnsuccessful, response: (response ?? nil)!))
                } else if httpRes.statusCode >= 400 && httpRes.statusCode < 500 {
                    if httpRes.statusCode == 400 {
                    completionHandler(data, response, APIError(innerError: .badRequest, response: (response ?? nil)!))
                    } else if httpRes.statusCode == 401 {
                    completionHandler(data, response, APIError(innerError: .unauthorized, response: (response ?? nil)!))
                    } else if httpRes.statusCode == 403 {
                    completionHandler(data, response, APIError(innerError: .forbidden, response: (response ?? nil)!))
                    } else if httpRes.statusCode == 404 {
                        completionHandler(data, response, APIError(innerError: .notFound, response: (response ?? nil)!))
                    } else if httpRes.statusCode == 422 {
                        completionHandler(data, response, APIError(innerError: .unprocessableEntity, response: (response ?? nil)!))
                    } else  {
                        completionHandler(data, response, APIError(innerError: .responseUnsuccessful, response: (response ?? nil)!))
                    }
                } else if httpRes.statusCode >= 200 && httpRes.statusCode < 400 {
                    completionHandler(data, response, nil)
                }
            } else {

                if error?._code == -1009 {
                    completionHandler(nil, nil, APIError(innerError: .noInternetConnection,response: nil))
                }
                else{
                    completionHandler(nil, nil, APIError(innerError: .other(error: (error ?? nil)!), response: nil))

                }
             }
        }
        task.resume()
    }

    private static func percentEscapeString(_ string: String) -> String {
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-._* ")
        
        return string
            .addingPercentEncoding(withAllowedCharacters: characterSet)!
            .replacingOccurrences(of: " ", with: "+")
            .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
    }
    
}




