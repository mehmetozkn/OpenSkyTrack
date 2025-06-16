//
//  AppStorage.swift
//  OpenSkyTrack
//
//  Created by Mehmet Özkan on 13.06.2025.
//

import Foundation

final class AppStorage {
    static let shared = AppStorage()
    private let defaults = UserDefaults.standard
    private init() { }

    func save<T: Codable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    func get<T: Codable>(key: String, as type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return decoded
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
