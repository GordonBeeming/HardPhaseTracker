# Copilot instructions (HardPhaseTracker)

## Project context
- SwiftUI iOS app targeting **iPhone + iPad** (universal).
- Long-term direction (do not implement yet): see `docs/00-Initial-Requirements.md` (HealthKit read, fasting engine, named meals, Sodii tracker, SwiftData persistence, theming).

## Repository structure expectations
- Keep code under `HardPhaseTracker/` organized by responsibility:
  - `App/` (App entry point, app-wide wiring)
  - `Views/` (SwiftUI views)
  - `Models/` (data models)
  - `Services/` (e.g., HealthKit, persistence adapters)
  - `Features/` (future feature modules)
  - `Theme/` (colors, typography, styling)
  - `Resources/` (Assets, Info.plist, entitlements)

## Coding guidelines
- Prefer small, composable SwiftUI views; keep view models/services testable.
- Keep iPhone/iPad layouts adaptive (size classes, dynamic type) rather than branching per device unless necessary.
- Don’t build future features from the requirements doc unless explicitly asked.

## Git rules (IMPORTANT)
1. **Do not commit** unless the user explicitly asks you to.
2. **Do not change git config** (local or global). When committing is requested, run plain `git commit` and rely on the user’s existing git configuration (no `git config` changes and no overriding author identity).
