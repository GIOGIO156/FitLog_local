# App Guide

## Purpose

This guide explains what each FitLog Local app area does, how it works at a high level, and where to read the design details. It is a user and maintainer map, not a replacement for Product, Methodology, Algorithm, Database, Agent, or References.

## App-wide Rules

- FitLog Local is local-first: business data is stored in SQLite unless the user exports it.
- Home, Food Log, and Workout Log share the selected date.
- The app has no internal LLM/API/Agent loop.
- External AI can help create food estimates before data enters the app, but FitLog stores and calculates locally.
- `diet_goal_phase` controls cutting/bulking semantics.
- `energy_ratio` and `gram_per_kg` stay separate.

Read more:

- Product scope: [Product](Product.md)
- Method reasoning: [Methodology](Methodology.md)
- AI boundary: [Agent](Agent.md)

## Home

Home is the selected-day dashboard.

What users see:

- local-time greeting using the locally saved nickname when present, with long nicknames moved to a dedicated second line when needed
- selected date
- primary calorie overview in `energy_ratio`
- primary macro overview in `gram_per_kg`
- compact macro progress for protein/carbs/fat in three equal-size cards rendered from dedicated SVG assets
- current `diet_goal_phase`, `diet_calculation_mode`, and `diet_plan_strategy`
- compact selected-day food/workout summaries with navigation to detail pages

How it works:

- `DailySummaryService` reads Profile, Food, Workout, calibration, self-check, and strategy data.
- Food totals come from saved `food_records`.
- Exercise totals come from saved `workout_sessions.estimated_calories`.
- `energy_ratio` uses kcal target/intake/remaining as primary.
- `gram_per_kg` uses macro grams as primary and treats kcal as auxiliary.
- Strategy fields show final target context after `none`, `carb_cycling`, or `carb_tapering` is applied.
- When carb cycling or carb tapering is active, the Home strategy card opens a structured explainer sheet with methodology-oriented guidance for non-expert users.
- Detailed BMR/TDEE/calibration numbers are intentionally left out of the Home surface and remain available in Profile-oriented views.

Read more:

- Daily behavior: [Product](Product.md#daily-dashboard-behavior)
- Calculation reasoning: [Methodology](Methodology.md)
- Formulas: [Algorithm](Algorithm.md)
- Runtime aggregate fields: [Database](Database.md#runtime-aggregates)

## Food Log

Food Log is the selected-day food record list.

What users can do:

- view saved meals for the selected date
- open and edit a record
- copy a record to a chosen date
- delete a record after confirmation
- start Add Food
- read the estimation notice after scrolling past the selected-day meal list

How it works:

- A meal is stored as one `FoodRecord`.
- Optional item rows are stored as `FoodItem`.
- `source` records whether the meal came from manual entry or external AI paste.
- Copying creates a new local record with new ids/timestamps.
- Deleting a food record cascades to its item rows.

Read more:

- Food workflow: [Product](Product.md#food-workflow)
- Tables: [Database](Database.md#food_records), [Database](Database.md#food_items)
- AI-adjacent boundary: [Agent](Agent.md)

## Add Food

Add Food is the food entry gateway.

Entry options:

- `Paste AI Result`: paste JSON produced outside the app.
- `Manual Entry`: type food data directly.
- `Photo AI Analysis`: visible placeholder only; app-internal image recognition is not implemented.
- Prompt copy: copy a Chinese or English prompt for use with an external model.

How it works:

- Prompt copy is static text, not an AI call.
- Pasted JSON is parsed locally by `NutritionCalculator`.
- The preview page lets users correct parsed values before saving.
- Manual entry writes a local record without item rows unless later edited.

Read more:

- Product behavior: [Product](Product.md#food-workflow)
- AI boundary: [Agent](Agent.md)
- Parser and summary formulas: [Algorithm](Algorithm.md#food-intake-summary)

## Workout Log

Workout Log is the selected-day workout record list.

The page title leads directly into the shared date strip, without a separate subtitle block above the calendar.

What users can do:

- view saved workout records for the selected date
- open a saved record
- delete a saved record
- start Add/Edit Workout Record

How it works:

- A user-facing `Workout Record` can contain multiple exercises.
- Internally, one multi-exercise record is multiple `workout_sessions` sharing the same `plan_id`.
- Each session in the same record also stores the same `record_name`.
- Record-level summaries are derived from persisted sessions and sets.
- Body-part thumbnails and key workout glyphs now come from shared SVG assets instead of ad hoc painter-based mini-icons.

Read more:

- Workout workflow: [Product](Product.md#workout-workflow)
- Workout tables: [Database](Database.md#workout_sessions), [Database](Database.md#workout_sets)

## Add/Edit Workout Record

Add/Edit Workout Record is where users create or revise a named workout record.

What users can do:

- name the workout record
- choose one or more exercises from the current chest, back, legs, glutes, shoulders, arms, core, full-body, and cardio library
- keep selected exercises in user-chosen order
- enter per-exercise duration
- enter strength sets with weight, reps, and completed state
- add notes
- save completed strength sets

How it works:

- Exercise selection supports body-part filtering, search, and multi-select order.
- Cardio exercises use duration and have no set checklist.
- Strength exercises use set rows.
- Assisted bodyweight exercises store assistance load in the weight field, and calorie estimation treats actual load as `bodyweight - assistance`.
- Save validation happens before persistence.
- Only completed strength sets are saved; unchecked sets are discarded.
- Editing a saved record replaces the full `plan_id` group transactionally.

Read more:

- Product workflow: [Product](Product.md#workout-workflow)
- Workout calorie reasoning: [Methodology](Methodology.md#why-exercise-calories-are-net-calories), [Methodology](Methodology.md#why-strength-training-is-not-just-minutes)
- Formulas: [Algorithm](Algorithm.md#workout-calories)
- Storage model: [Database](Database.md#workout_sessions)

## Workout Record Detail

Workout Record Detail explains a saved workout after persistence.

What users see:

- record name
- date and start time
- total duration
- total volume
- total sets
- estimated calories
- exercises in the record
- saved strength set detail

How it works:

- Summary metrics are derived from saved sessions and saved sets.
- Total volume is based on saved strength sets.
- Set count is the number of saved strength sets.
- Saved strength detail is read-only for completion state in the current record flow.

Read more:

- Product behavior: [Product](Product.md#workout-workflow)
- Data model: [Database](Database.md#workout_sessions), [Database](Database.md#workout_sets)

## Profile

Profile is where users configure personal data, diet behavior, language, export, and local data actions.

What users can set:

- nickname for local-only UI display
- age, height, weight, and sex option
- language
- `diet_goal_phase`
- `diet_calculation_mode`
- `energy_ratio` activity level, daily energy goal, and macro percentages
- `gram_per_kg` training-frequency tier and self-check settings
- `diet_plan_strategy`
- carb cycling pattern and multipliers
- carb taper review period, target loss rate, step size, and current offset

How it works:

- Profile saves to singleton `user_profile`.
- `nickname` is local-only profile data and is not an account identifier.
- Saving Profile also upserts the current day's weight log.
- Under-18 protection blocks adult-style cutting deficit behavior and cutting carb strategies.
- g/kg self-check can recommend a training-frequency tier from recent valid training days.
- Carb taper review can suggest a local action, but user confirmation is required.

Read more:

- Product behavior: [Product](Product.md#diet-setup-ux)
- User-facing method explanation: [Methodology](Methodology.md)
- Algorithm details: [Algorithm](Algorithm.md)
- Profile table: [Database](Database.md#user_profile)

## Export

Export creates local files for the user's records.

What exports include:

- food records
- food items
- workout records
- workout sets
- daily summary
- user profile
- diet adjustment review history
- strategy, calibration, and self-check fields where relevant

How it works:

- XLSX and CSV ZIP exports are written to the app documents directory.
- Daily summary export is generated at export time from repositories and `DailySummaryService`.
- Export does not upload data.

Read more:

- Export coverage: [Database](Database.md#export-coverage)
- Product boundary: [Product](Product.md#implemented-boundaries)

## Language

Language preference controls UI copy and prompt copy.

How it works:

- The current language is stored in SharedPreferences as `language_code`.
- Prompt copy follows the current language.
- Language state is app-local.

Read more:

- Storage overview: [Database](Database.md#storage-overview)

## Privacy And Local-first Boundary

FitLog Local does not currently have accounts, backend sync, remote database, or app-internal AI calls.

What stays local:

- profile data
- food records
- workout records
- weight logs
- calibration state
- diet adjustment reviews
- exports
- language preference

Read more:

- Database storage: [Database](Database.md)
- AI boundary: [Agent](Agent.md)
- Evidence and safety boundaries: [References](References.md)
