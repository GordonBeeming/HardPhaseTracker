# Initial App Build Execution Plan (HardPhase Tracker)

This doc turns `docs/00-Initial-Requirements.md` into an execution plan broken into small, **testable**, **publishable** sections.

## Working Agreement (Branches + “Publish”)

**Default workflow (most common):**
- Create a new branch for every change set (feature/fix/chore).
- Complete one section below.
- Test.
- **Publish** by **squash-merging to `main`** (either locally or via PR—see below).

**Before first release (early build):**
- We may choose to **squash locally onto `main`**.

**After first release (or when we want more rigor):**
- Prefer pushing the branch to GitHub and merging via a **Pull Request**.
- Still **squash merge** into `main`.

Suggested branch naming:
- `feature/<short-name>` (e.g., `feature/fasting-timer`)
- `fix/<short-name>`
- `chore/<short-name>`

---

## Definition of Done (per section)

Each section below is “done” when:
- ✅ Works on **iPhone and iPad** (at minimum: compact + regular size classes)
- ✅ Looks native/responsive (no clipped UI, sensible spacing, supports rotation where applicable)
- ✅ Code is structured as **Vertical Slice Architecture** (feature folders), with small reviewable files
- ✅ Tests added/updated:
  - Logic: **Swift Testing** (`HardPhaseTrackerTests`) where feasible
  - Critical flows: **XCUITest** (`HardPhaseTrackerUITests`) for smoke coverage
- ✅ No obvious regressions in existing flows
- ✅ A short PR description (or local notes) explains what changed
- ✅ Squash merge to `main`

---

## Testing strategy (iOS)

### What we test
- **Pure logic** (fasting duration math, daily tallying, weekly aggregation, date boundaries) as unit-style tests using **Swift Testing**.
- **Integration seams** via dependency injection (e.g., clock/time provider, HealthKit client protocol, SwiftData container) so logic stays testable.
- **Critical user journeys** via **XCUITest** (launch, navigate, create/edit/delete template, log meal, log Sodii).

### Device coverage
- For each milestone, do a quick pass on:
  - iPhone simulator (compact)
  - iPad simulator (regular)
- Prefer layouts that adapt via size classes and SwiftUI containers (avoid hard-coded widths).

---

## Milestone 0 — Foundation / Project Skeleton

### Scope
- Establish app structure and baseline navigation matching the target UI structure: **Dashboard**, **Meal Manager**, **Analysis**.
- Remove template/demo code (`Item`) once replaced by real models.

### Build
- [x] Set up root navigation (TabView or NavigationSplitView) with 3 destinations:
  - [x] Dashboard
  - [x] Meals
  - [x] Analysis
- [x] Add placeholder screens with titles and empty states
- [x] Add SwiftData container wiring to support upcoming models

### Test
- [x] App launches without crashes
- [x] Can navigate between the 3 main areas

### Publish
- [x] Squash merge to `main`

---

## Milestone 1 — Theming + Visual Identity Baseline

### Scope
- Adaptive theming (system light/dark) using the palette from the requirements.
- Set baseline typography and reusable components.

### Build
- [x] Define named colors for light/dark (Asset Catalog color sets or a Theme layer)
  - Background, Text, Primary, Accent, Divider
- [x] Apply consistent background/text colors across all primary screens
- [x] Add app icon + branding placeholder for “Vitality Drop” (final asset can come later)
- [x] Create reusable button styles for primary actions

### Test
- [x] Run in Light Mode: colors match spec
- [x] Run in Dark Mode: colors match spec
- [x] Snapshot/manual QA: no illegible text or low contrast

### Publish
- [x] Squash merge to `main`

---

## Milestone 2 — Data Model: Meals + Templates (SwiftData)

### Scope
- Implement the “Named Meals” template system (CRUD) in SwiftData.

### Build
- [x] Replace `Item` model with real models (minimum viable):
  - [x] `MealTemplate` (name, macros totals)
  - [x] `MealComponent` (name, grams)
  - [x] Relationship: template → components
- [x] Do **not** seed personal meal templates (start empty)
- [x] Add migrations/compat strategy (at least: handle fresh install + future changes)

### Test
- [x] Unit tests: creating/saving/loading templates (in-memory SwiftData container)
- [ ] Manual: confirm Meals starts empty on fresh install

### Publish
- [x] Squash merge to `main`

---

## Milestone 3 — Meal Manager UI (CRUD)

### Scope
- Full UI for listing, adding, editing, deleting templates and their components.

### Build
- [x] Meal Manager list view for templates
- [x] “Add New Meal” flow:
  - [x] Name
  - [x] Components (name + grams)
  - [x] Macros totals (protein/carbs/fats) for template
- [x] Edit existing template
- [x] Delete template

### Test
- [x] UI test: create template → verify appears in list
- [x] UI test: edit template → changes persist
- [x] UI test: delete template → removed from list

### Publish
- [x] Squash merge to `main`

---

## Milestone 4 — Meal Logging + Fasting Engine (Core)

### Scope
- Log a meal from a template (one tap).
- Compute fasting start time based on last logged meal.
- Live timer display (days/hours/minutes) + phase colors.
- Show whether the user is **inside/outside their eating window** (does not block logging).

### Build
- [x] Add SwiftData model for meal events:
  - [x] `MealLogEntry` (timestamp, template reference, optional notes)
  - [x] Store meal timezone details (identifier + UTC offset)
- [x] Dashboard “Log Meal” button that opens a template picker/drawer
- [x] Tapping a template logs it immediately (confirm UI optional)
- [x] Fasting engine:
  - [x] Determine last meal timestamp
  - [x] Live timer since last meal
  - [x] Phase thresholds + visual changes (24h / 48h / 72h+)
- [x] Eating window schedules:
  - [x] Seed common templates
  - [x] Add custom schedule creation
  - [x] Evaluate schedule using current device timezone
  - [x] Display in/out of window on Dashboard

### Test
- [x] Unit tests: fasting duration calculation given meal timestamps
- [ ] Manual: log meal → timer resets
- [ ] Manual: advance time (debug) / simulate older meal → phase color shifts

### Publish
- [x] Squash merge to `main`

---

## Milestone 5 — Electrolyte Log (Sodii Tracker)

### Scope
- Track daily electrolyte servings vs a per-day target.
- Allow logging inside the fasting window (separate from meals).

### Build
- [x] SwiftData models:
  - [x] `ElectrolyteTargetSetting` (effective-date target so past days do not change)
  - [x] `ElectrolyteIntakeEntry` (timestamp + slot index + optional template)
- [x] Meal templates can be flagged as electrolytes + have components
- [x] Settings:
  - [x] Set servings/day (applies today+ only)
  - [x] Choose electrolyte templates
  - [x] “Ask me each time” option
- [x] Dashboard:
  - [x] Electrolyte checklist shown outside warning styling
- [x] Log tab:
  - [x] Electrolytes appear inline with meals, ordered by timestamp
  - [x] Add button can log electrolytes too

### Test
- [ ] Unit tests: daily tally/date boundary rules for electrolyte entries
- [ ] Manual: iPhone + iPad pass (checklist UI <5 vs 5+)

### Publish
- [ ] Squash merge to `main`

---

## Milestone 6 — HealthKit Integration (Read Weight + Sleep)

### Scope
- Read weight + body fat % + sleep analysis from Apple Health.
- Present data in app (read-only).

### Build
- [ ] Add HealthKit capability + entitlements
- [ ] Request authorization (read-only):
  - [ ] `bodyMass`
  - [ ] `bodyFatPercentage`
  - [ ] `sleepAnalysis`
- [ ] Implement data fetch service with:
  - [ ] Latest weight
  - [ ] Last 7 days weight samples
  - [ ] Last N nights sleep summaries
- [ ] Handle permission denied / not available states gracefully

### Test
- [ ] Manual: authorization prompt appears; denied state shows helpful UI
- [ ] Unit tests (where possible): date-range query building + sample mapping

### Publish
- [ ] Squash merge to `main`

---

## Milestone 7 — Dashboard v1 (Timer + Quick Actions + Weight Trend)

### Scope
- Deliver the primary Dashboard described in the spec.

### Build
- [ ] “Vitality Drop” branded fasting timer as primary visual
- [ ] Quick actions: Log Meal + Log Sodii
- [ ] Weight trend graph (last 7 days)
- [ ] Display latest weight (and optionally body fat %)

### Test
- [ ] UI test: Dashboard renders and quick actions present
- [ ] Manual: graph shows data when available; empty state when not

### Publish
- [ ] Squash merge to `main`

---

## Milestone 8 — Analysis View v1 (Sleep ↔ Fasting + Weekly Protein Goal)

### Scope
- Initial insights screens:
  - Sleep quality vs fasting duration
  - Weekly protein goal tracking

### Build
- [ ] Define protein goal rules (clarify “Gordon’s requirement” into a number/logic)
- [ ] Aggregate per-week protein totals based on logged meal templates
- [ ] Sleep vs fasting correlation:
  - [ ] Simple chart/table showing fasting duration and sleep duration/quality
- [ ] UX: clear “insufficient data” empty states

### Test
- [ ] Unit tests: weekly aggregation + goal comparison
- [ ] Manual: correlation view behaves with/without HealthKit sleep data

### Publish
- [ ] Squash merge to `main`

---

## Milestone 9 — Polish / Hardening

### Scope
- Make the app feel shippable and resilient.

### Build
- [ ] Accessibility (Dynamic Type, VoiceOver labels for key controls)
- [ ] Error handling (HealthKit failures, SwiftData failures)
- [ ] Performance (avoid expensive queries on every render)
- [ ] Basic settings screen (optional): targets, thresholds

### Test
- [ ] Manual accessibility pass
- [ ] Regression pass on core flows: log meal, log sodii, timer, template CRUD

### Publish
- [ ] Squash merge to `main`

---

## Milestone 10 — Release Checklist (when we decide to ship)

- [ ] Confirm PR-based workflow (squash merge) for all changes
- [ ] Versioning (CFBundleShortVersionString + build number)
- [ ] App icon final + branding
- [ ] Privacy strings (HealthKit usage descriptions) reviewed
- [ ] Basic App Store metadata (even if not submitting yet)
