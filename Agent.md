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
  - `net_strength_kcal = active_lifting_kcal + capped_recovery_extra_kcal`
  - Active lifting time estimated from `total_reps * default_rep_tempo_seconds`.
  - Active lifting calories use net MET logic (`MET - 1`) to avoid adding resting baseline.
  - Added a small capped recovery component tied to lifting volume (not wall-clock rest time).
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
