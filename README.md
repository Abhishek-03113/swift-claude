# Orbit — AI agent usage widget for macOS

A native SwiftUI/WidgetKit macOS widget that answers one question at a
glance: *how much AI-agent capacity do I have left?* Claude Code is the
first supported provider; the architecture is provider-agnostic from the
start.

## Why this repo has no `.xcodeproj`

This project was built from a Linux container, which cannot run Xcode or
compile Swift for Apple platforms — nothing here has been compiled,
previewed, or run. Instead of hand-writing a fragile `.xcodeproj` (a
mostly-generated, Xcode-internal format), the project is defined
declaratively in [`Orbit/project.yml`](Orbit/project.yml) using
[XcodeGen](https://github.com/yonaskolb/XcodeGen). On your Mac, XcodeGen
turns this into a real, correctly-wired Xcode project. Treat the first
build on macOS as the actual validation step, not a formality.

## Setup (on macOS)

1. Install Xcode 16+ and open it once to accept the license.
2. Install XcodeGen: `brew install xcodegen`
3. Generate and open the project:
   ```sh
   cd Orbit
   xcodegen generate
   open Orbit.xcodeproj
   ```
4. Set your Apple Developer **Team** on both the `OrbitApp` and
   `OrbitWidgetExtension` targets (Signing & Capabilities), or set
   `DEVELOPMENT_TEAM` in `project.yml` and re-run `xcodegen generate`.
5. Both targets share the App Group `group.com.orbit.app` (declared in
   `project.yml`) — enable it for your team, or change the identifier
   everywhere it appears if you want your own.
6. Build & run the `Orbit` scheme, then add the widget from macOS's widget
   gallery.

Deployment target is macOS 14.0 (needed for interactive App-Intent-driven
widgets and `containerBackground`). The Liquid Glass material
(`glassEffect`) is used only when running on macOS 26+, with a `Material`
fallback below that — see `GlassSurface` in `OrbitWidget/Dial/GlassContainer.swift`.

## What's implemented

**Domain (`Shared/Domain/`)** — provider-agnostic model: `AgentProvider`,
`UsagePeriod` (used/limit as `Duration`, with defensively-clamped
`progress`/`remaining`), `UsagePeriodType`, `UsageSnapshot`,
`UsageRepository` protocol, `UsageLoadState`, and `CachingUsageRepository` /
`UsageSnapshotCache` for the stale-data fallback behavior.

**Providers (`Shared/Providers/`)** — `MockUsageProvider` for previews/tests,
and `ClaudeCode/` (`ClaudeCodeProvider` + `ClaudeCodeUsageClient` protocol +
DTO parsing with validation). See **Known gap** below — the Claude Code
client currently reads a JSON file rather than a live source, because no
public API exists yet for a user's own Claude Code quota.

**Dial UI (`OrbitWidget/Dial/`)** — `UsageRing` (a `Canvas`-based reusable
tick+arc ring component, no Claude-specific logic), `DialMetrics`/
`UsageTypography` design tokens, `DialLayout` (responsive per widget
family), `DialPresentation` + `DialPresentationBuilder` (the pure
snapshot+selection → visual-state transform that stands in for a
traditional ViewModel — widgets re-render from timeline entries rather than
holding observable state, so this is implemented as a pure function rather
than an `ObservableObject`), `UsageDialContainer`, `UsageCenterContent`,
`ProviderBadge`, `ResetCountdown`, `GlassSurface`.

**Interaction (`OrbitWidget/Intents/`)** — `SelectUsagePeriodIntent`, an
`AppIntent` button (the modern WidgetKit interactivity mechanism) that
writes the selection to the App Group and triggers a timeline reload;
`OrbitTimelineProvider` reads it back for the next entry.

**Tests (`OrbitTests/`)** — domain quota math (zero/full/negative/overshoot
usage), the color ramp, duration/reset formatting, Claude Code DTO parsing
(valid/malformed/missing fields), `DialPresentationBuilder` selection
states, and the caching/stale-fallback repository behavior.

## Design decisions worth knowing about

These came up reconciling the two source documents (the exported design
file vs. the written product spec) and were resolved with the project
owner during the build:

- **Ring semantics**: the ring's lit arc represents *used* quota (growing
  as you consume it, colored green→red), not remaining — per the written
  spec, overriding the design file's opposite convention.
- **Center value**: shows a formatted duration ("2h 17m remaining") per the
  spec's typography section, rather than the raw `%` the design mock
  displayed (that was a simplification of the design tool's own demo
  slider, not a hard requirement).
- **Live countdown**: the primary value uses `Text(timerInterval:)` (a
  system-managed, tick-without-rebuilding API) rather than a hand-formatted
  string that would need per-second rebuilds, per the spec's own guidance
  to prefer a system-supported relative-date representation. Its rendered
  format is `H:MM:SS`-style rather than literally "2h 17m" while counting
  down live — a real WidgetKit constraint, not an oversight.

## Known gap: real Claude Code usage data

Anthropic does not currently publish a consumer-facing API for a signed-in
user's own 5-hour/weekly Claude Code quota. `ClaudeCodeLocalFileUsageClient`
(`Shared/Providers/ClaudeCode/ClaudeCodeUsageClient.swift`) defines the
integration seam — it reads a JSON snapshot from the shared App Group
container — but nothing currently writes that file. Wiring up a real
source (a local helper process, a future CLI usage command, a future API)
means implementing `ClaudeCodeUsageClient` and swapping it into
`ClaudeCodeProvider`; no other code changes.

## Adding a second provider

Implement `UsageRepository` (fetch + normalize into `UsageSnapshot`), give
it an `AgentProvider` with its own `accent`/`symbolName`, and wire it into
`OrbitTimelineProvider`. No dial/ring/view code changes needed — that's the
point of the domain boundary.

## Project layout

```
Orbit/
  project.yml
  OrbitApp/                       # Host app (minimal — just hosts the widget)
  OrbitWidget/
    OrbitWidgetBundle.swift       # @main WidgetBundle + Widget + previews
    OrbitTimelineProvider.swift
    OrbitWidgetView.swift         # Loading/error/stale + responsive layout
    OrbitWidgetKind.swift
    Dial/                         # Reusable rendering + design tokens
    Intents/                      # SelectUsagePeriodIntent + selection store
  Shared/
    AppGroup.swift
    Domain/                       # Provider-agnostic model + repository
    Presentation/                 # SelectedUsagePeriod
    Providers/
      MockUsageProvider.swift
      ClaudeCode/
    Support/                      # Color ramp + text formatting
  OrbitTests/
```
