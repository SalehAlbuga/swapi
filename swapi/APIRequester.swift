
//  APIRequester.swift
//
//
//  Implementation of APIRequester.
//
//  Created by Saleh on 4/3/18.
//  Copyright © 2018 Saleh Albuga. All rights reserved.


import Foundation

public class APIRequester {
    
    public static var shared = APIRequester()
    
    public var debugLogging: Bool = false
    
    private init() { }
    
    // request a U endpoint defined as APIDefinition & deserialize the response as a T Decodable model & return the result
    public func request<U, T>(endpoint: U, deserialize: T.Type, session: URLSession = URLSession.shared, completionHandler: @escaping (APIResult<T>) -> ()) where U : APIDefinitionProtocol, T : Decodable {
        sendRequest(endpoint: endpoint, session: session) { (data, res, error) in
            if error == nil {
                self.deserializeData(deserialize, data: data, FromEndpoint: endpoint, completionHandler: { (dataError, deserializedData) in
                        if dataError == nil {
                            return completionHandler(APIResult.success(deserializedData))
                        } else {
                            return completionHandler(APIResult.failure(dataError!))
                        }
                    })
            } else {
                 return completionHandler(APIResult.failure(error!))
            }
        }
    }
    
    // request a U endpoint defined as APIDefinition & return the raw result
    public func requestRaw<U>(endpoint: U, session: URLSession = URLSession.shared, completionHandler: @escaping (_ data: Data?, _ response: URLResponse?, _ error: APIError?) ->()) where U : APIDefinitionProtocol {
        sendRequest(endpoint: endpoint, session: session) { (data, res, error) in
            return completionHandler(data, res, error)
        }
    }
    
    
    // Deserialize data returned by API
    private func deserializeData<U, T>(_ deserialize: T.Type, data: Data?, FromEndpoint endpoint: U, completionHandler: @escaping (_ error: APIError?, _ data: T?) -> ()) where T: Decodable, U: APIDefinitionProtocol {
            if let resData = data {
                do {
                    let obj = try JSONDecoder().decode(T.self, from: resData)
                    return completionHandler(nil, obj)
                } catch {
                    self.log("Error while deserializing response for: \(endpoint.path) - \(error)")
                    return completionHandler(APIError(innerError: .jsonDecodingError(error: error), response: nil), nil)
                }
            } else {
                return completionHandler(nil, nil)
            }
    }

    // Get the url as string out of an APIDefinition endpoint
    public func stringUrl<T>(ForEndpoint endpoint: T) -> String? where T: APIDefinitionProtocol {
        return self.url(ForEndpoint: endpoint)?.absoluteString
    }
    
    // Get the URL out of an APIDefinition endpoint
    private func url<T>(ForEndpoint endpoint: T) -> URL? where T: APIDefinitionProtocol {
        guard var comps : URLComponents = URLComponents(string: endpoint.url) else {
            return nil
        }
        
        
        if endpoint.paramsType == .QueryString, let params = endpoint.parameters {
            var queryItems : [URLQueryItem] = []
            for param in params {
                queryItems.append(URLQueryItem(name: "\(param.key)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!, value: "\(param.value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!))
            }
            if endpoint.apiKeyRequired && endpoint.apiKey != nil && endpoint.apiKeyName != nil && endpoint.apiKeyLocation == .QueryString {
                queryItems.append(URLQueryItem(name: endpoint.apiKeyName!, value: endpoint.apiKey))
            }
            comps.queryItems = queryItems
        }
        
        if let qsParams = endpoint.additionalQueryString {
            var queryItems : [URLQueryItem] = []
            for param in qsParams {
                queryItems.append(URLQueryItem(name: "\(param.key)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!, value: "\(param.value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!))
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
    
    public func buildRequest<T>(endpoint: T) -> URLRequest? where T: APIDefinitionProtocol {
        guard let url = self.url(ForEndpoint: endpoint) else {
            return nil
        }
        
        
        log("API url: \(url.absoluteString)")
        
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
                if req.value(forHTTPHeaderField: "Content-Type") == nil {
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                req.httpBody = try? Data(JSONSerialization.data(withJSONObject: params, options: .prettyPrinted))
            }
        }
        
        return req
        
    }
    
    // Send the request defined by an APIDefinition endpoint
    private func sendRequest<T>(endpoint: T, session: URLSession = URLSession.shared, completionHandler: @escaping (_ data: Data?, _ response: URLResponse?, _ error: APIError?) ->()) where T: APIDefinitionProtocol {
        guard let request = buildRequest(endpoint: endpoint) else {
            self.log("Invalid Endpoint Definition: \(endpoint.path)")
            return completionHandler(nil, nil, APIError(innerError: .invalidEndpointAPIDefinition, response: nil))
        }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if error == nil {
                let httpRes = response as! HTTPURLResponse
                
                self.log("HTTP Response for \(request.url!.absoluteString) : \(httpRes.statusCode)")
                
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
                    
                    self.log("Error while calling: \(request.url!.absoluteString) : \(error.debugDescription)")
                    completionHandler(nil, nil, APIError(innerError: .other(error: (error ?? nil)!), response: nil))
                    
                }
             }
        }
        task.resume()
    }

    
}

extension APIRequester {
    
    private func log(_ message: String) {
        if self.debugLogging {
            print("SWAPI \(message)")
        }
    }
    
    private func percentEscapeString(_ string: String) -> String {
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-._* ")
        
        return string
            .addingPercentEncoding(withAllowedCharacters: characterSet)!
            .replacingOccurrences(of: " ", with: "+")
            .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
    }
    
}




