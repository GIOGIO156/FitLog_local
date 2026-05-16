# FitLog Local - Agent Memory

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
  - `no_exercise_target_intake = baseline_no_exercise_tdee ± goal_delta`
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
