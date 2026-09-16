import AppIntents
import OrbitPresentation
import WidgetKit

/// Backs the session <-> weekly tap interaction.
///
/// Widgets rebuild from timeline entries rather than holding live view state,
/// so the selection has to live somewhere durable: this writes it to the
/// shared App Group and asks WidgetKit to reload, and `OrbitTimelineProvider`
/// reads it back when building the next entry. An App Intents button is the
/// supported interactivity mechanism — widgets cannot host gesture
/// recognizers.
struct SelectUsagePeriodIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Usage Period"
    static var description = IntentDescription("Switches the Orbit widget's focused quota between session and weekly.")

    @Parameter(title: "Period")
    var period: UsagePeriodAppEnum

    init() {
        period = .session
    }

    init(period: SelectedUsagePeriod) {
        self.period = UsagePeriodAppEnum(period)
    }

    func perform() async throws -> some IntentResult {
        SelectedPeriodStore.shared.save(period.selection)
        WidgetCenter.shared.reloadTimelines(ofKind: OrbitWidget.kind)
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
