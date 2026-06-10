# Database Design

## Storage Overview

FitLog Local stores business data locally.

| Storage | Purpose | Remote sync |
| --- | --- | --- |
| SQLite / `sqflite` | Profile, food records, food items, workout sessions, workout sets, workout record drafts, weight logs, calibration state, diet adjustment reviews. | No |
| SharedPreferences | UI language preference, currently `language_code`. | No |
| Local files | XLSX and CSV ZIP exports in the app documents directory. | No |
| In-memory providers | App services, refresh version, selected date, language state. | No |

Database name: `fitlog_local.db`.

Current SQLite schema version: `10`.

Foreign keys are enabled with `PRAGMA foreign_keys = ON`.

## Migration Policy

Migrations are additive and must preserve existing local data.

| Version | Change |
| ---: | --- |
| 1 | Initial profile, food, workout, and set tables. |
| 2 | Added `workout_sessions.plan_id`. |
| 3 | Added profile macro ratio fields: `protein_ratio_percent`, `carbs_ratio_percent`, `fat_ratio_percent`. |
| 4 | Added `user_weight_logs` and `calorie_calibration_state`. |
| 5 | Added `diet_calculation_mode`, `training_frequency_per_week`, macro self-check fields. |
| 6 | Added `user_profile.diet_goal_phase TEXT NOT NULL DEFAULT 'cutting'`. |
| 7 | Added diet strategy profile fields and `diet_adjustment_reviews`. |
| 8 | Added `workout_sessions.record_name`. |
| 9 | Added local-only `user_profile.nickname`. |
| 10 | Added `workout_record_drafts` for one active unsaved workout editor state. |

Compatibility rules:

- Never merge or rewrite old migrations just because current schema changed.
- Prefer additive columns/tables over destructive rebuilds.
- Existing users default to safe compatibility values such as `cutting`, `energy_ratio`, and `none`.
- `daily_energy_goal_type` remains stored for compatibility, but `diet_goal_phase` is the phase source of truth.

## Tables

### `user_profile`

Purpose: singleton user profile, diet settings, strategy settings, and self-check settings. Repository uses `id = 1`.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY | Singleton profile id. |
| `nickname` | TEXT | Local-only UI nickname used by Home greeting; not an account field. |
| `age` | INTEGER NOT NULL | BMR and under-18 protection. |
| `height_cm` | REAL NOT NULL | BMR. |
| `weight_kg` | REAL NOT NULL | BMR, g/kg macros, workout calories. |
| `sex_for_formula` | TEXT NOT NULL | `male`, `female`, `prefer_not_to_say`. |
| `activity_level` | TEXT NOT NULL | Non-exercise activity tier for `energy_ratio`. |
| `daily_energy_goal_type` | TEXT NOT NULL | Compatibility field: `maintenance`, `deficit`, `surplus`. |
| `daily_energy_goal_kcal` | REAL NOT NULL | Deficit or surplus amount depending on `diet_goal_phase`. |
| `protein_ratio_percent` | REAL NOT NULL | `energy_ratio` macro percentage. |
| `carbs_ratio_percent` | REAL NOT NULL | `energy_ratio` macro percentage. |
| `fat_ratio_percent` | REAL NOT NULL | `energy_ratio` macro percentage. |
| `diet_goal_phase` | TEXT NOT NULL DEFAULT `cutting` | `cutting` or `bulking`; phase source of truth. |
| `diet_calculation_mode` | TEXT NOT NULL DEFAULT `energy_ratio` | `energy_ratio` or `gram_per_kg`. |
| `diet_plan_strategy` | TEXT NOT NULL DEFAULT `none` | `none`, `carb_cycling`, `carb_tapering`. |
| `carb_cycle_pattern_json` | TEXT | Weekday to high/medium/low mapping. |
| `carb_cycle_high_multiplier` | REAL NOT NULL DEFAULT 1.20 | High day multiplier. |
| `carb_cycle_medium_multiplier` | REAL NOT NULL DEFAULT 1.00 | Medium day multiplier. |
| `carb_cycle_low_multiplier` | REAL NOT NULL DEFAULT 0.80 | Low day multiplier. |
| `carb_taper_review_period_days` | INTEGER NOT NULL DEFAULT 14 | 14/21/28/7. |
| `carb_taper_target_loss_pct_per_week` | REAL NOT NULL DEFAULT 0.50 | Clamped by app constants. |
| `carb_taper_step_g` | REAL NOT NULL DEFAULT 10.0 | 5/10/15/20 style taper step. |
| `carb_taper_current_delta_g` | REAL NOT NULL DEFAULT 0.0 | Cumulative carb offset. |
| `last_carb_taper_review_at` | TEXT | Last taper review timestamp/date. |
| `training_frequency_per_week` | INTEGER NOT NULL DEFAULT 3 | g/kg lookup tier 2/3/4/5. |
| `macro_self_check_period_days` | INTEGER NOT NULL DEFAULT 14 | 7/14/21/28. |
| `macro_self_check_enabled` | INTEGER NOT NULL DEFAULT 1 | Boolean stored as 0/1. |
| `last_macro_self_check_at` | TEXT | Self-check cooldown timestamp/date. |
| `created_at` | TEXT NOT NULL | ISO datetime. |
| `updated_at` | TEXT NOT NULL | ISO datetime. |

### `food_records`

Purpose: meal-level food records.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | Record id. |
| `date` | TEXT NOT NULL | `yyyy-MM-dd`. |
| `meal_name` | TEXT NOT NULL | Meal label. |
| `total_weight_g` | REAL NOT NULL | Total estimated weight. |
| `calories_kcal` | REAL NOT NULL | Meal kcal. |
| `protein_g` | REAL NOT NULL | Protein grams. |
| `carbs_g` | REAL NOT NULL | Carbohydrate grams. |
| `fat_g` | REAL NOT NULL | Fat grams. |
| `confidence` | REAL | External estimate confidence; often null for manual records. |
| `estimation_notes` | TEXT | Notes from external estimate or user. |
| `source` | TEXT NOT NULL | `ai_paste` or `manual`. |
| `created_at` | TEXT NOT NULL | ISO datetime. |
| `updated_at` | TEXT NOT NULL | ISO datetime. |

### `food_items`

Purpose: item rows inside a meal. Deleted with parent food record.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | Item id. |
| `food_record_id` | INTEGER NOT NULL | FK to `food_records.id`, ON DELETE CASCADE. |
| `name` | TEXT NOT NULL | Food item name. |
| `estimated_weight_g` | REAL NOT NULL | Estimated item weight. |
| `calories_kcal` | REAL NOT NULL | Item kcal. |
| `protein_g` | REAL NOT NULL | Protein grams. |
| `carbs_g` | REAL NOT NULL | Carbohydrate grams. |
| `fat_g` | REAL NOT NULL | Fat grams. |
| `notes` | TEXT | Optional item notes. |

### `workout_sessions`

Purpose: one saved exercise session. A multi-exercise workout record is represented by multiple sessions sharing `plan_id`.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | Session id. |
| `plan_id` | TEXT | Shared id for a workout record group. |
| `record_name` | TEXT | User-facing workout record name, duplicated across the group. |
| `date` | TEXT NOT NULL | `yyyy-MM-dd`. |
| `body_part` | TEXT NOT NULL | Body part/category. |
| `exercise_name` | TEXT NOT NULL | Exercise display name. |
| `exercise_type` | TEXT NOT NULL | `strength` or `cardio`. |
| `duration_minutes` | INTEGER NOT NULL | Per-exercise duration. |
| `intensity` | TEXT NOT NULL | Currently saved as an intensity label such as `medium`. |
| `estimated_calories` | REAL NOT NULL | Saved net exercise kcal estimate. |
| `notes` | TEXT | Optional notes. |
| `created_at` | TEXT NOT NULL | Timeline/start-time ordering. |
| `updated_at` | TEXT NOT NULL | ISO datetime. |

Workout record behavior:

- `plan_id` remains the grouping key.
- No separate parent workout-record table exists.
- Editing a saved record replaces the full `plan_id` group transactionally.
- Summary duration, calories, volume, and set count are derived from persisted sessions/sets.

### `workout_sets`

Purpose: strength set rows. Deleted with parent workout session.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | Set id. |
| `workout_session_id` | INTEGER NOT NULL | FK to `workout_sessions.id`, ON DELETE CASCADE. |
| `set_number` | INTEGER NOT NULL | Saved set order. |
| `weight_kg` | REAL NOT NULL | External load; for bodyweight movements, `0` means pure bodyweight. |
| `reps` | INTEGER NOT NULL | Repetition count. |
| `is_completed` | INTEGER NOT NULL | Boolean stored as 0/1. |
| `completed_at` | TEXT | ISO datetime when completed. |

Current save behavior:

- Completed strength sets are persisted.
- Unchecked sets are discarded before insert/update.
- Remaining sets are renumbered from `1..n`.
- `is_completed` remains stored for compatibility, but saved strength sets are expected to be completed sets.

### `workout_record_drafts`

Purpose: one active unsaved workout editor state, stored separately from saved workout history.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | TEXT PRIMARY KEY | Fixed active draft id. |
| `kind` | TEXT NOT NULL | `new_record` or `edit_record`. |
| `source_plan_id` | TEXT | Saved-record `plan_id` when the draft started from an existing grouped workout record. |
| `source_session_id` | INTEGER | Saved single-session id when the draft started from an older non-grouped workout record. |
| `date` | TEXT NOT NULL | Draft date shown in the editor. |
| `record_name` | TEXT NOT NULL | Draft workout-record name. |
| `notes` | TEXT NOT NULL | Draft notes. |
| `payload_json` | TEXT NOT NULL | Serialized exercise order, duration values, set rows, default-hint state, and completed flags. |
| `created_at` | TEXT NOT NULL | Draft creation timestamp. |
| `updated_at` | TEXT NOT NULL | Last draft autosave timestamp. |

Draft behavior:

- The draft table is not part of workout history and does not appear in saved workout lists.
- The draft table does not feed Home workout totals or export coverage.
- Explicit save validates current editor state first, then writes `workout_sessions` and `workout_sets`, then deletes the draft row.

### `user_weight_logs`

Purpose: daily bodyweight history for calibration and review.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | Weight log id. |
| `date` | TEXT NOT NULL UNIQUE | One entry per day. |
| `weight_kg` | REAL NOT NULL | Bodyweight. |
| `source` | TEXT NOT NULL | Currently written from profile save. |
| `created_at` | TEXT NOT NULL | ISO datetime. |
| `updated_at` | TEXT NOT NULL | ISO datetime. |

### `calorie_calibration_state`

Purpose: singleton dynamic calorie calibration state.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY CHECK (`id = 1`) | Singleton row. |
| `lifestyle_factor` | REAL NOT NULL | Calibrated non-exercise lifestyle factor. |
| `confidence` | REAL NOT NULL | 0 to 1 confidence. |
| `window_days` | INTEGER NOT NULL | 7/14/21/28. |
| `valid_days` | INTEGER NOT NULL | Food-log valid day count. |
| `last_calibrated_date` | TEXT | `yyyy-MM-dd`. |
| `created_at` | TEXT NOT NULL | ISO datetime. |
| `updated_at` | TEXT NOT NULL | ISO datetime. |

### `diet_adjustment_reviews`

Purpose: local carb taper review history and user decision record.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | Review id. |
| `review_date` | TEXT NOT NULL | Review date. |
| `window_days` | INTEGER NOT NULL | Review window. |
| `diet_goal_phase` | TEXT NOT NULL | Phase at review time. |
| `diet_calculation_mode` | TEXT NOT NULL | Mode at review time. |
| `diet_plan_strategy` | TEXT NOT NULL | Strategy at review time. |
| `start_avg_weight_kg` | REAL | Start average weight. |
| `end_avg_weight_kg` | REAL | End average weight. |
| `weight_change_kg` | REAL | End minus start. |
| `loss_rate_pct_per_week` | REAL | Rolling trend. |
| `target_loss_pct_per_week` | REAL | User target. |
| `food_log_coverage` | REAL | Coverage ratio. |
| `active_training_days` | INTEGER | Training stability input. |
| `suggested_action` | TEXT NOT NULL | `no_data`, `keep`, `decrease_carbs`, `pause_taper`, `increase_carbs_small`, or `blocked_by_safety_floor`. |
| `suggested_carb_delta_g` | REAL NOT NULL DEFAULT 0 | Suggested change. |
| `applied_delta_after_g` | REAL | Resulting cumulative delta if accepted. |
| `confidence` | REAL NOT NULL DEFAULT 0 | Review confidence. |
| `reason_codes_json` | TEXT | Internal reason codes. |
| `user_decision` | TEXT | `pending`, `accepted`, `dismissed`, or `expired`. |
| `created_at` | TEXT NOT NULL | ISO datetime. |
| `updated_at` | TEXT NOT NULL | ISO datetime. |

## Runtime Aggregates

`DailySummary` is not a table. It is assembled at runtime from profile data, food records, workout records, calibration state, self-check results, and strategy results.

Derived data includes:

- intake kcal/protein/carbs/fat
- exercise calories
- BMR and no-exercise TDEE reference
- target intake and remaining kcal for `energy_ratio`
- macro targets and remaining macros
- base and final strategy targets
- strategy reason codes and confidence
- calibration metadata
- self-check metadata
- selected-day food and workout record lists

## Data Flows

Profile:

```text
ProfilePage
-> UserProfile
-> ProfileRepository.saveProfile
-> user_profile + user_weight_logs
-> DailySummaryService
-> Home/Profile display
```

Food:

```text
AddFoodPage / PasteAiResultPage / ManualFoodEntryPage
-> FoodRecord + FoodItem
-> FoodRepository
-> food_records + food_items
-> DailySummaryService
-> Home/Food display
```

Workout:

```text
AddWorkoutPage
-> workout draft snapshot
-> workout_record_drafts
-> explicit save validation
-> WorkoutCalorieCalculator
-> WorkoutSession + WorkoutSet
-> WorkoutRepository
-> workout_sessions + workout_sets
-> DailySummaryService
-> Home/Workout display
```

Export:

```text
ProfilePage export action
-> XlsxExportService or CsvExportService
-> repositories + DailySummaryService
-> local .xlsx or .zip file
```

## Export Coverage

Exports include food records, food items, workout records, workout sets, daily summary, user profile, and diet adjustment review history. Strategy fields, base/final target fields, calibration metadata, g/kg self-check fields, local-only `nickname`, and `record_name` are included where relevant.

## Not Implemented

- cloud sync
- accounts
- remote database
- data import
- vector database
- embedding storage
- AI conversation history
- Agent action logs
- semantic memory

## Code References

- Database: `lib/data/db/app_database.dart`
- Repositories: `lib/data/repositories/food_repository.dart`, `workout_repository.dart`, `profile_repository.dart`
- Models: `lib/domain/models/*`
- Services: `lib/domain/services/*`
- Export: `lib/export/xlsx_export_service.dart`, `lib/export/csv_export_service.dart`
- App state: `lib/app.dart`, `lib/core/localization/language_controller.dart`
