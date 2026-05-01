public protocol ConfigStore {
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func delete(forKey key: String) throws
}
