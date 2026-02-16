# Glass Design System

This app uses a shared glass-surface system for cards, sections, and tab chrome.

## Core Rules

1. Use `glassCard(...)` for card containers instead of ad hoc `RoundedRectangle(...).fill(...)`.
2. Use theme tokens in `AppTheme` for all glass color/stroke/shadow values.
3. Keep one background treatment per screen via `.appScreen()`.
4. Do not add root-level drag gestures to `TabView`.
5. Keep tab-root async work lazy/guarded to avoid transition stutter.

## Primary Building Blocks

- `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Common/UI/GlassSurface.swift`
- `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Theme/AppTheme.swift`
- `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Theme/AppScreenModifier.swift`
- `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/App/HardPhaseTrackerApp.swift`

## Migration Pattern

Before:
- Opaque card background (`Color(.systemBackground)`)

After:
- `content.glassCard()`

## Motion Guidance

- Prefer native tab transitions.
- Use short, local animations for controls and progress only.
- Avoid global gestures that can conflict with lists, charts, or calendars.
