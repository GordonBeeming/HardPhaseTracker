# Liquid Glass + Tab Transition Audit

- Date: 2026-02-15
- Repo: /Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker
- Scope: Visual design system alignment to liquid-glass patterns + tab transition smoothness
- Analyst: Codex (parallel exploration across root navigation, theme layer, tab roots, and screenshot validation)

## Summary

The current app uses mostly opaque, grouped-background cards and a global drag gesture on the root `TabView`. This makes the UI feel closer to classic iOS grouped forms than liquid glass, and likely contributes to the tab-switching jank.

## Key Findings (What is not correct today)

1. Root tab container uses a global swipe gesture that competes with child gestures.
- Evidence: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Views/ContentView.swift:44`
- Why it matters: A root-level `DragGesture` can conflict with horizontal/diagonal interactions in child views (for example graphical date pickers and chart pans), causing accidental tab changes and perceived stutter.

2. Design system does not define reusable liquid-glass surfaces.
- Evidence: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Theme/AppTheme.swift:20`
- Evidence: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Theme/AppScreenModifier.swift:10`
- Why it matters: `systemBackground`/`systemGroupedBackground` are flat/opaque defaults; there is no shared material blur, translucency scale, highlight, or elevation model.

3. Feature screens hardcode opaque card fills instead of material-backed surfaces.
- Evidence: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Dashboard/DashboardView.swift:60`
- Evidence: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Log/LogView.swift:35`
- Why it matters: Inconsistent depth model and no “refractive” feel; visual language diverges across sections.

4. Tab bar/navigation chrome is not styled as a coherent glass system.
- Evidence: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Views/ContentView.swift:19`
- Why it matters: Liquid-glass patterns rely on layered/translucent chrome and consistent surface blending; current chrome reads mostly default.

5. Potential tab-switch performance pressure from eager heavy content in all tabs.
- Evidence: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Dashboard/DashboardView.swift:66` (`TimelineView`)
- Evidence: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Analysis/AnalysisView.swift:256` (`.task` Health refresh)
- Why it matters: Multiple live queries/timelines/tasks across tab roots can make transitions feel less smooth on lower-end devices.

6. Visual confirmation from screenshots matches code findings.
- Evidence sampled:
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/AppStore/Screenshots/iPhone/iPhone-19-01-42.png`
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/AppStore/Screenshots/iPhone/iPhone-19-03-25.png`
- Why it matters: Current UI is dark and polished, but primarily opaque blocks rather than liquid translucent layers.

## Proposed Task List (Execution Plan)

## Phase 1: Remove Interaction Jank First
- [x] T1. Remove or gate the root `TabView` drag gesture.
  - File: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Views/ContentView.swift`
  - Preferred change: remove the custom swipe handler entirely and rely on native tab switching.
  - Alternative (if swipe is required): attach swipe only to explicit full-screen pager surfaces, never global root.
  - Acceptance: No accidental tab switch while interacting with calendar/chart/content gestures.

- [x] T2. Stabilize tab selection state and tab identity.
  - File: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Views/ContentView.swift`
  - Change: migrate `selectedTab` from raw `Int` to `enum` for safety/readability and fewer accidental mismatches.
  - Acceptance: Tab selection remains correct across app lifecycle and future refactors.

## Phase 2: Introduce Liquid-Glass Design Tokens + Primitives
- [x] T3. Add shared glass surface tokens in theme layer.
  - Files:
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Theme/AppTheme.swift`
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Theme/AppScreenModifier.swift`
  - Change: define material/elevation/edge highlight/shadow tokens; avoid per-screen ad hoc fills.
  - Acceptance: One central source defines glass behavior for cards, grouped sections, and overlays.

- [x] T4. Create reusable `GlassCard` and `GlassSection` modifiers/components.
  - New file target: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Common/UI/GlassSurface.swift`
  - Change: encapsulate `Material` background, subtle stroke, corner radius, depth shadow.
  - Acceptance: Features consume shared surface components, not raw `RoundedRectangle.fill(Color...)`.

## Phase 3: Apply Glass Surfaces to Core Tabs
- [x] T5. Migrate Dashboard cards to glass surfaces.
  - File: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Dashboard/DashboardView.swift`
  - Acceptance: Existing cards keep semantics/content but adopt consistent glass treatment.

- [x] T6. Migrate Log header/status container and list sections.
  - Files:
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Log/LogView.swift`
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Log/MealLogListView.swift`
  - Acceptance: Calendar/status block and meal rows share the same surface language.

- [x] T7. Migrate Meals and Analysis containers.
  - Files:
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Meals/MealsView.swift`
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Analysis/AnalysisView.swift`
  - Acceptance: Inset grouped lists and empty states visually align with glass system.

## Phase 4: Motion + Performance Hardening
- [x] T8. Audit expensive tab-root work and move to lazy/on-demand where possible.
  - Files:
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Dashboard/DashboardView.swift`
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Analysis/AnalysisView.swift`
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Log/LogView.swift`
  - Change examples: avoid unnecessary recomputation in body, avoid eager heavy refresh on tab appearance where not required.
  - Acceptance: Tab changes are smooth on device; no obvious dropped frames under typical usage.

- [x] T9. Add targeted UI/perf checks for tab switching.
  - Files:
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTrackerTests/` (new/updated tests)
  - Acceptance: Basic automated coverage verifies tab identity/accessibility and no regression in key interactions.

## Phase 5: Polish + Documentation
- [x] T10. Update architecture/design docs with glass system rules.
  - Files:
    - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/docs/ARCHITECTURE.md`
    - Optional new: `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/docs/GlassDesignSystem.md`
  - Acceptance: Future contributors know where and how to apply surfaces/motion patterns.

## Execution Order Recommendation

1. T1
2. T2
3. T3
4. T4
5. T5
6. T6
7. T7
8. T8
9. T9
10. T10

## Out-of-Scope for This Workstream

- Any major information architecture changes (tab count/order).
- Domain logic changes unrelated to rendering/interaction.
- Rewriting HealthKit data model/services.

## Validation Checklist (for each completed task)

- [ ] Build succeeds locally. (blocked in this sandbox: no simulator runtimes / signing constraints)
- [ ] Dashboard, Log, Meals, Analysis tabs all load. (blocked by build/run limitation)
- [ ] Tab switching is smooth (manual device test). (pending local device verification)
- [ ] No accidental tab changes while interacting with Log calendar. (pending local device verification)
- [ ] No visual regressions in key cards/lists. (pending local device verification)

## Session Handoff Notes

If continuing in a new session, start here:
1. Open this file.
2. All implementation tasks are complete; focus on visual QA and tuning.
3. Run on-device checks for tab transitions, list/calendar interactions, and glass legibility in light/dark modes.

## Completion Notes (2026-02-15)

- Implemented root tab gesture removal and enum-based tab selection in:
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Views/ContentView.swift`
- Added glass theme tokens and screen backdrop:
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Theme/AppTheme.swift`
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Theme/AppScreenModifier.swift`
- Added reusable glass card primitive:
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Common/UI/GlassSurface.swift`
- Migrated core tab surfaces:
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Dashboard/DashboardView.swift`
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Dashboard/DashboardMealLogSummaryView.swift`
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Log/LogView.swift`
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Log/MealLogListView.swift`
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Meals/MealsView.swift`
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Features/Analysis/AnalysisView.swift`
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/Common/UI/ElectrolyteChecklistView.swift`
- Added tab/nav chrome appearance setup:
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTracker/App/HardPhaseTrackerApp.swift`
- Added tests and docs:
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/HardPhaseTrackerTests/AppThemeGlassTests.swift`
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/docs/ARCHITECTURE.md`
  - `/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/docs/GlassDesignSystem.md`
