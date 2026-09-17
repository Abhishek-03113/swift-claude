# Orbit — AI agent usage for macOS

A native macOS app and widget that answer one question at a glance: *how much
AI-agent capacity do I have left?* Claude Code is the first supported provider;
the architecture is provider-agnostic.

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
  OrbitApp/              the app: agent list, dial, quota breakdown
  OrbitWidget/           widget definition, timeline provider
  Shared/                dial views + selection intent, used by both targets
Makefile                 build / test / generate / open
```

The split is the point. `OrbitKit` is a plain Swift package with no Apple-UI
dependencies, so the quota math, CLI parsing, caching and visual-state logic
build and test with the Swift toolchain alone — no Xcode, no simulator, no
widget host. Only genuinely SwiftUI/WidgetKit/AppIntents code lives under
`App/`.

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

1. Set your Apple Developer **Team** on both targets, or set
   `DEVELOPMENT_TEAM` in `App/project.yml` and re-run `make generate`.
2. **Set `ORBIT_APP_GROUP`** in `App/project.yml` to
   `$(DEVELOPMENT_TEAM).group.com.orbit.app`. macOS requires the team-ID
   prefix for a non-sandboxed app (see below), and the app and widget must
   name the same group or they read different containers and the widget
   silently stays empty.
3. Build and run the `Orbit` scheme, then add the widget from the macOS
   widget gallery.

Deployment target is macOS 14.0, which is what interactive App-Intent-driven
widgets and `containerBackground` need. The Liquid Glass material
(`glassEffect`) is used only on macOS 26+, with a `Material` fallback below
that — see `GlassSurface`.

`make help` lists the rest.

## Status

This was built in a Linux container with no Apple toolchain, so **nothing here
has been compiled or run**. `make test` on a Mac is the first real validation
step, not a formality.

The `/usage` parsing logic was validated separately against real CLI output
(see "Reading usage" below), but validated logic is not compiled code.

## How it fits together

A `UsageRepository` produces a provider-agnostic `UsageSnapshot`: one
`UsagePeriod` per quota window, each carrying consumption as a clamped
`0...1` fraction plus a reset date. `CachingUsageRepository` wraps any
repository with an App-Group-backed cache and turns a fetch into a
`UsageLoadState` — `.loaded`, `.stale` (last known-good data kept on screen
after a failed refresh), or `.failed`.

`DialPresentationBuilder` turns a snapshot plus the current selection into a
`DialPresentation`: every ring opacity, color, glow radius and accessibility
string already resolved. It stands in for a view model — widgets re-render
from timeline entries rather than observing mutable state, so a pure function
is both the correct shape and directly unit testable.

**The app fetches; the widget reads.** Reading Claude Code's usage means
running its CLI, and a widget extension is sandboxed and cannot spawn
processes. So the app refreshes, writes the snapshot to the App Group, and
reloads the widget's timeline; the widget's `CachedSnapshotRepository` reads
that cache and labels it stale once it ages past 20 minutes.

Both render the same `UsageDialContainer`, differing only in how a tap is
handled — an `AppIntent` in the widget, plain state in the app — which the
`DialSelectionBehavior` parameter carries.

## Reading usage

`ClaudeCodeCLIUsageClient` runs `claude -p "/usage"` and hands the output to
`ClaudeUsageTextParser`, which is a pure function over a string so every
format quirk is testable without spawning anything:

```text
Current session
███                                                6% used
Resets 8:40pm (Asia/Calcutta)

Current week (all models)
████████████▌                                      25% used
Resets Sep 21 at 1:30am (Asia/Calcutta)
```

It handles the progress-bar glyphs (ignored — the percentage is
authoritative), ANSI styling, a same-day `Resets 8:40pm` versus a dated
`Resets Sep 21 at 1:30am`, the timezone in parentheses, a year-less dated
reset rolling correctly into next year, and model-specific caps like
`Current week (Opus)` — carried through as an extra period rather than
discarded.

**Not every account prints quota.** An API-key login prints only the cost
totals, with no `Current session` section at all. That case throws rather than
rendering a dial at zero, and the app explains it instead of showing a
confident wrong number.

`PATH` is not inherited by a GUI app launched from Finder, so the client
locates the binary explicitly (`~/.claude/local`, `~/.local/bin`, Homebrew,
`/usr/local/bin`) rather than relying on `claude` resolving on the path.

## The sandbox decision

**The app is not sandboxed.** App Sandbox forbids executing binaries outside
the container, which rules out running the `claude` CLI — the only way to read
this data today. That trade is deliberate and has a consequence: Orbit cannot
ship on the Mac App Store, and is a directly-distributed developer tool. The
widget extension remains sandboxed, as extensions must be, which is exactly
why it reads a cache instead of fetching.

## Design decisions worth knowing about

These came up reconciling the exported design file against the written product
spec, and were resolved with the project owner during the build:

- **Ring semantics**: the lit arc represents *used* quota (growing as you
  consume it, green -> red), not remaining — per the written spec, overriding
  the design file's opposite convention.
- **Consumption is a fraction, not a duration.** The model stores
  `usedFraction`, because "6% used" is what providers actually report. There
  is no "hours of quota left" figure in the data, so the dial's secondary line
  is time *until reset* — a number that is real — rather than quota
  re-expressed as hours, which would be invented.

## Adding a second provider

Add a type to `Sources/OrbitProviders/`, implement `UsageRepository` (fetch +
normalize into `UsageSnapshot`), give it an `AgentProvider` with its own
`accent`/`symbolName`, and add a slot in `AgentCatalog`. No dial, ring, or
view code changes — that is what the module boundary buys.

Agents without an adapter yet (Codex, Gemini) appear in the app as explicit
"not connected" rows, so the multi-agent shape is visible without inventing
data for them.
