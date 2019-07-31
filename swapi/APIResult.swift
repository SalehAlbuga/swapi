//
//  APIResponse.swift
//
//
//  APIResult is what an APIRequester returns with it's completionHandlers
//
//  Created by Saleh on 4/3/18.
//  Copyright © 2018 Saleh Albuga. All rights reserved.
//

import Foundation

public enum APIResult <T: Decodable>{
    case success(T?)
    case failure(APIError)
}

