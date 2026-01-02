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

## Testing expectations
- Write tests as we go; each feature should land with the **standard iOS tests** we can reasonably add.
- Prefer **Swift Testing** (`HardPhaseTrackerTests`, `import Testing`) for pure logic (date math, aggregation, calculations).
- Use **XCUITest** (`HardPhaseTrackerUITests`) for critical end-to-end flows (smoke tests).
- Design for testability: use dependency injection (e.g., `Clock`/time provider, `HealthKitClient` protocol) so logic can be tested without real HealthKit.

## Device support (IMPORTANT)
- Target **both iPhone and iPad**: verify layouts in compact + regular size classes.
- Avoid hard-coded widths/heights; use adaptive SwiftUI layout and consider iPad-first patterns (e.g., split views where appropriate).

## Branching + publish workflow
- **All new changes happen in their own branch** (feature/fix/chore).
- “Publish” means **squash-merge to `main`**.
  - Early development: we may squash locally to `main`.
  - Once released (or when we want more rigor): push branch to GitHub, open a PR, and **squash merge**.

## Git rules (IMPORTANT)
1. **Do not commit** unless the user explicitly asks you to.
2. **Do not change git config** (local or global). When committing is requested, run plain `git commit` and rely on the user’s existing git configuration (no `git config` changes and no overriding author identity).
