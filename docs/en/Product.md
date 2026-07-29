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
- Bottom navigation and fixed CTA visual backgrounds do not define layout geometry: the root bottom navigation is a body overlay rather than a `Scaffold.bottomNavigationBar` slot, so the area outside each pill must not become a full-width footer band. The nav pill itself uses opaque `navBackground`, and a width-matched `background` shield may sit behind the lower half of the pill to stop scrolling content from showing through the bottom rounded corners. `FitLogBottomNavLayout` is the single source for nav footprint, bottom safe-area gap, Home first-viewport height, fixed CTA placement, scroll bottom padding, and guide-sheet bottom avoidance.
- Guide-style modal sheets, including Home strategy guidance and Profile current-plan guidance, use a root modal route: the scrim covers and disables the bottom navigation, while the sheet content is positioned above the navigation footprint instead of overlapping the nav pill. These sheets keep a top focus gap and scroll long explanatory content inside the panel instead of stretching to the status bar.
- System notifications use one shared FitLog notification layer instead of page-local `SnackBar` construction. Success and neutral notices appear as compact lightweight top overlays without manual close controls; errors and action notices appear above the keyboard or bottom navigation footprint. Action notices preserve their button callback, and all variants derive color and type from the active FitLog theme.
- Android workout-in-progress notifications are a separate platform notification surface for active local workout drafts. They do not create backend work or background calculation; they mirror the current draft state and return the user to the editor when the notification body is tapped.

## Current Modules

| Module | Current capability | Main code |
| --- | --- | --- |
| Home | Low-density selected-day entry screen for greeting, primary calorie/macro overview, current diet context, and compact food/workout summaries. | `lib/features/home/home_page.dart`, `DailySummaryService` |
| Food Log | Date-filtered food records with open/edit, copy-to-date, delete, and add entry points. | `lib/features/food/food_log_page.dart`, `FoodRepository` |
| Add Food | Manual entry, external AI JSON paste, prompt copy, and placeholder `Photo AI Analysis`; manual entry uses the same compact food-form grid as saved-record editing. | `add_food_page.dart`, `paste_ai_result_page.dart`, `manual_food_entry_page.dart` |
| Food Detail | Editable saved food record and item rows with localized field labels and suffix units while storage/JSON keys stay unchanged. | `food_detail_page.dart` |
| Workout Log | Date-filtered saved workout records grouped by internal `plan_id`. | `workout_log_page.dart`, `WorkoutRepository` |
| Add/Edit Workout Record | Named multi-exercise workout record creation/editing, exercise picker, temporary or reusable custom exercises, cardio duration/intensity, strength input modes, completed-set persistence, 30-minute cold-start resume for active new drafts, Android workout-in-progress notification mirroring, notes, and summary calculation. | `add_workout_page.dart` |
| Workout Record Detail | Saved record detail, summary metrics, exercise cards, and edit re-entry. | `workout_plan_page.dart` |
| Workout Session Detail | Single-exercise detail view; saved strength detail is read-only for completion state in the current record flow. | `workout_session_page.dart` |
| Profile | Local nickname, a `User Settings` summary header, current-plan summary hero, display-first body-profile grid for age/height/weight/sex/body fat/waist with one shared current-profile save, a date-picker-backed inline body-card state for past body metric records, clean read-only weight/body-fat/waist trend switching with range-scaled point spacing, metric-scaled reference lines, and tap-only point tooltip, direct phase/mode/strategy matrix, local theme and language preferences, a consistently named training-frequency/self-check setup card, card-local save actions for text/number inputs, export, and clear-local-data actions. | `profile_page.dart`, `ProfileRepository`, `ThemeController` |
| Export | XLSX and CSV ZIP exports for raw records, parent workout records plus workout exercise/set details, custom exercises, daily summary, profile, body metric history, strategy fields, and review history. Export output follows the current app language for sheet names, CSV file names, headers, and known enum labels; export file names include the first exported record date and export date when records exist, and Profile opens the system share sheet after file creation. | `lib/export/*` |

## Food Workflow

1. The user opens Food Log and selects a date.
2. The user chooses Add Food.
3. For external AI-assisted entry, the user copies FitLog's language-matched prompt once into a new external-model conversation. A later new food image normally starts a new meal, while add/remove/replace/recalculate follow-ups update the most recent meal; every response remains one complete strict JSON object in the existing schema.
4. FitLog parses JSON locally with `NutritionCalculator.parseAiFoodJson`.
5. The user previews, corrects, and saves the `FoodRecord` and optional `FoodItem` rows.
6. Manual entry skips JSON parsing and saves a record with `source = manual`.
7. Saved records can be edited, deleted, or copied to a user-selected target date.
8. Home and Food Log refresh through local repositories and app refresh state.

## Workout Workflow

1. The user opens Workout Log and selects a date.
2. The user creates a `Workout Record`, gives it a name, and selects one or more exercises.
3. The exercise library supports body-part filtering, search, multi-select, visible selection order, and reusable custom exercises saved locally.
4. The user can add a temporary custom exercise to the current record; on save, FitLog asks whether to keep it in the reusable custom library.
5. Reusable custom exercises appear in a dedicated `Custom exercises` picker group instead of being merged into the built-in chest/back/legs/body-part groups.
6. When the user is viewing that dedicated custom group, reusable custom exercises support inline swipe-to-delete with confirmation instead of a separate management page or a global library action.
7. The temporary custom-exercise creation page is a card-first control surface with the same title scale as Add Workout, a compact slider-style strength/cardio switch, one identity card for the name, a bento-style strength metadata card, short tappable tile labels, a compact recording-rules card that gives long load labels a full-width row, narrow-screen single-column fallback, section headers aligned to the shared workout card-title scale, tighter real-device typography, and a fixed bottom add action.
8. Cardio exercises require per-exercise duration and session intensity, and have no set checklist.
9. The cardio duration helper is shown above the duration field, and the intensity explanation is shown above the intensity picker to avoid dropdown overflow and keep the question readable.
10. Cardio intensity is entered as a maintainable-duration basis: 60+ minutes, 30-60 minutes, 10-30 minutes, 3-10 minutes, or under 3 minutes with rests.
11. Interval or very-high-intensity cardio records active movement time so rest time is not treated as extreme-intensity work.
12. Strength exercises use set rows with weight, reps or single-set duration, and completed state.
13. Built-in and custom strength exercises store the input mode used for the session: total load, per-side load, bodyweight plus added load, assistance load, total reps, per-side reps, or duration-based sets.
14. While the user is editing, FitLog persists one local workout draft instead of immediately creating or mutating a saved workout record.
15. Leaving the editor through the app back button or system back gesture saves and keeps the draft instead of forcing a save/discard modal, then clears the lightweight auto-resume marker.
16. If the app enters `inactive`, `paused`, or `hidden` while the user is still on a new Add Workout draft editor, FitLog immediately persists the SQLite draft and keeps a lightweight editor-active marker in SharedPreferences. The marker is only navigation eligibility state; the SQLite draft remains the source of truth.
17. On cold start, Root checks this once: if the marker exists, the SQLite active draft is a new-record draft, and `updatedAt` is no more than 30 minutes old, FitLog switches to Workout and opens Add Workout once, restoring date, exercises, set rows, weights, reps or durations, completed state, record name, and notes.
18. The 30-minute window is only a cold-start eligibility check. FitLog does not run a background countdown, alarm, worker, foreground service, wake lock, keep-alive mechanism, or any background calculation for this recovery path.
19. Explicit editor exit, discard, formal save, and draft clearing/deletion clear the marker. The SQLite draft remains available for manual Workout Log recovery after normal exit or after the 30-minute auto-resume window expires.
20. Workout Log shows a compact two-line draft-resume bar above `Add Workout`; its title prefers the record name and otherwise falls back to `Workout draft`, while the subtitle uses short body-part labels, shows up to three body parts before switching to `+n`, and then appends exercise count or `Tap to continue editing`.
21. On Android, an active strength draft can also show a persistent workout notification. The notification title is only the current exercise name, the body shows the next set such as `Set 2 of 9 - 50 kg x 8 reps`, the notification large icon uses the current exercise image, and the status-bar small icon comes from the saved transparent FitLog SVG source converted into an Android drawable.
22. The workout notification follows the most recently checked completed set: it stays on that exercise for the next unfinished set, then falls back to the first unfinished exercise in workout order when that exercise is complete. If every strength set is checked, the notification moves to a completion prompt that returns to the editor for review/save.
23. Tapping the Android notification body opens the active draft in Add/Edit Workout Record through the same resume path as the Workout Log draft bar. The platform expand arrow remains controlled by Android and is not an app-defined action.
24. Save validation completes before any saved-record persistence happens.
25. Strength saves persist completed sets only; unchecked sets are removed and saved sets are renumbered from `1..n`.
26. A multi-exercise record is stored as multiple `workout_sessions` sharing one `plan_id`; every session also stores the same `record_name`.
27. Saved records keep an exercise snapshot so later edits to a reusable custom exercise do not reinterpret historical records.
28. Saved records show duration, calculation-volume, total sets, estimated calories, and exercise cards.
29. Editing a saved record re-enters the same page used for creation and replaces the full `plan_id` group transactionally, while abandoned changes stay only in the draft layer until the user discards or saves them. Edit drafts do not qualify for the new-workout cold-start auto-resume path.

## Daily Dashboard Behavior

- The selected date is shared by Home, Food Log, and Workout Log.
- Home is intentionally lower density than the detail pages.
- Home shows a local-time greeting with a local nickname fallback, selected date, current diet context, and compact food/workout summaries, but the first-screen structure changes by calculation mode.
- Home's selected-day workout summary count is `DailySummary.workoutSessions.length`: each saved exercise entry counts once, independent of grouped workout records sharing a `plan_id`. The count uses `exercise` / `exercises` in English and `个动作` in Chinese.
- In `energy_ratio`, kcal target/intake/remaining is primary and Home keeps the calorie-ring hero plus compact macro cards.
- In `energy_ratio`, the first viewport is defined as a two-card kcal-first box: the calorie hero and macro cards live inside one dedicated first-screen container, their internal gap stays controlled, and only a short protective tail separates the strategy card from the macro card.
- In `gram_per_kg`, macro grams are primary and kcal is auxiliary intake information; Home replaces the calorie-ring hero with a dedicated macro dashboard that absorbs kcal intake/workout summaries, expands to fill the opening viewport, and keeps strategy below that first-screen macro area.
- In `gram_per_kg`, the strategy separation also comes from a dedicated first-screen dashboard container, but the macro-first dashboard owns that space directly instead of reusing the calorie-first box structure from `energy_ratio`.
- Detailed BMR, TDEE, calibration, and long record editing flows stay in Food Log, Workout Log, Profile, and detail pages.
- Home also shows `diet_goal_phase`, `diet_calculation_mode`, and `diet_plan_strategy` context.
- `carb_cycling` displays carb day type and carb adjustment context.
- `carb_tapering` displays current taper offset and pending review context when available.
- In English, the active Home strategy card formats long strategy states as `Strategy\n- status` instead of keeping the hyphen suffix on the first line.

## Diet Setup UX

Profile presents diet setup as a summary-first control surface instead of a long first-screen form:

1. Local identity summary: nickname used only for on-device UI such as the Home greeting, shown under the `User Settings` header as a compact one-line identity row with a trailing pen trigger, and edited inline only when the user activates it.
2. Current-plan hero: current phase, diet mode, training-frequency/self-check summary, strategy label, and static macro target strip whose protein, carbs, and fat icon badges reuse the same nutrient-specific soft backgrounds as Home.
3. Body-profile summary and shared editing: age, height, weight, sex, body fat, and waist stay in a readable display grid; tapping one tile opens the whole body grid for current Profile editing, and dirty values use one card-local save/cancel action instead of a separate long editing form.
4. Plan matrix: direct tap chips for `diet_goal_phase`, `diet_calculation_mode`, and `diet_plan_strategy`, kept in a stable horizontal wrap layout instead of switching into full-width vertical buttons.
5. Current-plan help sheet: the hero keeps a small information trigger at the upper-right edge and opens the same nav-aware, non-full-screen guide sheet used by the Home strategy guide; `gram_per_kg` shows the current phase/sex coefficient table by training-frequency row, while `energy_ratio` shows the default macro split plus the default lifestyle-factor table.
6. Shared training-frequency/self-check card near the top, with direct-save chips for training frequency and self-check period, four self-check period choices kept on one row, without duplicating the self-check summary inside the setup card, and with one stable card title across diet modes.
7. In `energy_ratio` mode, the energy-ratio settings card appears immediately below the plan matrix and above the shared training-frequency/self-check card so the mode-specific numeric inputs stay adjacent to the mode selector.
8. Input-heavy cards such as nickname, body fields, and `energy_ratio` details save locally from within the same card; nickname and body fields default to read-only display, while direct chips and switches save immediately.
9. Theme and language preferences are low-frequency local UI settings near the lower Profile settings area; theme choices are Green, Blue, and Black, and they only remap app color tokens.
   The Blue theme follows the same role mapping as Green while keeping page backgrounds, ordinary cards, inputs, Profile inner tiles, and informational areas white; the bottom navigation pill stays a distinct surface, and the area outside it reveals the page background instead of acting as a separate full-width navigation surface. `#55DCE2` is the brighter but soft solid button and strong-fill color, pale aqua supports selected pills and small emphasis badges, and deeper teal/indigo derivatives carry text, icons, borders, and contrast.
   The Black theme keeps the black-orange direction with dark background, card, input, selected-surface, and outline roles separated so orange remains an accent instead of becoming a general surface color.
10. The full training-frequency self-check card stays below the setup cards instead of being mixed into the `g/kg` setup body, and the long g/kg explanatory note now lives in the help sheet rather than inside the setup card.

Expected behavior:

- `cutting + gram_per_kg`: show the shared training-frequency setting, self-check settings, cutting g/kg table context, and macro target preview.
- `bulking + gram_per_kg`: show the shared training-frequency setting, self-check settings, bulking g/kg table context, and macro target preview.
- `cutting + energy_ratio`: show the shared training-frequency setting, daily deficit, macro ratios, and target preview.
- `bulking + energy_ratio`: show the shared training-frequency setting, daily surplus, macro ratios, default 25/50/25 suggestion, and target preview.
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
- shared training-frequency self-check across both diet modes
- cutting/bulking phase split
- `energy_ratio` and `gram_per_kg` diet calculation modes
- local deterministic `carb_cycling` and `carb_tapering`
- XLSX and CSV ZIP export with localized table labels, workout parent/detail tables, and the system share sheet opened after file creation
- language switching
- local theme switching
- local data clearing with confirmation
- 30-minute cold-start auto-resume for active new workout drafts, driven by SQLite draft data plus a lightweight local marker
- Android workout-in-progress notification for active local strength drafts

Not implemented:

- backend, cloud sync, accounts, remote database, or import
- app-internal image recognition
- app-internal LLM API calls
- RAG, vector database, embedding storage, semantic memory, tool calling, or Agent loop
- automatic meal planning, AI coach, or automatic goal modification
- medical advice

## Code References

- App bootstrap and providers: `lib/main.dart`, `lib/app.dart`
- Android launcher label and icon: APK installs display as `FitLog local` via `android/app/src/main/AndroidManifest.xml`; the package id remains `com.fitlog.local.fitlog_local` so existing local data stays in the same Android app sandbox. Launcher icons come from `assets/icons/app/fitlog.png` and `android/app/src/main/res/mipmap-*/ic_launcher.png`.
- In-app system notices: `lib/core/widgets/fitlog_notifications.dart`
- Android workout notification: `lib/core/utils/workout_notification_bridge.dart`, `lib/domain/services/workout_notification_snapshot_builder.dart`, `android/app/src/main/kotlin/com/fitlog/local/fitlog_local/MainActivity.kt`, `assets/icons/app/fitlog_notification_small.svg`, `android/app/src/main/res/drawable/ic_stat_fitlog.xml`
- Home: `lib/features/home/home_page.dart`
- Food: `lib/features/food/*`
- Workout: `lib/features/workout/*`
- Profile: `lib/features/profile/profile_page.dart`
- Models: `lib/domain/models/*`
- Services: `lib/domain/services/*`
- Database and repositories: `lib/data/db/app_database.dart`, `lib/data/repositories/*`
- Export: `lib/export/*`
- Localization and prompt templates: `lib/core/localization/*`, `lib/core/constants/prompt_templates.dart`
