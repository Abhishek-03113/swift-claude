# Orbit — AI agent usage widget for macOS

A native SwiftUI/WidgetKit macOS widget that answers one question at a
glance: *how much AI-agent capacity do I have left?* Claude Code is the
first supported provider; the architecture is provider-agnostic.

## Layout

```
Package.swift            OrbitKit — everything that isn't SwiftUI
Sources/
  OrbitCore/             usage model, repository contract, caching, formatting
  OrbitProviders/        adapters that produce a UsageSnapshot
  OrbitPresentation/     snapshot + selection -> resolved visual state
Tests/                   one suite per module, runs with `swift test`
App/
  project.yml            XcodeGen definition of the app + widget targets
  OrbitApp/              host app (minimal — it exists to ship the widget)
  OrbitWidget/           SwiftUI views, timeline provider, App Intent
Makefile                 build / test / generate / open
```

The split is the point. `OrbitKit` is a plain Swift package with no Apple-UI
dependencies, so the quota math, parsing, caching and visual-state logic build
and test with the Swift toolchain alone — no Xcode, no simulator, no widget
host. Only genuinely SwiftUI/WidgetKit/AppIntents code lives under `App/`.

Module dependencies run one way:

```
OrbitCore  <--  OrbitProviders
     ^
     +--------  OrbitPresentation
```

`OrbitPresentation` cannot import `OrbitProviders`, so provider-specific
knowledge cannot reach the dial even by accident. That boundary is a compiler
rule rather than a convention.

## Setup

Package only (any machine with a Swift 5.9+ toolchain):

```sh
make test
```

App and widget (macOS, Xcode 16+):

```sh
brew install xcodegen
make open
```

Then:

1. Set your Apple Developer **Team** on both the `OrbitApp` and
   `OrbitWidgetExtension` targets, or set `DEVELOPMENT_TEAM` in
   `App/project.yml` and re-run `make generate`.
2. Both targets share the App Group `group.com.orbit.app` — enable it for
   your team, or change the identifier in `App/project.yml` and
   `Sources/OrbitCore/AppGroup/AppGroup.swift` (the two must match).
3. Build and run the `Orbit` scheme, then add the widget from the macOS
   widget gallery.

Deployment target is macOS 14.0, which is what interactive App-Intent-driven
widgets and `containerBackground` need. The Liquid Glass material
(`glassEffect`) is used only on macOS 26+, with a `Material` fallback below
that — see `GlassSurface`.

`make help` lists the rest.

## Status

This was built in a Linux container with no Apple toolchain, so **nothing
here has been compiled or run**. `make test` on a Mac is the first real
validation step, not a formality. CI (`.github/workflows/ci.yml`) runs both
the package tests and an unsigned app build on every push.

## How it fits together

A `UsageRepository` produces a provider-agnostic `UsageSnapshot` (one
`UsagePeriod` per quota window, with `used`/`limit` as `Duration`s and
defensively clamped `progress`/`remaining`). `CachingUsageRepository` wraps
any repository with an App-Group-backed cache and turns a fetch into a
`UsageLoadState` — `.loaded`, `.stale` (last known-good data kept on screen
after a failed refresh), or `.failed`.

`DialPresentationBuilder` turns a snapshot plus the current selection into a
`DialPresentation`: every ring opacity, color, glow radius and accessibility
string already resolved. It stands in for a view model — widgets re-render
from timeline entries rather than observing mutable state, so a pure function
is both the correct shape and directly unit testable.

The widget then renders that presentation and nothing else. `UsageRing` draws
a tick band with `Canvas`; `UsageDialContainer` assembles the two rings, the
glass core and the tap targets. Tapping runs `SelectUsagePeriodIntent`, which
writes the selection to the App Group and reloads the timeline —
`OrbitTimelineProvider` reads it back for the next entry.

## Design decisions worth knowing about

These came up reconciling the exported design file against the written
product spec, and were resolved with the project owner during the build:

- **Ring semantics**: the lit arc represents *used* quota (growing as you
  consume it, green -> red), not remaining — per the written spec, overriding
  the design file's opposite convention.
- **Center value**: a formatted duration ("2h 17m remaining") per the spec's
  typography section, rather than the raw `%` in the design mock.
- **Live countdown**: the primary value uses `Text(timerInterval:)`, a
  system-managed API that ticks without per-second rebuilds. While counting
  down live it renders as `H:MM:SS` rather than literally "2h 17m" — a
  WidgetKit constraint, not an oversight.

## Known gap: real Claude Code usage data

Anthropic does not currently publish a consumer-facing API for a signed-in
user's own 5-hour/weekly Claude Code quota, so there is no live source to
wire up yet.

`ClaudeCodeLocalFileUsageClient` is the seam meant for whatever the real
source turns out to be. It reads `claude-usage.json` from the shared App
Group container:

```json
{
  "session": { "usedSeconds": 8820, "limitSeconds": 18000, "resetsAt": "2026-09-16T21:00:00Z" },
  "weekly":  { "usedSeconds": 356400, "limitSeconds": 604800, "resetsAt": "2026-09-22T09:00:00Z" },
  "generatedAt": "2026-09-16T18:00:00Z"
}
```

Nothing currently writes that file, so the provider reports `.unavailable`
and the widget shows its unavailable state. (It does **not** silently fall
back to mock data — sample numbers appear only in previews.) Wiring up a real
source means implementing `ClaudeCodeUsageClient` and passing it to
`ClaudeCodeProvider`; no other code changes.

## Adding a second provider

Add a target to `Sources/OrbitProviders/`, implement `UsageRepository`
(fetch + normalize into `UsageSnapshot`), give it an `AgentProvider` with its
own `accent`/`symbolName`, and pass it to `OrbitTimelineProvider`. No dial,
ring, or view code changes — that is what the module boundary buys.
