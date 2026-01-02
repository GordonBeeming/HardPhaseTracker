# Spec: HardPhase Tracker

## 1. Project Overview

A specialized tracking application for iPhone and iPad designed to support ultra-extended fasting protocols (e.g., Gordon's 4:3 routine). The app minimizes "food focus" through a template-based "Named Meals" system while providing automated health tracking via Apple Health.

## 2. Core Principles

* **Zero Friction:** One-tap logging for recurring meals and Sodii electrolytes.
* **Data Integrity:** Auto-sync weight and sleep data from Apple Health (Source: Garmin Scale).
* **Adaptive Theming:** Supports system Light and Dark modes using Gordon's palette.
* **Visual Identity:** Branding based on the **Vitality Drop** icon—symbolizing hydration, electrolyte balance, and the ultimate goal of returning to swimming.

## 3. Theming & Color Palette

The app must automatically switch based on the device's active `colorScheme`.

### Light Mode

* **Background:** #F8F9FA
* **Text:** #1A1A1A
* **Primary (Actions/Buttons):** #0063B2 (Dark Blue)
* **Accent (Status/Graphs):** #46CBFF (Light Blue)
* **UI Accents (Dividers):** #E9ECEF

### Dark Mode

* **Background:** #1A1A1A (Charcoal)
* **Text:** #E0E0E0
* **Primary (Actions/Buttons):** #46CBFF (Light Blue)
* **Accent (Status/Graphs):** #0063B2 (Dark Blue)
* **UI Accents (Dividers):** #2C2C2C

## 4. Key Features

### A. HealthKit Integration

* **Weight (Read):** Fetch `bodyMass` and `bodyFatPercentage`.
* **Sleep (Read):** Fetch `sleepAnalysis` to monitor recovery during deep fasting phases.

### B. Fasting Engine

* **Timer:** Live counter (Days/Hours/Minutes) since the last logged meal.
* **Phase Colors:** Visual shifts in the timer display as the fast deepens (e.g., 24h, 48h, 72h+).

### C. The "Named Meals" System

Users can create, edit, and delete their own meal templates.

* **Template Fields:** * Meal Name (e.g., "Thursday Lunch").
* Individual Components with weight in **Grams** (e.g., 300g Sweet Potato).
* Total Protein, Carbs, and Fats for the template.


* **Gordon's Starter Templates:**
* **Thursday Lunch:** 3 Eggs, 300g Sweet Potato, 30g Cheese, 175g Cucumber, 125g Tomato, 30g Spinach.
* **Sunday Dinner:** 5 Eggs, 450g White Potato, 50g Cheese, 350g Cucumber, 250g Tomato, 60g Spinach.



### D. Electrolyte Log (Sodii Tracker)

* Dedicated button to log a serving of Sodii.
* Tracks daily intake vs. the target (2-4 servings).

## 5. UI Structure

### Dashboard

* **Primary View:** "Vitality Drop" branded Fasting Timer.
* **Quick Actions:** Large "Log Meal" (opens template drawer) and "Log Sodii" buttons.
* **Graph:** Last 7-day weight trend fetched from Apple Health.

### Meal Manager

* List view of all "Named Meals."
* "Add New Meal" interface with fields for name and nutritional components.

### Analysis View

* Correlation of sleep quality and fasting duration.
* Weekly protein goal tracking based on Gordon's requirement for muscle preservation.

## 6. Technical Architecture

* **Framework:** SwiftUI + SwiftData (for local persistence of meal templates and entries).
* **API Support:** Logic ready for future Gemini/Apple Intelligence integration to analyze trends.
