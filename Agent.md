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
