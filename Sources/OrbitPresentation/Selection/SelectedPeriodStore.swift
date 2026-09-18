import Foundation
import OrbitCore

/// App-Group-backed store for the app window's own focused period.
///
/// The widget does not use this: each placed widget instance keeps its own
/// focused period in its `SelectUsagePeriodIntent` configuration, which
/// WidgetKit persists per instance. The app has exactly one window, so a
/// single App-Group-backed value is the right model here — it just needs to
/// survive relaunches, the same reason a widget's own state has to survive
/// outside its view hierarchy.
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
