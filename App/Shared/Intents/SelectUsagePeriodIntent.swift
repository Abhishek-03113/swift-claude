import AppIntents
import OrbitPresentation
import WidgetKit

/// Backs the session <-> weekly tap interaction, and doubles as the widget's
/// own per-instance configuration.
///
/// This is also `OrbitWidget`'s `AppIntentConfiguration` intent: WidgetKit
/// persists one instance of it per placed widget, so three widgets on the
/// desktop each remember their own focused period rather than sharing one
/// value the way a plain App-Group-backed store would. Running this intent —
/// which a tap on a ring does, by constructing a new instance with the
/// flipped period — is exactly how a configuration intent updates the
/// widget instance that invoked it; there's no separate "write configuration"
/// call to make.
struct SelectUsagePeriodIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Usage Period"
    static var description = IntentDescription("Switches the Orbit widget's focused quota between session and weekly.")

    @Parameter(title: "Period", default: .session)
    var period: UsagePeriodAppEnum

    init() {
        period = .session
    }

    init(period: SelectedUsagePeriod) {
        self.period = UsagePeriodAppEnum(period)
    }

    func perform() async throws -> some IntentResult {
        // Any tap on the dial is also treated as "show me current numbers".
        // The widget has no room for a separate refresh control, and asking
        // OrbitAgent to re-read is cheap and idempotent — the daemon is
        // always running, so this reliably lands rather than depending on
        // the main app happening to be open.
        RefreshSignal.postRefreshRequested()
        return .result()
    }
}

/// App Intents requires its own enum conformance, so this mirrors
/// `SelectedUsagePeriod` rather than the domain type adopting `AppEnum` and
/// dragging the framework into the package.
enum UsagePeriodAppEnum: String, AppEnum {
    case session
    case weekly

    init(_ selection: SelectedUsagePeriod) {
        switch selection {
        case .session: self = .session
        case .weekly: self = .weekly
        }
    }

    var selection: SelectedUsagePeriod {
        switch self {
        case .session: return .session
        case .weekly: return .weekly
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Usage Period"
    static var caseDisplayRepresentations: [UsagePeriodAppEnum: DisplayRepresentation] = [
        .session: "Session",
        .weekly: "Weekly",
    ]
}
