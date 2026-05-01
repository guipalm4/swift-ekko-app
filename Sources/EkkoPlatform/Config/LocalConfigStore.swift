import Foundation
import EkkoCore

// MARK: - ConfigError

public enum ConfigError: Error {
    case encodingFailed
    case decodingFailed
    case storageUnavailable
}

// MARK: - LocalConfigStore

/// A `ConfigStore` backed by JSON files in a local directory.
/// Each key maps to `<baseURL>/<key>.json`.
public struct LocalConfigStore: ConfigStore {
    private let baseURL: URL

    /// Designated init — injects the base directory. Use a temp dir in tests.
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    /// Convenience init for production — uses `~/Library/Application Support/Ekko/`.
    public init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        self.baseURL = appSupport.appendingPathComponent("Ekko", isDirectory: true)
    }

    // MARK: ConfigStore

    public func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        do {
            let data = try Data(contentsOf: url(forKey: key))
            return try JSONDecoder().decode(type, from: data)
        } catch let error as NSError
            where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
            return nil
        } catch is DecodingError {
            throw ConfigError.decodingFailed
        } catch {
            throw ConfigError.storageUnavailable
        }
    }

    public func save<T: Codable>(_ value: T, forKey key: String) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(value)
        } catch {
            throw ConfigError.encodingFailed
        }
        do {
            try FileManager.default.createDirectory(
                at: baseURL,
                withIntermediateDirectories: true
            )
            try data.write(to: url(forKey: key), options: .atomic)
        } catch {
            throw ConfigError.storageUnavailable
        }
    }

    public func delete(forKey key: String) throws {
        do {
            try FileManager.default.removeItem(at: url(forKey: key))
        } catch let error as NSError
            where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
            return
        } catch {
            throw ConfigError.storageUnavailable
        }
    }

    // MARK: Private

    private func url(forKey key: String) -> URL {
        baseURL.appendingPathComponent("\(key).json")
    }
}
