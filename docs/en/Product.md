# Product Design

## Purpose

FitLog Local is a local-first personal food and workout logging app. Its product value is not simply "record kcal"; it connects food estimation, structured logging, daily targets, remaining macros, workout burn, diet strategy, review, and export into a durable local workflow.

The app is designed for users who may use external multimodal AI to estimate complex meals, but who need those estimates to become editable, queryable, exportable local records.

## Product Principles

- Local-first: business data stays in SQLite unless the user exports it.
- Deterministic app behavior: core calculations are local Dart logic, not app-internal LLM reasoning.
- User control: the app can show targets, remaining values, and review suggestions, but it does not auto-plan meals or auto-change goals.
- Additive compatibility: database migrations preserve existing local users.
- Diet modes stay separate: `gram_per_kg` and `energy_ratio` are parallel methods and must not be merged.
- Phase is explicit: `diet_goal_phase` is the source of truth for cutting/bulking behavior.

## Current Modules

| Module | Current capability | Main code |
| --- | --- | --- |
| Home | Low-density selected-day entry screen for greeting, primary calorie/macro overview, current diet context, and compact food/workout summaries. | `lib/features/home/home_page.dart`, `DailySummaryService` |
| Food Log | Date-filtered food records with open/edit, copy-to-date, delete, and add entry points. | `lib/features/food/food_log_page.dart`, `FoodRepository` |
| Add Food | Manual entry, external AI JSON paste, prompt copy, and placeholder `Photo AI Analysis`. | `add_food_page.dart`, `paste_ai_result_page.dart`, `manual_food_entry_page.dart` |
| Food Detail | Editable saved food record and item rows. | `food_detail_page.dart` |
| Workout Log | Date-filtered saved workout records grouped by internal `plan_id`. | `workout_log_page.dart`, `WorkoutRepository` |
| Add/Edit Workout Record | Named multi-exercise workout record creation/editing, exercise picker, cardio duration, strength sets, completed-set persistence, notes, and summary calculation. | `add_workout_page.dart` |
| Workout Record Detail | Saved record detail, summary metrics, exercise cards, and edit re-entry. | `workout_plan_page.dart` |
| Workout Session Detail | Single-exercise detail view; saved strength detail is read-only for completion state in the current record flow. | `workout_session_page.dart` |
| Profile | Local identity nickname, body profile, language, diet phase, diet mode, strategy settings, g/kg self-check, export, and clear-local-data actions. | `profile_page.dart`, `ProfileRepository` |
| Export | XLSX and CSV ZIP exports for raw records, daily summary, profile, strategy fields, and review history. | `lib/export/*` |

## Food Workflow

1. The user opens Food Log and selects a date.
2. The user chooses Add Food.
3. For external AI-assisted entry, the user copies FitLog's prompt, uses any external model, and pastes returned JSON into the app.
4. FitLog parses JSON locally with `NutritionCalculator.parseAiFoodJson`.
5. The user previews, corrects, and saves the `FoodRecord` and optional `FoodItem` rows.
6. Manual entry skips JSON parsing and saves a record with `source = manual`.
7. Saved records can be edited, deleted, or copied to a user-selected target date.
8. Home and Food Log refresh through local repositories and app refresh state.

## Workout Workflow

1. The user opens Workout Log and selects a date.
2. The user creates a `Workout Record`, gives it a name, and selects one or more exercises.
3. The exercise library supports body-part filtering, search, multi-select, and visible selection order.
4. Cardio exercises require per-exercise duration and have no set checklist.
5. Strength exercises use set rows with weight, reps, and completed state.
6. While the user is editing, FitLog persists one local workout draft instead of immediately creating or mutating a saved workout record.
7. Leaving the editor through the app back button or system back gesture keeps the draft instead of forcing a save/discard modal.
8. Workout Log shows a compact draft-resume bar above `Add Workout`; tapping the bar resumes editing, and tapping its delete icon discards the draft after confirmation.
9. Save validation completes before any saved-record persistence happens.
10. Strength saves persist completed sets only; unchecked sets are removed and saved sets are renumbered from `1..n`.
11. A multi-exercise record is stored as multiple `workout_sessions` sharing one `plan_id`; every session also stores the same `record_name`.
12. Saved records show duration, total volume, total sets, estimated calories, and exercise cards.
13. Editing a saved record re-enters the same page used for creation and replaces the full `plan_id` group transactionally, while abandoned changes stay only in the draft layer until the user discards or saves them.

## Daily Dashboard Behavior

- The selected date is shared by Home, Food Log, and Workout Log.
- Home is intentionally lower density than the detail pages.
- Home shows a local-time greeting with a local nickname fallback, selected date, current diet context, and compact food/workout summaries, but the first-screen structure changes by calculation mode.
- In `energy_ratio`, kcal target/intake/remaining is primary and Home keeps the calorie-ring hero plus compact macro cards.
- In `energy_ratio`, the first viewport is defined as a two-card kcal-first box: the calorie hero and macro cards live inside one dedicated first-screen container, their internal gap stays controlled, and only a short protective tail separates the strategy card from the macro card.
- In `gram_per_kg`, macro grams are primary and kcal is auxiliary intake information; Home replaces the calorie-ring hero with a dedicated macro dashboard that absorbs kcal intake/workout summaries, expands to fill the opening viewport, and keeps strategy below that first-screen macro area.
- In `gram_per_kg`, the strategy separation also comes from a dedicated first-screen dashboard container, but the macro-first dashboard owns that space directly instead of reusing the calorie-first box structure from `energy_ratio`.
- Detailed BMR, TDEE, calibration, and long record editing flows stay in Food Log, Workout Log, Profile, and detail pages.
- Home also shows `diet_goal_phase`, `diet_calculation_mode`, and `diet_plan_strategy` context.
- `carb_cycling` displays carb day type and carb adjustment context.
- `carb_tapering` displays current taper offset and pending review context when available.

## Diet Setup UX

Profile presents diet setup in this order:

1. Local identity: nickname used only for on-device UI such as the Home greeting.
2. Body profile: age, height, weight, and sex option.
3. Goal phase: `cutting` or `bulking`.
4. Calculation mode: `energy_ratio` or `gram_per_kg`.
5. Optional strategy: `none`, `carb_cycling`, or `carb_tapering`.
6. Phase/mode/strategy-specific controls.

Expected behavior:

- `cutting + gram_per_kg`: show training-frequency tier, self-check settings, cutting g/kg table context, and macro target preview.
- `bulking + gram_per_kg`: show training-frequency tier, self-check settings, bulking g/kg table context, and macro target preview.
- `cutting + energy_ratio`: show activity level, daily deficit, macro ratios, and target preview.
- `bulking + energy_ratio`: show activity level, daily surplus, macro ratios, default 25/50/25 suggestion, and target preview.
- `carb_cycling`: show weekly high/medium/low day selectors, multipliers, and current-week preview.
- `carb_tapering`: show review period, target loss rate, taper step, current carb offset, and local review Apply/Dismiss flow.

## Implemented Boundaries

Implemented:

- local food record CRUD and copy-to-date
- external AI JSON paste and local parsing
- built-in bilingual prompt copy
- local workout record creation, editing, grouping, summary, and deletion
- daily summary calculation and display
- dynamic calorie calibration
- g/kg training-frequency self-check
- cutting/bulking phase split
- `energy_ratio` and `gram_per_kg` diet calculation modes
- local deterministic `carb_cycling` and `carb_tapering`
- XLSX and CSV ZIP export
- language switching
- local data clearing with confirmation

Not implemented:

- backend, cloud sync, accounts, remote database, or import
- app-internal image recognition
- app-internal LLM API calls
- RAG, vector database, embedding storage, semantic memory, tool calling, or Agent loop
- automatic meal planning, AI coach, or automatic goal modification
- medical advice

## Code References

- App bootstrap and providers: `lib/main.dart`, `lib/app.dart`
- Home: `lib/features/home/home_page.dart`
- Food: `lib/features/food/*`
- Workout: `lib/features/workout/*`
- Profile: `lib/features/profile/profile_page.dart`
- Models: `lib/domain/models/*`
- Services: `lib/domain/services/*`
- Database and repositories: `lib/data/db/app_database.dart`, `lib/data/repositories/*`
- Export: `lib/export/*`
- Localization and prompt templates: `lib/core/localization/*`, `lib/core/constants/prompt_templates.dart`
