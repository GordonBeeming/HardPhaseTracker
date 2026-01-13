# AI Agent Instructions (HardPhaseTracker)

These instructions apply to all AI agents (GitHub Copilot, OpenCode, etc.) working on this project.

When you have questions:
- Ask each question one at a time
- Wait for an answer before asking the next question
- If there are several options, present them clearly with labels (A, B, C, etc.)

## Project context

- SwiftUI iOS app targeting **iPhone + iPad** (universal).
- Long-term direction (do not implement yet): see `docs/00-Initial-Requirements.md` (HealthKit read, fasting engine, named meals, Sodii tracker, SwiftData persistence, theming).

## Repository structure

Current structure (organized by responsibility):
- `App/` - App entry point, app-wide wiring
- `Common/` - Shared code (UI components, domain models, utilities)
  - `UI/` - Reusable SwiftUI views
  - `Domain/` - Core data models
  - `Extensions/` - Swift/SwiftUI extensions
- `Features/` - Feature modules (preferred for new code)
  - Each feature contains its UI, state, and services
- `Shared/` - Cross-cutting concerns (SwiftData, CloudKit)
- `Theme/` - Colors, typography, styling
- `Resources/` - Assets, Info.plist, entitlements

## Coding guidelines

- Prefer **Vertical Slice Architecture**: group code by feature (UI + state + services) under `HardPhaseTracker/Features/<FeatureName>/...`.
- Keep files small and reviewable; avoid "god views" and large, multi-purpose types.
- Prefer small, composable SwiftUI views; keep view models/services testable.
- Keep iPhone/iPad layouts adaptive (size classes, dynamic type) rather than branching per device unless necessary.
- Don't build future features from the requirements doc unless explicitly asked.

## Testing expectations

- Write tests for significant features and logic changes
- Prefer **Swift Testing** (`HardPhaseTrackerTests`, `import Testing`) for unit tests
  - Pure logic: date math, aggregation, calculations, data transformations
  - Use `@Test func testName()` with `#expect(condition)` syntax
- **UI Tests are disabled** - they timeout in CI pipeline, avoid creating new UI tests
- Design for testability: use dependency injection (e.g., `Clock`/time provider, `HealthKitClient` protocol)
- Test files should be comprehensive, covering main functionality and edge cases
- AI agents can run iOS builds and tests via xcodebuild commands

## User action callouts (IMPORTANT)

- Whenever the user needs to do something manually (re-run, reset simulator/app data, etc.), prefix the message with **🚨🚨🚨**.
- Example: if we make a SwiftData schema change that can't migrate cleanly (e.g., adding a new _non-optional_ property), call it out explicitly:
  - **🚨🚨🚨 Action required:** delete the app from the Simulator (or erase simulator content) to clear the SwiftData store, then re-run.

## Device support (IMPORTANT)

- Target **both iPhone and iPad**: verify layouts in compact + regular size classes.
- Avoid hard-coded widths/heights; use adaptive SwiftUI layout and consider iPad-first patterns (e.g., split views where appropriate).

## Branching + publish workflow

- **All new changes happen in their own branch** (feature/fix/chore).
- "Publish" means **squash-merge to `main`**.
  - Early development: we may squash locally to `main`.
  - Once released (or when we want more rigor): push branch to GitHub, open a PR, and **squash merge**.

## Git rules (CRITICAL)

1. **NEVER commit** unless the user explicitly asks you to.
2. **NEVER push** to remote repositories.
3. **NEVER change git config** (local or global). When committing is requested, run plain `git commit` and rely on the user's existing git configuration (no `git config` changes and no overriding author identity).
4. **Follow conventional commit format**: `feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`

## AI Task Documentation

When creating documentation files (MD files) during AI-assisted development, follow these guidelines to avoid unnecessary documentation noise:

### When to Create New Documentation

**DO create new documentation for**:

- Significant architectural changes or new features
- Major refactorings that affect multiple modules
- New patterns or conventions being established
- Implementation guides that will be referenced by others
- Complex changes that need detailed explanation for future reference

**DO NOT create new documentation for**:

- Minor bug fixes or corrections
- Small adjustments to existing code
- Clarifications or improvements to existing implementations
- Changes that can be adequately explained in commit messages

**When unsure**: Ask if documentation should be created before writing it. It's better to update existing documentation than create redundant files.

### Documentation File Naming Format

All documentation files created during AI-assisted tasks should be saved to `docs/ai-tasks/` with the following format:

yyyyMMdd-II-XX-description.md

Where:

- `yyyyMMdd` = Current date (e.g., 20251002)
- `II` = Author's initials from git config (e.g., GB for Gordon Beeming)
- `XX` = Sequential number starting at 01 for the day (01, 02, 03, etc.)
- `description` = Kebab-case description of the task/document

### Examples

- `20251002-GB-01-graceful-row-failure-implementation-summary.md`
- `20251002-GB-02-graceful-row-failure-refactoring-guide.md`
- `20251002-GB-03-graceful-row-failure-changes-summary.md`

### Process

1. **Determine if documentation is needed** - Is this a significant change?
2. Get current date in yyyyMMdd format
3. Get author initials from git config or developer identity
4. Check existing files in `docs/ai-tasks/` for today's date to determine next sequence number
5. Check if existing documentation should be **updated** instead of creating new
6. Create file with proper naming format only if needed
7. If multiple related documents, use sequential numbers to maintain order

### Updating Existing Documentation

Prefer updating existing documentation when:

- The change is related to a recent task documented today
- It's a bug fix or improvement to something recently implemented
- It adds clarification or correction to existing docs
- The change is minor and fits within the scope of existing documentation
