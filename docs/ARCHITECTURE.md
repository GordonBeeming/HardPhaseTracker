# VSA Architecture

HardPhaseTracker follows **Vertical Slice Architecture (VSA)** principles, organizing code by feature rather than by technical layer.

## Directory Structure

```
HardPhaseTracker/
├── Features/           # Tab-based features (vertical slices)
│   ├── Dashboard/     # Dashboard tab
│   ├── Log/           # Log tab
│   ├── Meals/         # Meals tab
│   ├── Analysis/      # Analysis tab
│   ├── Schedule/      # Schedule management (used by Dashboard)
│   └── HealthKit/     # HealthKit integration (infrastructure)
├── Common/            # Shared across features
│   ├── Domain/        # Shared data models
│   ├── Services/      # Shared business logic
│   └── UI/            # Shared UI components
├── App/               # App lifecycle
├── Theme/             # Visual styling
├── Shared/            # Framework extensions (SwiftData, etc.)
└── Views/             # Root views (ContentView)
```

## Features/ (Tab-based features)

Each feature folder corresponds to a tab in the app or a cohesive functional area:

### Dashboard (Dashboard tab)
- `DashboardView.swift` - Main dashboard view
- `DashboardMealLogSummaryView.swift` - Recent meals card
- `LastMealCompactView.swift` - Last meal indicator
- `DashboardOnboardingPolicy.swift` - Onboarding logic
- `LogMealVisibilityPolicy.swift` - Log meal button visibility

### Log (Log tab)
- `LogView.swift` - Main log view
- `MealLogListView.swift` - List of meal logs
- `MealCalendarView.swift` - Calendar picker

### Meals (Meals tab)
- `MealsView.swift` - Main meals view
- `MealLogEntryDetailView.swift` - View meal log details
- `MealLogEntryEditorView.swift` - Edit meal log
- `MealTemplateDetailView.swift` - View meal template
- `MealTemplateEditorView.swift` - Edit meal template
- `MealTimeDisplaySettings.swift` - Time display settings
- `SeedMealTemplatesService.swift` - Seed data
- `StarterMeals.swift` - Starter meal templates

### Analysis (Analysis tab)
- `AnalysisView.swift` - Main analysis view
- `SleepFastingCorrelationService.swift` - Sleep/fasting correlation
- `WeeklyProteinAggregationService.swift` - Protein tracking

### Schedule (Not a tab, but feature-specific)
- `ScheduleEditorView.swift` - Edit eating window schedule
- `EatingWindowNavigator.swift` - Schedule navigation
- `ScheduleTemplates.swift` - Schedule templates
- `SeedSchedulesService.swift` - Seed schedules

### HealthKit (Shared infrastructure)
- `HealthKitService.swift` - HealthKit integration
- `HealthKitViewModel.swift` - HealthKit view model
- `HealthKitModels.swift` - HealthKit data models
- `HealthKitQuerySupport.swift` - Query helpers

## Common/ (Shared across features)

Components that are genuinely shared across multiple features live here:

### Common/Domain/ (Shared data models)
Core domain models used by multiple features:
- `MealLogEntry.swift` - Meal log entry model
- `MealTemplate.swift` - Meal template model
- `MealComponent.swift` - Meal component model
- `AppSettings.swift` - App-wide settings
- `EatingWindowSchedule.swift` - Eating window schedule model
- `ElectrolyteIntakeEntry.swift` - Electrolyte intake model
- `ElectrolyteTargetSetting.swift` - Electrolyte target model
- `FastingPhase.swift` - Fasting phase model

### Common/Services/ (Shared business logic)
Business logic and utilities used across features:
- `MealLogService.swift` - Meal logging operations
- `DateFormatting.swift` - Date/time formatting
- `FoodUnits.swift` - Food unit conversions
- `FastingEngine.swift` - Fasting calculations
- `EatingWindowEvaluator.swift` - Eating window evaluation
- `ElectrolyteTargetService.swift` - Electrolyte target management

### Common/UI/ (Shared UI components)
Reusable UI components used by multiple tabs:
- `MealQuickLogView.swift` - Quick meal logging (used in Dashboard, Log)
- `SettingsView.swift` - App settings (used in all tabs)
- `ElectrolyteChecklistView.swift` - Electrolyte checklist (used in Dashboard)
- `SchedulePickerView.swift` - Schedule picker (used in Dashboard)
- `EatingWindowStatusView.swift` - Eating window status (used in Dashboard)
- `FastingTimerView.swift` - Fasting timer component

## Key Principles

1. **Feature Independence**: Each tab feature is self-contained and doesn't directly depend on other features
2. **Shared via Common**: Components used by 2+ features live in `Common/`
3. **No Cross-Feature Dependencies**: Features only depend on `Common/`, never on each other
4. **Domain in Common**: Core data models are shared via `Common/Domain/`
5. **Services in Common**: Shared business logic goes in `Common/Services/`
6. **UI in Common**: Reusable UI components go in `Common/UI/`
7. **Flat Structure**: Within each feature, files are flat (no unnecessary subfolders)

## When to Add to Common/

A component should be moved to `Common/` when:
- It's used by 2 or more features
- It represents core domain logic
- It's a genuinely reusable UI component

If it's only used by one feature, keep it in that feature's folder.

## Benefits of This Architecture

1. **Easier Navigation**: Find all code related to a tab in one place
2. **Clearer Dependencies**: Shared dependencies are explicit in `Common/`
3. **Easier Testing**: Each feature can be tested independently
4. **Scalability**: New features can be added without impacting existing ones
5. **Team Collaboration**: Different team members can work on different features with minimal conflicts
