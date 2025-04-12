//
//  JSONUtil.swift
//  Observable
//
//  Created by whoog on 2024/9/11.
//

import Foundation

struct JSON {
    
    public static func toJSONString<T: Encodable>(_ obj: T) -> String? {
        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted  // Optional: for pretty printing the JSON
        encoder.dateEncodingStrategy = .iso8601   // Optional: for handling dates

        do {
            let jsonData = try encoder.encode(obj)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error encoding object to JSONString: \(error)")
            return nil
        }
    }

    public static func parseObject<T: Decodable>(_ json: String, to clazz: T.Type) -> T? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601   // Optional: for handling dates

        guard let jsonData = json.data(using: .utf8) else {
            print("Error converting JSON string to Data")
            return nil
        }

        do {
            return try decoder.decode(clazz, from: jsonData)
        } catch {
            print("Error decoding JSON string to object: \(error)")
            return nil
        }
    }
}
