//
//  URLSession+Extension.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 30.05.2025.
//

import Foundation

// MARK: - Response Logging
extension URLSession {
    static func logResponse(_ data: Data?, response: URLResponse?, error: Error?) {
        print("\n📥 RESPONSE LOG 📥")

        if let error = error {
            print("Error: \(error.localizedDescription)")
        }

        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }

        if let data = data,
            let jsonString = String(data: data, encoding: .utf8) {
            print("Response Data: \(jsonString)")
        }
        print("------------------------\n")
    }
}
