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

1. Copy `App/.env.example` to `App/.env` and set `ORBIT_TEAM_ID` to your
   Apple Developer Team ID (Membership tab at developer.apple.com/account).
   `make generate`/`make open`/`make app` source it automatically. `App/.env`
   is gitignored — it's the only file that should hold this.
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
