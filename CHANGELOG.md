# FitLog Local - Agent Memory

## 2026-06-06 Workout Record Flow Update

### Added
- Added `record_name` to saved workout sessions so one multi-exercise workout record can carry a user-defined name across the whole saved group.
- Added create-time naming for workout records.
- Added saved workout record summary metrics: total duration, total volume, total sets, and estimated calories.
- Added full-record edit re-entry through the same page used for workout creation.

### Changed
- User-facing workout copy now uses `Workout Record` instead of `Workout Plan` for saved entries.
- Saved workout records still use shared `plan_id` internally, but now behave as editable named records in the UI.
- Saving a strength workout record now persists completed sets only.
- Unchecked strength sets are removed before save and remaining saved sets are renumbered from `1..n`.
- Create/edit workout rows now show a row-level highlight after a set is marked completed.
- Saved single-exercise detail pages are now read-only for completion state and focus on clearer weight/reps display.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.
- `flutter build apk --debug`: success.

## 2026-06-06 Diet Strategy UI Follow-up

### Fixed
- Home dashboard hero now shows goal phase and diet plan strategy on their own line above the macro title to avoid overflow on narrow mobile screens.
- Home dashboard hero now keeps the original single-line title layout when `diet_plan_strategy = none`, showing only the current phase on the right and hiding the `None` label.
- Carb cycling weekly preview now breaks the carb day label and the `P / C / F / kcal` values into two lines for better readability.
- Carb taper review cards no longer expose raw internal reason codes like `review_cooldown_active`; visible review reasons are now shown as user-facing text only.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.
- `flutter build apk --debug`: success.

## 2026-06-05 Cutting Diet Strategy Layer

### Added
- Added `diet_plan_strategy` with `none`, `carb_cycling`, and `carb_tapering`.
- Added cutting-only local deterministic carb cycling and carb tapering services.
- Added schema v7 fields on `user_profile` and the new `diet_adjustment_reviews` table.
- Added export coverage for strategy fields, base/final target columns, and diet adjustment review history.
- Added tests for carb cycling, carb taper review logic, daily summary integration, and migration compatibility.

### Changed
- `DailySummaryService` now computes base targets first and then applies a separate strategy layer to produce final displayed targets.
- Home now shows strategy badge and strategy-specific target context.
- Profile now exposes cutting-only strategy settings, weekly carb cycling preview, and carb taper review/apply/dismiss flow.
- Under-18 protection now blocks cutting carb strategies in addition to deficit handling.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

## 2026-06-05 Round 2 Simplification Cleanup

### Changed
- Extracted shared food-form support helpers for repeated date rows, save buttons, and editable food item draft mapping without changing food save flows.
- Unified CSV and XLSX export row construction through a single `ExportTableBuilder` so both export formats keep the same columns from one source of truth.
- Collapsed repeated food/workout repository row-to-model assembly into private helpers while preserving query order and child-record loading behavior.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.
- `flutter build apk --debug`: success.

## 2026-06-05 Workout Plan Save Atomicity Fix

### Fixed
- Workout plan save now finishes all validation before any workout session is inserted.
- If any exercise is missing duration or required set data, the app only shows the validation prompt and does not save a partial plan.
- Full-plan saves now use one repository transaction so repeated taps on an invalid first-time exercise no longer leave behind duplicate incomplete plans.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.
- `flutter build apk --debug`: success.

## 2026-06-04 Round 1 Simplification Cleanup

### Changed
- Extracted a shared `SelectedDateHeader` widget for Home, Food Log, and Workout Log date navigation UI.
- Extracted reusable Profile form field widgets for repeated numeric and option inputs without changing save flow or field behavior.
- Centralized allowed-option resolution helpers in `AppConstants` and reused them from profile/model/service code paths.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

## 2026-06-04 Diet Goal Phase Split

### Added
- Added `diet_goal_phase` with `cutting` and `bulking` as the source of truth above diet calculation mode.
- Upgraded SQLite to v6 with additive `user_profile.diet_goal_phase TEXT NOT NULL DEFAULT 'cutting'`.
- Added the 2 x 2 diet matrix: `cutting/bulking` x `gram_per_kg/energy_ratio`.
- Added a separate bulking g/kg table; `prefer_not_to_say` still averages same-tier male/female coefficients.
- Added `diet_goal_phase` to User Profile and Daily Summary CSV/XLSX export.

### Changed
- `energy_ratio` now interprets `daily_energy_goal_kcal` by phase: cutting = deficit, bulking = surplus.
- Profile phase now drives deficit/surplus semantics instead of letting goal types mix freely.
- Home and Profile show the current goal phase.
- `gram_per_kg` remains independent from BMR, activity level, daily energy goal, logged exercise calories, and macro ratios.
- `macro_energy_equivalent_kcal` remains auxiliary in g/kg mode, not a kcal target counter.

### Tests
- Added coverage for cutting/bulking g/kg tables, `prefer_not_to_say` averaging, and phase-based energy target direction.
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

## 1) Product Goal
- FitLog Local is a Flutter fitness logging app with local-first storage (no backend).
- Core value:
  - Food logging with AI-assisted nutrition estimates.
  - Workout logging with set-level details.
  - Daily dashboard for intake, burn, targets, and remaining budget.
  - Data export support (XLSX/CSV).

## 2) Project Structure
- `lib/app.dart`: app bootstrap, providers, bottom navigation shell.
- `lib/data/db/app_database.dart`: SQLite schema and migrations.
- `lib/data/repositories/*`: food/workout/profile data access.
- `lib/domain/models/*`: domain models (`FoodRecord`, `WorkoutSession`, etc.).
- `lib/domain/services/*`: business logic calculators and summaries.
- `lib/features/*`: feature pages (home/food/workout/profile).

## 3) Important Domain Rules
- For bodyweight movements, set `weight` means extra load only.
  - `0` means pure bodyweight.
- `created_at` is used for timeline ordering and workout start time.
- `date` is used for day-based filtering/grouping.

## 4) Existing Commit History (Before This Round)
1. `c365d77` - feat: initial commit for FitLog Local MVP
2. `fc8a893` - feat: inherit workout set defaults from last session, refine bodyweight logic, add macro ratio targets
3. `0d3807f` - fix: prevent save freeze after changing record date/time by preserving created_at and always resetting saving state
4. `35c6d1b` - feat: add shared date navigation, fix bottom-nav overlap, and enable workout record editing (date/time/duration)
5. `9a11901` - feat(home): redesign dashboard hero to show key intake/macro summary first, expand to detailed metrics on tap

## 5) This Round Changes (2026-05-15)

### A. Fix workout plan edit crash risk
- File: `lib/features/workout/workout_plan_page.dart`
- Changed save flow to avoid async `BuildContext` misuse and route dependency timing issues.
- Reordered provider reads so repository handles are captured before async gaps.
- Captured sheet navigator before `await` and added mounted checks for both state and sheet context.
- Result: avoids red-screen assertion risk when editing date/time/duration after creation.

### B. Strength vs cardio calorie logic split
- File: `lib/domain/services/workout_calorie_calculator.dart`
- Cardio remains duration-based using MET logic.
- Strength no longer scales calories by duration.
- Strength now uses set volume style estimation based on effective load and reps.
- Bodyweight movements apply body-mass share plus extra external load.

### C. Keep logic consistent in workout creation/edit
- Files:
  - `lib/features/workout/add_workout_page.dart`
  - `lib/features/workout/workout_plan_page.dart`
- Creation and later plan edits now use the same calorie logic:
  - Cardio: duration matters.
  - Strength: set/reps/load matter; duration does not directly scale calories.

### D. Add walking
- Files:
  - `lib/core/constants/app_constants.dart`
  - `lib/core/localization/app_strings.dart`
- Added `Walking` cardio exercise and display name mapping.

## 6) Validation Status
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

## 7) Future Notes
- If we want higher scientific precision later:
  - Add movement-specific displacement/ROM and mechanical work approximations.
  - Add user-level coefficients by sex/training status.
  - Add optional effort inputs (RPE/RIR) for calibration.

## 8) Follow-up Changes (2026-05-15, evening)

### A. Add-workout flow redesigned for multi-cardio duration inputs
- File: `lib/features/workout/add_workout_page.dart`
- Removed always-open inline exercise library from main add page.
- Added a dedicated exercise picker page (multi-select) opened by an "Add Exercises" action.
- Main add page now stays compact and focuses on selected exercises + parameter entry.
- Each selected exercise has its own duration input.
  - This is especially important for cardio because cardio calories depend on per-exercise duration.
  - Mixed plans (e.g. running + walking, running + strength) are now calculated with separate durations.

### B. Strength calorie model switched to net-active logic
- File: `lib/domain/services/workout_calorie_calculator.dart`
- Updated strength estimation to align with "net additional calories" intent:
  - `net_strength_kcal = active_lifting_kcal + recovery_extra_kcal`
  - `active_lifting_kcal` is driven by training volume:
    - `total_volume_kg * strength_coefficient * body_factor * intensity_factor`
  - `body_factor = clamp(sqrt(body_weight / 80), 0.85, 1.15)`
  - `intensity_factor` is inferred conservatively from reps/load profile and kept in a bounded range.
  - `recovery_extra_kcal` uses a small exercise-type recovery rate multiplier.
  - Session duration is NOT used as linear calorie accumulation for strength.
  - Session duration is used only as a small capped rest modifier:
    - `clamp(1 + log(1 + rest_minutes) * 0.03, 1.0, 1.10)`
- Strength type profiles are explicitly split:
  - upper-body compound / lower-body compound / isolation / full-body power-high-density
  - each profile has its own coefficient and recovery rate.
- Set selection rule:
  - if there are completed sets, estimate from completed sets first
  - otherwise estimate from all valid entered sets (so new plans without completion checks still get estimates)
- Cardio remains duration-based MET estimation per selected cardio exercise.

### C. Strength duration notice added in UI
- File: `lib/features/workout/add_workout_page.dart`
- Added an explicit note near strength duration input:
  - Strength calories are net exercise calories.
  - Inter-set rest baseline is not linearly added.

### D. Workout-plan edit crash hardening
- File: `lib/features/workout/workout_plan_page.dart`
- Replaced bottom-sheet editor with a dedicated full-page editor for date/time/total duration.
- Save is now performed after returning from the editor page, reducing route/context disposal conflicts.
- This change is intended to resolve persistent red-screen assertion (`_dependents.isEmpty`) when editing duration/time after plan creation.

### E. Set default-input UX improved (no forced deletion)
- File: `lib/features/workout/add_workout_page.dart`
- Historical set values are now shown as gray hints instead of prefilled text.
- If user does not type, save uses historical defaults.
- If user types, they can directly enter new values without deleting old text first.
- Added `selectAllOnFocus` for faster edits when a field has typed text.

### F. Localization support for new workout flow copy
- File: `lib/core/localization/app_strings.dart`
- Added strings for:
  - collapsed exercise picker flow
  - add-selected-exercises button text
  - per-exercise duration guidance
  - strength net-calorie notice
  - per-exercise duration validation message

## 9) Dynamic Calorie Target Calibration (2026-05-16)

### A. Core target architecture changed to avoid double counting
- Files:
  - `lib/domain/services/daily_summary_service.dart`
  - `lib/features/home/home_page.dart`
  - `lib/features/profile/profile_page.dart`
- Daily target logic is now:
  - `baseline_no_exercise_tdee = BMR * lifestyle_factor_non_exercise`
  - `no_exercise_target_intake = baseline_no_exercise_tdee - daily_energy_goal_kcal`
  - `final_food_target = no_exercise_target_intake + logged_net_exercise_kcal`
- This removes the previous risk of counting planned/implicit exercise twice.

### B. Added persistent calibration data
- Files:
  - `lib/data/db/app_database.dart`
  - `lib/data/repositories/profile_repository.dart`
  - `lib/domain/models/weight_log.dart`
  - `lib/domain/models/calorie_calibration_state.dart`
- New DB tables:
  - `user_weight_logs` (daily weight history)
  - `calorie_calibration_state` (current calibrated lifestyle factor and confidence metadata)
- Saving profile now also upserts today's weight log.

### C. Implemented rolling calibration (7–28 day windows)
- File: `lib/domain/services/daily_summary_service.dart`
- Calibration flow:
  - use candidate windows: 28 / 21 / 14 / 7 days
  - require sufficient food log coverage and weight logs
  - use 7-day start/end rolling average weight
  - estimate observed non-exercise TDEE:
    - `observed_total_tdee = avg_intake - weight_change_kg * 7700 / days`
    - `observed_no_exercise_tdee = observed_total_tdee - avg_logged_net_exercise`
    - `observed_lifestyle_factor = observed_no_exercise_tdee / avg_bmr`
  - update factor gradually with EWMA:
    - `new = old*0.8 + observed*0.2`
  - cap per-update step to `±0.03`
  - clamp factor to `1.10–1.70`
  - calibrate at most once every 7 days

### D. Exercise net-calorie consistency updates
- File: `lib/domain/services/workout_calorie_calculator.dart`
- Cardio now uses net MET:
  - `(MET - 1) * 3.5 * weight / 200 * minutes`
- Strength remains volume-driven and now explicitly splits:
  - `active_lifting_kcal`
  - `post_training_recovery_kcal`
  - `muscle_repair_adaptation_kcal`
- Strength duration is used only for a small capped rest-density modifier, not linear calorie accumulation.

### E. Export summary fields extended
- Files:
  - `lib/export/xlsx_export_service.dart`
  - `lib/export/csv_export_service.dart`
- Added exported metrics:
  - lifestyle factor used
  - no-exercise target intake
  - calibration confidence / window / valid-day count

## 10) Follow-up Fixes (2026-05-16, late)

### A. Decimal default-value rendering fix in Add Workout
- File: `lib/features/workout/add_workout_page.dart`
- Issue:
  - Some history defaults with decimal values (e.g. `72.5`) looked blank/truncated in set weight inputs.
- Fix:
  - Switched set defaults from hint-only display to prefilled controller values.
  - Kept “default gray value” UX by rendering unchanged defaults in muted text color.
  - Kept `selectAllOnFocus` so users can tap once and directly overwrite.
- Result:
  - Decimal historical weights now render reliably.
  - Editing no longer requires deleting old numbers manually.

### B. Strength duration now causes visible but capped differences
- File: `lib/domain/services/workout_calorie_calculator.dart`
- Updated strength recovery modifier:
  - duration is still NOT linear calorie accumulation.
  - duration now influences a capped recovery-density modifier so different durations can produce different kcal for same sets.
  - current implementation:
    - `density = completed_sets / session_minutes`
    - `density_ratio = density / baseline_density`
    - `recovery_density_modifier = clamp(1 + (density_ratio - 1) * 0.28, 0.85, 1.35)`
  - modifier applies only to `post_training_recovery_kcal`.

### C. Muscle-repair component remains enabled
- File: `lib/domain/services/workout_calorie_calculator.dart`
- Strength net kcal still includes:
  - `active_lifting_kcal`
  - `post_training_recovery_kcal`
  - `muscle_repair_adaptation_kcal`

### D. Documentation sync
- Files:
  - `README.md`
  - `Agent.md`
- Clarified that:
  - Cardio uses net MET (`MET - 1`) to remove resting baseline during exercise.
  - Strength is volume-driven and only uses duration as a capped recovery-density modifier.
  - Core principle is net additional exercise calories to avoid baseline double counting.

## 11) Diet Algorithm Dual-Mode Update (2026-05-17)

### A. New profile fields and compatibility
- Files:
  - `lib/domain/models/user_profile.dart`
  - `lib/data/db/app_database.dart`
  - `lib/data/repositories/profile_repository.dart`
  - `lib/core/constants/app_constants.dart`
- Added fields in `user_profile`:
  - `diet_calculation_mode` (`energy_ratio` | `gram_per_kg`, default `energy_ratio`)
  - `training_frequency_per_week` (2/3/4/5, default 3)
  - `macro_self_check_period_days` (7/14/21/28, default 14)
  - `macro_self_check_enabled` (bool, default true)
  - `last_macro_self_check_at` (nullable ISO datetime)
- DB migration bumped to v5 with additive columns only, so old users remain on `energy_ratio` by default.

### B. Added macro calculator service for two diet modes
- File: `lib/domain/services/macro_target_calculator.dart`
- `energy_ratio` mode:
  - keep existing behavior: kcal target -> macro grams by percentage.
- `gram_per_kg` mode:
  - direct targets:
    - `protein_target_g = weight_kg * protein_coeff`
    - `carbs_target_g = weight_kg * carbs_coeff`
    - `fat_target_g = weight_kg * fat_coeff`
  - coefficient table implemented for male/female and 2/3/4/5 sessions.
  - `prefer_not_to_say` uses male/female average as fallback.
  - also computes `macro_energy_equivalent_kcal` for analysis/export only.

### C. Daily summary now switches by diet mode

## 12) UX + Food Log Copy Update (2026-05-31)

### A. Strength set input overwrite behavior fixed
- File: `lib/features/workout/add_workout_page.dart`
- Problem:
  - Historical values are shown in muted gray, but on some devices tapping into the field placed the cursor in the middle.
  - Typing could append/insert (e.g., `60` -> `6650`) instead of replacing.
- Fix:
  - Added per-field tap handler and default-aware selection logic.
  - If current text equals historical default and still in "default display" state, tap now forces full-text selection.
  - Next numeric input cleanly overwrites old value.
- Result:
  - Historical defaults stay convenient.
  - Editing is predictable and fast without manual deletion.

### B. Food record copy action added
- Files:
  - `lib/features/food/food_log_page.dart`
  - `lib/core/localization/app_strings.dart`
- Added a copy icon button on each food record card.
- Copy behavior:
  - Duplicates the selected record into the current selected date.
  - Copies top-level nutrition fields and item rows.
  - Keeps source/confidence/notes.
  - Saves as a new local record (new id/new timestamps).
- Added localized strings for:
  - copy action label
  - copy success message
  - copy failure message

### C. Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

## 14) Workout Readability Rework (2026-06-01, late)

### A. Remove "Previous" column and recover core data clarity
- Files:
  - `lib/features/workout/add_workout_page.dart`
  - `lib/core/localization/app_strings.dart`
- Reason:
  - Extra "Previous" column compressed the actual weight/reps input area and reduced readability.
- Changes:
  - Removed the "Previous" header/column from set rows.
  - Removed `previousLabel` string in localization.
- Result:
  - More horizontal space for current weight/reps values.
  - Better legibility on narrow/mobile screens.

### B. Reduce crowded "boxed" feeling in set rows
- File: `lib/features/workout/add_workout_page.dart`
- Changes:
  - Removed per-cell rounded input borders and filled capsules in set rows.
  - Switched to lighter, borderless numeric entry style for weight/reps.
  - Kept row structure and action buttons, but simplified visual containers.
  - Added subtle row separators to preserve scanning rhythm without heavy blocks.
- Result:
  - UI feels less cramped while keeping information density.
  - Visual style aligns better with the "spacious but readable" direction.

### C. Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

## 13) Workout UI Compaction + Date-targeted Food Copy (2026-06-01)

### A. Workout input area compacted toward table-style density
- File: `lib/features/workout/add_workout_page.dart`
- Goal:
  - Reduce visual bloat from heavy nested-card feeling.
  - Improve readability when many sets exist.
  - Avoid truncation risk for decimal values like `42.5`.
- Changes:
  - Refined set input style:
    - denser input decoration (`isDense`, reduced padding, compact rounded border)
    - smaller icon button footprint for complete/remove actions
  - Updated set section layout to a denser row structure:
    - `# / Previous / Weight / Reps / Actions`
    - row-level subtle background instead of large separated blocks
  - Added previous-set summary text (`weight x reps`) per row.
  - Reduced per-exercise card visual weight (smaller radius/padding and lower border/background alpha).
- Result:
  - More "stretched" and information-dense UI in the set area.
  - Decimal entries get more practical visible space.

### B. Food copy now supports user-picked target date
- Files:
  - `lib/features/food/food_log_page.dart`
  - `lib/core/localization/app_strings.dart`
- Previous behavior:
  - copy always duplicated to the currently selected day.
- New behavior:
  - tapping copy first opens a date picker.
  - selected date becomes the duplication target.
  - still copies full nutrition fields + item rows as a new record.

### C. Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.
- File: `lib/domain/services/daily_summary_service.dart`
- `energy_ratio`:
  - unchanged flow: no-exercise target + logged net exercise, then macro-by-ratio.
- `gram_per_kg`:
  - macro targets come directly from g/kg table.
  - `target_intake` and `remaining_calories` are set to `0` (not primary counters in this mode).
  - food calories are still stored and exposed as auxiliary intake info.
- Dynamic calorie calibration logic for lifestyle factor remains independent and untouched.

### D. Added training-frequency self-check service (separate from calorie calibration)
- Files:
  - `lib/domain/services/training_frequency_self_check_service.dart`
  - `lib/domain/models/training_frequency_self_check_result.dart`
  - `lib/data/repositories/workout_repository.dart` (new range query)
- Scope:
  - only for `gram_per_kg` mode.
  - does not modify lifestyle factor and does not use 7700 kcal/kg logic.
- Active training day rule:
  - count distinct dates, not session count.
  - valid day if any of:
    1. has strength session
    2. cardio minutes >= 20
    3. total estimated exercise kcal >= 80
- Recommendation:
  - `avg_weekly = active_days / period_days * 7`
  - `recommended = clamp(round(avg_weekly), 2, 5)`
  - with cooldown gating based on `last_macro_self_check_at` (>= 7 days).

### E. UI and export integration
- Files:
  - `lib/features/profile/profile_page.dart`
  - `lib/features/home/home_page.dart`
  - `lib/export/csv_export_service.dart`
  - `lib/export/xlsx_export_service.dart`
  - `lib/domain/models/daily_summary.dart`
  - `lib/core/localization/app_strings.dart`
- Profile page:
  - added diet mode selector.
  - `energy_ratio` keeps activity/goal/macro-ratio settings.
  - `gram_per_kg` shows training frequency + self-check settings and recommendation panel.
- Home page:
  - in `gram_per_kg` mode, primary display is macro current/target grams.
  - calories shown as auxiliary intake only; no kcal target/remaining counter.
- Export:
  - added mode, g/kg/self-check fields for both profile and daily summary sheets/csv.

## 15) Cut MVP g/kg Carbohydrate Table Update (2026-06-04)

### A. gram_per_kg default table revised
- File: `lib/domain/services/macro_target_calculator.dart`
- Scope:
  - updated only the `gram_per_kg` coefficient table for the cut-phase MVP.
  - reduced carbohydrate coefficients for male/female 2/3/4/5 training-frequency tiers.
  - kept protein and fat coefficients aligned with the cut MVP default table.
- `prefer_not_to_say` still uses the male/female average in the same frequency tier.

### B. Algorithm boundary clarified
- Files:
  - `lib/core/localization/app_strings.dart`
  - `README.md`
  - `docs/Algorithm.md`
  - `docs/Product.md`
  - `docs/Agent.md`
  - `docs/Database.md`
- Clarified that:
  - `gram_per_kg` and `energy_ratio` are parallel, independent cut-phase diet calculation methods.
  - `gram_per_kg` does not use BMR, activity level, daily deficit, logged exercise calories, or macro ratio percentages to recalculate carbs.
  - the g/kg table is not a bulking table, maximum sports-performance table, or endurance carb-loading table.
  - training frequency is only a coarse lookup tier, not true intensity, training age, training volume, or performance demand.

### C. Tests
- File: `test/macro_target_calculator_test.dart`
- Added coverage for:
  - male 80 kg at 2 and 5 sessions/week.
  - female 80 kg at 2 and 5 sessions/week.
  - `prefer_not_to_say` 80 kg at 5 sessions/week using male/female average coefficients.
  - `energy_ratio` still converting target kcal by macro ratios.
