# Algorithm Design

## Source-of-truth Inputs

| Input | Meaning | Used by |
| --- | --- | --- |
| `age` | BMR estimate and under-18 protection. | BMR, safety rules |
| `height_cm` | Height in centimeters. | BMR |
| `weight_kg` | Bodyweight in kilograms. | BMR, g/kg macros, workout calories |
| `sex_for_formula` | `male`, `female`, or `prefer_not_to_say`. | BMR, g/kg tables |
| `activity_level` | Non-exercise daily activity tier. | `energy_ratio` baseline |
| `diet_goal_phase` | `cutting` or `bulking`; phase source of truth. | Target semantics |
| `diet_calculation_mode` | `energy_ratio` or `gram_per_kg`. | Base target selection |
| `daily_energy_goal_kcal` | Daily deficit or surplus amount depending on phase. | `energy_ratio` |
| `protein_ratio_percent`, `carbs_ratio_percent`, `fat_ratio_percent` | Macro energy percentages. | `energy_ratio` |
| `training_frequency_per_week` | Coarse 2/3/4/5 lookup tier. | `gram_per_kg` only |
| `diet_plan_strategy` | `none`, `carb_cycling`, or `carb_tapering`. | Strategy layer |
| Food records | Daily kcal/protein/carbs/fat intake. | Daily summary |
| Workout sessions/sets | Saved exercise calories and strength volume inputs. | Workout calories, daily summary |
| Weight logs | Daily bodyweight history. | Dynamic calorie calibration and taper review |

`activity_level` and `training_frequency_per_week` must stay separate. Activity level estimates non-exercise daily baseline. Training frequency is only a coarse g/kg table lookup tier, not a measure of intensity, training age, training volume, or performance demand.

## Diet Architecture

Diet computation has two stages:

1. Base target layer: applies `diet_goal_phase x diet_calculation_mode`.
2. Strategy layer: applies `diet_plan_strategy` after base targets exist.

The base layer is the source of truth for phase and mode. The strategy layer may adjust final displayed macros/target context, but it must not merge the two base calculation modes.

## BMR And Baseline

FitLog uses Mifflin-St Jeor style BMR estimates:

```text
male = 10 * weightKg + 6.25 * heightCm - 5 * age + 5
female = 10 * weightKg + 6.25 * heightCm - 5 * age - 161
prefer_not_to_say = average(male, female)
```

Non-exercise baseline:

```text
baselineNoExerciseTdee = bmr * lifestyleFactorUsed
```

`lifestyleFactorUsed` comes from dynamic calibration when available and valid; otherwise it falls back to the activity-level default:

| `activity_level` | Default non-exercise factor |
| --- | ---: |
| `sedentary` | 1.20 |
| `lightly_active` | 1.30 |
| `moderately_active` | 1.425 |
| `very_active` | 1.60 |

## `energy_ratio`

`energy_ratio` is the kcal-primary mode.

```text
if diet_goal_phase == cutting:
  noExerciseTarget = baselineNoExerciseTdee - dailyEnergyGoalKcal

if diet_goal_phase == bulking:
  noExerciseTarget = baselineNoExerciseTdee + dailyEnergyGoalKcal

targetIntake = noExerciseTarget + loggedNetExerciseKcal
remainingCalories = targetIntake - caloriesInToday
```

Macro targets are converted from target kcal by normalized macro percentages:

```text
ratioTotal = proteinRatioPercent + carbsRatioPercent + fatRatioPercent
proteinRatio = proteinRatioPercent / ratioTotal
carbsRatio = carbsRatioPercent / ratioTotal
fatRatio = fatRatioPercent / ratioTotal

targetProteinG = targetIntakeKcal * proteinRatio / 4
targetCarbsG = targetIntakeKcal * carbsRatio / 4
targetFatG = targetIntakeKcal * fatRatio / 9
macroEnergyEquivalentKcal = protein*4 + carbs*4 + fat*9
```

If ratios are invalid at calculation time, the calculator falls back to 30/40/30. Profile save validation requires the visible ratio fields to sum to 100.

## `gram_per_kg`

`gram_per_kg` is the macro-primary mode.

```text
targetProteinG = weightKg * proteinCoeff
targetCarbsG = weightKg * carbsCoeff
targetFatG = weightKg * fatCoeff
macroEnergyEquivalentKcal = protein*4 + carbs*4 + fat*9
targetIntake = 0
remainingCalories = 0
```

Boundaries:

- It uses only bodyweight, sex option, goal phase, and `training_frequency_per_week`.
- It does not use BMR, `activity_level`, `daily_energy_goal_kcal`, logged exercise calories, or macro ratio percentages.
- `macroEnergyEquivalentKcal` is auxiliary analysis/export data, not the kcal target counter.
- For `prefer_not_to_say`, use the same-frequency male/female average.

Cutting table, protein/carbs/fat g/kg:

| Sex | 2 days | 3 days | 4 days | 5 days |
| --- | --- | --- | --- | --- |
| male | 1.4 / 1.5 / 0.8 | 1.6 / 1.8 / 0.8 | 1.7 / 2.0 / 0.9 | 1.8 / 2.2 / 1.0 |
| female | 1.4 / 1.4 / 1.0 | 1.6 / 1.6 / 1.0 | 1.7 / 1.7 / 1.1 | 1.8 / 1.9 / 1.2 |

Bulking table, protein/carbs/fat g/kg:

| Sex | 2 days | 3 days | 4 days | 5 days |
| --- | --- | --- | --- | --- |
| male | 1.6 / 3.0 / 0.8 | 1.7 / 3.4 / 0.9 | 1.8 / 3.8 / 0.9 | 2.0 / 4.2 / 1.0 |
| female | 1.6 / 2.8 / 0.9 | 1.7 / 3.1 / 1.0 | 1.8 / 3.4 / 1.0 | 2.0 / 3.8 / 1.1 |

## Diet Plan Strategy Layer

Applicable strategies:

- `none`: final targets equal base targets.
- `carb_cycling`: cutting-only, adult-only weekly carb redistribution.
- `carb_tapering`: cutting-only, adult-only review suggestion flow.

Under-18 users cannot enable cutting carb strategies.

### `carb_cycling`

The strategy redistributes carbs across high/medium/low days while preserving the normalized weekly average.

```text
rawMultiplier(day) = high / medium / low
sumRaw = sum(rawMultiplier over 7 days)
normalizer = 7 / sumRaw
normalizedMultiplier(day) = rawMultiplier(day) * normalizer

finalCarbsG(day) = baseCarbsG * normalizedMultiplier(day)
finalProteinG(day) = baseProteinG
finalFatG(day) = baseFatG
finalMacroEnergyEquivalentKcal = P*4 + C*4 + F*9
```

Safety floor:

```text
minCarbsG = max(weightKg * 1.2, 100)
```

If final carbs would fall below the floor, FitLog clamps carbs and adds `carb_floor_applied`.

### `carb_tapering`

The strategy reviews rolling weight trend, food-log coverage, and training stability. It never auto-applies.

Review windows: default 14 days, with 21/28/7 options.

Trend formula:

```text
startAvgWeight = first 7-day average in window
endAvgWeight = last 7-day average in window
weightChangeKg = endAvgWeight - startAvgWeight
lossRatePctPerWeek = (-weightChangeKg / startAvgWeight) * 100 * 7 / windowDays
```

Data floor:

- at least 7 weight logs in the window
- food log coverage at least 0.70
- both early and late window segments need weight data

Decision behavior:

- slower than target minus tolerance: `decrease_carbs`
- within target band: `keep`
- faster than target plus tolerance: `pause_taper`
- insufficient data: `no_data`
- material training drop: prefer `keep`
- projected carbs below floor: `blocked_by_safety_floor`

Application formula after user confirmation:

```text
taperedCarbsG = max(baseCarbsG + carb_taper_current_delta_g, minCarbsG)
```

`carb_taper_current_delta_g` is cumulative relative to base carbs.

## Food Intake Summary

Daily intake is computed from saved food records for the selected date:

```text
caloriesIn = sum(food_records.calories_kcal)
proteinG = sum(food_records.protein_g)
carbsG = sum(food_records.carbs_g)
fatG = sum(food_records.fat_g)
```

`DailySummary` is runtime aggregate data. It is not stored as a database table.

## Workout Calories

Workout calories are calculated when workout records are created or edited and then saved on `workout_sessions.estimated_calories`.

Cardio uses net MET to avoid double counting resting baseline:

```text
netMet = max(0, MET - 1)
netCardioKcal = netMet * 3.5 * bodyWeightKg / 200 * durationMinutes
```

Current cardio MET map:

| Exercise | MET |
| --- | ---: |
| Walking | 4.3 |
| Running | 8 |
| Cycling | 6 |
| Rowing Machine | 7 |
| Stair Climber | 8 |

Strength uses volume-driven net calories:

1. Prefer completed sets with `reps > 0`; if none exist, use all valid entered sets.
2. Bodyweight movements use `bodyWeightKg * bodyweightShare + externalLoadKg` as effective load.
3. Assisted bodyweight movements store assistance in `weight_kg`, and use `max(0, bodyWeightKg - assistanceKg)` as effective load.
4. Non-bodyweight movements use external load.
5. Compute `totalVolumeKg = sum(effectiveLoadKg * reps)`.
6. Select movement profile coefficients from the updated chest/back/legs/glutes/shoulders/arms/core/full-body movement library.
7. Use duration only in a capped recovery-density modifier, not as linear calorie accumulation.

```text
activeLiftingKcal =
  totalVolumeKg * strengthCoefficient * bodyFactor * intensityFactor

postTrainingRecoveryKcal =
  activeLiftingKcal * postTrainingRecoveryRate * recoveryDensityModifier

muscleRepairAdaptationKcal =
  activeLiftingKcal * muscleRepairAdaptationRate

netStrengthKcal =
  activeLiftingKcal + postTrainingRecoveryKcal + muscleRepairAdaptationKcal
```

Movement coefficients:

| Profile | strengthCoefficient | postTrainingRecoveryRate | muscleRepairAdaptationRate |
| --- | ---: | ---: | ---: |
| `upperBodyCompound` | 0.013 | 0.28 | 0.12 |
| `lowerBodyCompound` | 0.019 | 0.34 | 0.16 |
| `isolation` | 0.0085 | 0.12 | 0.06 |
| `fullBodyPowerOrHighDensity` | 0.024 | 0.45 | 0.20 |

Additional modifiers:

```text
bodyFactor = clamp(sqrt(bodyWeightKg / 80), 0.85, 1.15)
recoveryDensityModifier = clamp(1 + (densityRatio - 1) * 0.28, 0.85, 1.35)
```

Workout calories are added to `energy_ratio` target intake. They do not directly change g/kg macro targets.

## Dynamic Calorie Calibration

Dynamic calibration updates the non-exercise lifestyle factor from local history.

Rules:

- candidate windows: 28 / 21 / 14 / 7 days
- at most one calibration every 7 days
- use 7-day start/end rolling average weight
- require sufficient food logs and weight logs
- use 7700 kcal/kg as a rough historical approximation
- smooth updates with EWMA
- cap each update and clamp the global factor

```text
observedTotalTdee = avgDailyIntake - weightChangeKg * 7700 / windowDays
observedNoExerciseTdee = observedTotalTdee - avgDailyExercise
observedLifestyleFactor = observedNoExerciseTdee / avgBmr
newFactor = oldFactor * 0.8 + observedLifestyleFactor * 0.2
```

Bounds:

- per-update step cap: +/-0.03
- global factor range: 1.10 to 1.70
- minimum confidence: 0.35

Calibration is independent from g/kg self-check.

## g/kg Training-frequency Self-check

Self-check applies only in `gram_per_kg`.

Valid training day rule: count distinct dates, not sessions. A day is valid if any condition is true:

1. at least one strength session
2. cardio total duration is at least 20 minutes
3. daily total estimated exercise calories is at least 80 kcal

Recommendation:

```text
averageWeekly = activeTrainingDays / periodDays * 7
recommended = clamp(round(averageWeekly), 2, 5)
```

Periods: 7 / 14 / 21 / 28 days.

Cooldown: show/apply feedback no more frequently than every 7 days through `last_macro_self_check_at`.

Self-check does not update `lifestyle_factor_non_exercise`, does not use weight-change equations, and does not use observed TDEE EWMA.

## Algorithm Boundaries

- All current target, summary, workout calorie, calibration, strategy, and self-check calculations are local deterministic Dart code.
- External AI prompt copy and JSON paste do not constitute app-internal AI reasoning.
- No current algorithm uses RAG, vector search, semantic memory, tool calling, or an Agent loop.
- FitLog estimates are for personal tracking and are not medical advice.

## Code References

- `lib/domain/services/daily_summary_service.dart`
- `lib/domain/services/macro_target_calculator.dart`
- `lib/domain/services/workout_calorie_calculator.dart`
- `lib/domain/services/training_frequency_self_check_service.dart`
- `lib/domain/services/diet_plan_strategy_service.dart`
- `lib/domain/services/carb_cycling_calculator.dart`
- `lib/domain/services/carb_taper_review_service.dart`
- `lib/domain/services/nutrition_calculator.dart`
- `lib/domain/models/daily_summary.dart`
- `lib/domain/models/user_profile.dart`
- `lib/domain/models/diet_adjustment_review.dart`
- `test/macro_target_calculator_test.dart`
- `test/workout_calorie_calculator_test.dart`
