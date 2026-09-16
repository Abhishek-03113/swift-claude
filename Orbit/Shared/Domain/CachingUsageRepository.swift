import Foundation

/// Wraps any `UsageRepository` with an App-Group-backed cache, so a widget
/// refresh that fails (network hiccup, CLI unavailable) still has a last
/// known-good snapshot to show instead of going blank. This is the piece
/// that turns "some data source" into "reliable enough for a glanceable
/// widget" per the Reliability phase of the spec.
public actor CachingUsageRepository: UsageRepository {
    private let wrapped: UsageRepository
    private let cache: UsageSnapshotCache

    public init(wrapping repository: UsageRepository, cache: UsageSnapshotCache = .shared) {
        self.wrapped = repository
        self.cache = cache
    }

    public func snapshot() async throws -> UsageSnapshot {
        do {
            let fresh = try await wrapped.snapshot()
            cache.save(fresh)
            return fresh
        } catch {
            if let cached = cache.load() {
                return cached
            }
            throw error
        }
    }

    /// Loads the current state without necessarily awaiting a network round
    /// trip's failure path twice: returns `.loaded` on success, `.stale`
    /// when falling back to cache, `.failed` when nothing is available.
    public func loadState() async -> UsageLoadState {
        do {
            let fresh = try await wrapped.snapshot()
            cache.save(fresh)
            return .loaded(fresh)
        } catch let error as UsageRepositoryError {
            if let cached = cache.load() {
                return .stale(cached)
            }
            return .failed(error)
        } catch {
            if let cached = cache.load() {
                return .stale(cached)
            }
            return .failed(.unavailable)
        }
    }
}

/// Thin `UserDefaults`(App Group)-backed store for the last known-good
/// snapshot. Kept separate from `CachingUsageRepository` so it can be unit
/// tested without an async repository in the loop.
public final class UsageSnapshotCache: @unchecked Sendable {
    public static let shared = UsageSnapshotCache()

    private let defaults: UserDefaults?
    private let key = "orbit.usage.snapshot.cache"
    private let lock = NSLock()

    public init(suiteName: String = AppGroup.identifier) {
        self.defaults = UserDefaults(suiteName: suiteName)
    }

    public func save(_ snapshot: UsageSnapshot) {
        lock.lock(); defer { lock.unlock() }
        guard let data = try? JSONEncoder().encode(CodableSnapshot(snapshot)) else { return }
        defaults?.set(data, forKey: key)
    }

    public func load() -> UsageSnapshot? {
        lock.lock(); defer { lock.unlock() }
        guard let data = defaults?.data(forKey: key),
              let decoded = try? JSONDecoder().decode(CodableSnapshot.self, from: data) else {
            return nil
        }
        return decoded.snapshot
    }
}

/// `UsageSnapshot`'s members are hand-rolled value types without `Codable`
/// conformance (to keep the domain layer's public API minimal); this
/// private mirror exists solely to (de)serialize the cache.
private struct CodableSnapshot: Codable {
    struct Period: Codable {
        let id: String
        let type: UsagePeriodType
        let usedSeconds: Double
        let limitSeconds: Double
        let resetDate: Date
    }
    struct Provider: Codable {
        let id: String
        let name: String
        let symbolName: String
        let accent: ColorToken
    }
    let provider: Provider
    let periods: [Period]
    let lastUpdated: Date

    init(_ snapshot: UsageSnapshot) {
        provider = Provider(
            id: snapshot.provider.id,
            name: snapshot.provider.name,
            symbolName: snapshot.provider.symbolName,
            accent: snapshot.provider.accent
        )
        periods = snapshot.periods.map {
            Period(id: $0.id, type: $0.type, usedSeconds: $0.used.secondsDouble, limitSeconds: $0.limit.secondsDouble, resetDate: $0.resetDate)
        }
        lastUpdated = snapshot.lastUpdated
    }

    var snapshot: UsageSnapshot {
        UsageSnapshot(
            provider: AgentProvider(id: provider.id, name: provider.name, symbolName: provider.symbolName, accent: provider.accent),
            periods: periods.map {
                UsagePeriod(id: $0.id, type: $0.type, used: .seconds($0.usedSeconds), limit: .seconds($0.limitSeconds), resetDate: $0.resetDate)
            },
            lastUpdated: lastUpdated
        )
    }
}
