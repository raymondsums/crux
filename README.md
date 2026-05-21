# Crux

A bouldering companion for Apple Watch that watches your heart rate and tells you when you've recovered enough to climb again.

## The idea

Between attempts on a hard boulder problem, the question is always the same: *am I rested enough to try again?* Rest too little and you fail the move; rest too long and you waste skin and session time. Climbers usually just guess.

Crux turns that guess into a signal. It monitors your heart rate through a session, detects when you've dropped back to your recovery threshold, and tells you — with a haptic tap and a "READY TO CLIMB" cue — that it's time to pull on again. No need to look at the watch; you're on the wall.

## Features

- **Recovery detection** — a heart-rate state machine (elevated → recovering → recovered) with hysteresis so noisy readings don't make it flicker. A haptic fires the moment you're recovered.
- **Live heart rate** — a large, glanceable BPM read from a real HealthKit workout session.
- **Route logging** — tap V-grade columns to log sends; a bar chart builds as the session goes.
- **Session summary** — peak HR, average recovery time, active vs. rest split, and climbs logged.
- **History** — past sessions saved on-device.
- **Eyes-free by design** — haptics and color-coded state, so you don't have to study the screen mid-climb.

## How recovery is detected

Crux runs an `HKWorkoutSession` and streams heart rate live. A small state machine classifies each reading against your recovery threshold (configurable in Settings):

- **Elevated** — well above threshold; you're climbing.
- **Recovering** — heart rate dropping back down.
- **Recovered** — at or below threshold → haptic + "READY TO CLIMB".

The threshold has hysteresis built in, so a noisy reading near the boundary won't bounce the state back and forth.

## Build & run

Requirements: Xcode 26, an Apple Watch (watchOS 26+), and an Apple ID for signing (a free account is enough for development).

1. Open `Crux.xcodeproj`.
2. Pick your team under **Signing & Capabilities**.
3. Build to a paired Apple Watch.

Note: the **Simulator cannot produce heart-rate data** — the UI runs there, but the recovery feature only works on a physical Apple Watch.

## Project layout

```
Crux Watch App/
  CruxApp.swift          app entry point
  ContentView.swift      root navigation
  Models/                workout session, route log, history, settings
  Views/                 onboarding, heart rate, route logger, summary, history
  Utils/                 haptics
```

`preview.html` is a standalone HTML mockup of the interface, used during design.
