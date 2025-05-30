import Foundation
import Alamofire

final class NetworkLogger {
    static func logRequest(_ request: URLRequest) {
        print("\n🚀 REQUEST LOG 🚀")
        print("URL: \(request.url?.absoluteString ?? "")")
        print("Method: \(request.httpMethod ?? "")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        if let body = request.httpBody,
           let jsonString = formatJSON(from: body) {
            print("Body: \(jsonString)")
        }
        print("------------------------\n")
    }
    
    static func logResponse(_ response: AFDataResponse<Data>) {
        print("\n📥 RESPONSE LOG 📥")
        print("URL: \(response.request?.url?.absoluteString ?? "")")
        print("Status Code: \(response.response?.statusCode ?? 0)")
        
        if let headers = response.response?.allHeaderFields as? [String: Any] {
            print("Headers: \(headers)")
        }
        
        if let data = response.data,
           let jsonString = formatJSON(from: data) {
            print("Response Data:\n\(jsonString)")
        }
        
        if let error = response.error {
            print("Error: \(error.localizedDescription)")
        }
        print("------------------------\n")
    }
    
    // MARK: - Helper Methods
    private static func formatJSON(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return String(data: data, encoding: .utf8)
        }
        return prettyString
    }
} 