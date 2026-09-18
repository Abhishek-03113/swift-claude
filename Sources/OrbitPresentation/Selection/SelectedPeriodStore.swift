import Foundation
import OrbitCore

/// App-Group-backed store for the focused period, shared between the intent
/// that writes it and the timeline provider that reads it back.
///
/// Widgets rebuild from timeline entries rather than holding live state, so
/// the selection has to survive outside the view hierarchy.
public struct SelectedPeriodStore: Sendable {
    public static let shared = SelectedPeriodStore()

    private static let key = "orbit.selected.period"

    private let store: AppGroupStore

    public init(store: AppGroupStore = .shared) {
        self.store = store
    }

    public func load() -> SelectedUsagePeriod {
        store.readString(forKey: Self.key).flatMap(SelectedUsagePeriod.init(rawValue:)) ?? .session
    }

    public func save(_ period: SelectedUsagePeriod) {
        store.writeString(period.rawValue, forKey: Self.key)
    }
}
