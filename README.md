# Swapi

### A simple network abstraction library that uses only URLSession. Supports Swift 4.0 JSON deserialization with Decodable protocol

## Installation
### Currently you can get Swapi with CocoaPods, add the following to your Podfile
```podfile
pod 'swapi', '~> 0.9'
```

## Usage
## Defining APIs
### Defining APIs is easy and fun with Swapi and feels natural with Swift. Create an enum that conforms to **APIDefinitionProtocol** and implement the properties as need for your API. Here an example below:
```swift

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

```
## Calling APIs
### Call ```request(_,_,_)``` method of **APIRequester**  with the defined API as below. The library will return a result object with the deserialized response or the error.

```swift
 APIRequester.request(endpoint: MusicAPI.search(term: term, limit: 25), deserialize: ResultResponse.self) { (result) in
            DispatchQueue.main.async {
            switch result {
            case let .success(response):
                if let searchResults = response {
                    self.results = searchResults.results
                    self.tableView.reloadData()
                }
                break
            case let .failure(error):
                switch error.innerError {
                case .connectionError:
                      ...
                    break
                case .badRequest:
                    ...
                    break
                default:
                    break;
                }
                break         
            }
        }
        }
```
### If you want to use the class URLSession callback, you can call ```RequestRaw(_,_)```

```swift
  APIRequester.requestRaw(endpoint: MusicAPI.search(term: "OneRepublic", limit: 25)) { (data, response, error) in
         ...   
        }
```

## Defining Models
### You can define models using Swift 4 Decodable and pass it to Swapi to deserialize as shown in ```request(_,_,_)``` example

```swift
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
```
## Future work
1. Better documentation
2. More features :]

