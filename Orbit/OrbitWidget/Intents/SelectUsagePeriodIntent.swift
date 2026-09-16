import AppIntents
import WidgetKit
import Foundation

/// Backs the Session ↔ Weekly tap interaction. WidgetKit widgets re-render
/// fresh from each timeline entry rather than holding live view-model
/// state, so the "current selection" has to live somewhere durable: this
/// intent writes it to the shared App Group defaults and asks WidgetKit to
/// reload, and `OrbitTimelineProvider` reads it back when building the next
/// entry. This is the standard interactive-widget pattern (App Intents
/// button in the widget view) rather than a custom gesture recognizer,
/// which widgets cannot host.
struct SelectUsagePeriodIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Usage Period"
    static var description = IntentDescription("Switches the Orbit widget's focused quota between session and weekly.")

    @Parameter(title: "Period")
    var period: SelectedUsagePeriodAppEnum

    init() {
        period = .session
    }

    init(period: SelectedUsagePeriod) {
        self.period = SelectedUsagePeriodAppEnum(period)
    }

    func perform() async throws -> some IntentResult {
        SelectedPeriodStore.shared.set(period.domainValue)
        WidgetCenter.shared.reloadTimelines(ofKind: OrbitWidgetKind.identifier)
        return .result()
    }
}

/// `AppEnum` wrapper around the domain's `SelectedUsagePeriod` — App Intents
/// requires its own enum conformance, so the domain type itself stays free
/// of that framework dependency.
enum SelectedUsagePeriodAppEnum: String, AppEnum {
    case session
    case weekly

    init(_ value: SelectedUsagePeriod) {
        switch value {
        case .session: self = .session
        case .weekly: self = .weekly
        }
    }

    var domainValue: SelectedUsagePeriod {
        switch self {
        case .session: return .session
        case .weekly: return .weekly
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Usage Period"
    static var caseDisplayRepresentations: [SelectedUsagePeriodAppEnum: DisplayRepresentation] = [
        .session: "Session",
        .weekly: "Weekly",
    ]
}

/// Small App-Group-backed store for the currently-selected period, shared
/// between the intent (which writes) and the timeline provider (which
/// reads). Deliberately tiny — this is the widget's entire persisted state.
final class SelectedPeriodStore: @unchecked Sendable {
    static let shared = SelectedPeriodStore()

    private let defaults: UserDefaults?
    private let key = "orbit.selected.period"

    init(suiteName: String = AppGroup.identifier) {
        defaults = UserDefaults(suiteName: suiteName)
    }

    func get() -> SelectedUsagePeriod {
        guard let raw = defaults?.string(forKey: key), let value = SelectedUsagePeriod(rawValue: raw) else {
            return .session
        }
        return value
    }

    func set(_ value: SelectedUsagePeriod) {
        defaults?.set(value.rawValue, forKey: key)
    }
}
