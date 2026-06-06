# Changelog

## 2026-06-07 Documentation Structure Cleanup

### Changed
- Rebuilt `README.md` as a stable bilingual project overview with English first and matching Chinese content second.
- Kept `CHANGELOG.md` English-only and limited to dated project changes.
- Split design documentation into `docs/en/` and `docs/zh/`.
- Reworked Product, Algorithm, Database, Agent, and References docs as stable design files instead of date-appended update logs.
- Added document maintenance rules to `AGENTS.md`, including source-of-truth, language, and terminal-encoding verification rules.

### Validation
- Documentation-only change; Flutter analysis and tests were not required.

## 2026-06-07 Workout Record Summary Layout Follow-up

### Changed
- Rebalanced saved workout-record summary columns so the volume value keeps `kg` on the same line more reliably.
- Pushed the sets metric farther right to free more horizontal space for the volume column.
- Kept kcal on the body-part row for collapsed exercise cards and left set count out of the collapsed state.
- Kept the `#` column fixed in saved single-exercise strength tables while shifting the `weight + reps` block to the right.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.
- `flutter build apk --debug`: success.

## 2026-06-06 Workout Record UI Refinement

### Changed
- Moved the strength-calorie estimation note out of each individual strength exercise card and into the shared training-parameters area when strength exercises are present.
- Split workout notes into a separate optional card below training parameters.
- Increased spacing for the total-sets metric in saved workout-record summaries to reduce crowding with total volume.
- Changed saved strength exercise detail to use table-style weight and reps headers.
- Changed saved strength set rows to display weight and reps as separate columns, using `x` before reps.
- Removed the sample naming hint from the workout-record name field.
- Rebalanced vertical spacing around the workout-record name field inside training parameters.
- Workout records now preserve the user's exercise selection order instead of falling back to exercise-library order.
- Exercise-library multi-select now shows selection order as `1 / 2 / 3...` for chosen exercises.
- Saved workout-record summary metrics now stay aligned on one row and keep `kg` on the same line as the volume value.
- Collapsed exercise cards now place kcal beside the body-part line and remove the set-count line.
- Saved single-exercise strength tables now shift the `weight + reps` block to the right while keeping the `#` column fixed.

### Validation
- `flutter build apk --debug`: success.

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
- `energy_ratio` now interprets `daily_energy_goal_kcal` by phase: cutting means deficit, bulking means surplus.
- Profile phase now drives deficit/surplus semantics instead of letting goal types mix freely.
- Home and Profile show the current goal phase.
- `gram_per_kg` remains independent from BMR, activity level, daily energy goal, logged exercise calories, and macro ratios.
- `macro_energy_equivalent_kcal` remains auxiliary in g/kg mode, not a kcal target counter.

### Validation
- Added coverage for cutting/bulking g/kg tables, `prefer_not_to_say` averaging, and phase-based energy target direction.
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

## 2026-06-04 Cut MVP g/kg Carbohydrate Table Update

### Changed
- Updated only the `gram_per_kg` coefficient table for the cut-phase MVP.
- Reduced carbohydrate coefficients for male/female 2/3/4/5 training-frequency tiers.
- Kept protein and fat coefficients aligned with the cut MVP default table.
- Preserved `prefer_not_to_say` as the same-tier male/female average.
- Clarified that `gram_per_kg` and `energy_ratio` are parallel independent diet calculation methods.
- Clarified that training frequency is a coarse lookup tier, not real intensity, training age, training volume, or performance demand.

### Validation
- Added macro target calculator coverage for male, female, `prefer_not_to_say`, and `energy_ratio` conversion behavior.

## 2026-06-01 Workout Readability Rework

### Changed
- Removed the `Previous` column from strength set entry rows to restore horizontal space for current weight/reps input.
- Removed the `previousLabel` localization string.
- Removed per-cell rounded input borders and filled capsules in set rows.
- Switched to lighter borderless numeric entry for weight/reps.
- Kept row structure and action buttons while simplifying visual containers.
- Added subtle row separators to preserve scanning rhythm without heavy blocks.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

## 2026-06-01 Workout UI Compaction And Date-targeted Food Copy

### Changed
- Refined strength set input style with denser input decoration, smaller action buttons, and row-level structure.
- Added previous-set summary text in the compact workout row layout.
- Reduced per-exercise card visual weight.
- Changed food record copy to open a date picker before duplication.
- Copied meal name, nutrition fields, source, confidence, notes, and item rows into a new local record for the selected target date.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

## 2026-05-31 UX And Food Log Copy Update

### Fixed
- Historical strength set values shown in muted text now select fully on tap when still in default-display state.
- New numeric input cleanly overwrites historical defaults instead of inserting into the middle of the value.

### Added
- Added a copy icon button on each food record card.
- Added localized copy action, success, and failure strings.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

## 2026-05-17 Diet Algorithm Dual-Mode Update

### Added
- Added `diet_calculation_mode` with `energy_ratio` and `gram_per_kg`.
- Added `training_frequency_per_week` with 2/3/4/5 tiers.
- Added g/kg self-check fields: `macro_self_check_period_days`, `macro_self_check_enabled`, and `last_macro_self_check_at`.
- Added `MacroTargetCalculator` support for `energy_ratio` macro percentages and `gram_per_kg` table lookup.
- Added `TrainingFrequencySelfCheckService` for g/kg mode.
- Added profile, daily summary, CSV, and XLSX export coverage for diet mode and self-check fields.

### Changed
- `energy_ratio` kept the existing kcal target to macro grams flow.
- `gram_per_kg` computes protein, carbs, and fat directly from bodyweight and same-tier sex/frequency coefficients.
- In `gram_per_kg`, `target_intake` and `remaining_calories` are not primary counters.
- Dynamic calorie calibration remains independent from g/kg self-check.

## 2026-05-16 Dynamic Calorie Target Calibration

### Added
- Added `user_weight_logs` for daily weight history.
- Added `calorie_calibration_state` for calibrated lifestyle factor and confidence metadata.
- Saving Profile now upserts the current day's weight log.
- Added exported metrics for lifestyle factor used, no-exercise target intake, calibration confidence, window, and valid-day count.

### Changed
- Daily target logic now computes a no-exercise baseline first, then adds logged net exercise calories.
- Cardio now uses net MET: `(MET - 1) * 3.5 * weight / 200 * minutes`.
- Strength calories remain volume-driven and split into active lifting, post-training recovery, and muscle repair/adaptation components.
- Strength duration is used only for a capped recovery-density modifier, not linear calorie accumulation.
- Calibration uses 28/21/14/7 day candidate windows, 7-day start/end rolling average weight, observed non-exercise TDEE, EWMA smoothing, per-update step cap, and global factor clamp.

## 2026-05-16 Add Workout Follow-up Fixes

### Fixed
- Decimal historical set weights now render reliably in Add Workout.
- Default workout set values remain convenient while allowing direct overwrite on focus.

### Changed
- Strength duration now creates visible but capped kcal differences through the recovery-density modifier.
- The muscle-repair component remains enabled in strength net kcal.

## 2026-05-15 Workout Flow And Calorie Logic Update

### Fixed
- Hardened workout plan edit save flow against async route/context disposal issues.
- Replaced the bottom-sheet editor with a dedicated full-page editor for date, time, and total duration.

### Added
- Added walking as a cardio exercise and display-name mapping.
- Added a dedicated multi-select exercise picker page.
- Added per-exercise duration input, which is especially important for cardio.
- Added strength net-calorie guidance copy.
- Added localization for the collapsed picker flow, add-selected action, duration guidance, strength notice, and duration validation.

### Changed
- Cardio remains duration-based using MET logic.
- Strength no longer scales calories linearly by duration.
- Strength estimation is driven by set volume, effective load, reps, bounded body factor, bounded intensity factor, recovery, and adaptation.
- Creation and edit paths now use the same calorie logic.
- Historical set values are reusable as defaults, and user edits can directly overwrite them.

### Validation
- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.
