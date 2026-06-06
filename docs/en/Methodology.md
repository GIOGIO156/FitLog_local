# Methodology

## Purpose

This document explains why FitLog Local uses its current diet, carb strategy, and exercise calorie methods. It is written for users who want to understand the reasoning behind the app before trusting the numbers.

FitLog is a tracking and estimation tool. It does not provide medical advice, diagnose conditions, prescribe diets, or replace a qualified professional.

## The Core Idea

FitLog separates three things that are often mixed together:

1. Goal phase: whether the user is cutting or bulking.
2. Base calculation method: whether daily targets are kcal-primary or macro-primary.
3. Strategy layer: whether carbs are redistributed or reviewed after the base target is calculated.

This separation matters because different users trust and act on different targets. Some users think in kcal first. Others think in protein/carbs/fat grams first. Mixing both systems into one formula would make the app harder to reason about and easier to misread.

## `energy_ratio`: Kcal-first Planning

`energy_ratio` is for users who want daily kcal target, intake, and remaining kcal to be the primary signal.

It works like this:

```text
BMR estimate
-> non-exercise daily activity baseline
-> cutting deficit or bulking surplus
-> add logged net exercise calories
-> split the final kcal target into protein/carbs/fat by percentage
```

Why this method exists:

- Many diet plans start with energy balance: eat below maintenance for cutting or above maintenance for bulking.
- Macro percentages are easy to understand when the main target is kcal.
- Logged exercise can be added back as extra available intake because the baseline is intentionally a no-exercise daily baseline.

What users should know:

- `diet_goal_phase = cutting` means `daily_energy_goal_kcal` is treated as a deficit.
- `diet_goal_phase = bulking` means `daily_energy_goal_kcal` is treated as a surplus.
- In this mode, kcal target/intake/remaining is the main counter.
- Macro grams are derived from the kcal target and macro percentages.
- BMR and activity factors are estimates, not exact measurements.

Main evidence context:

- BMR/RMR estimate: `REF-ALG-01`, `REF-ALG-02`.
- Macro energy conversion: `REF-ALG-03`.
- Percentage-of-energy macro framing: `REF-ALG-04`.

See [References](References.md) for source details and boundaries.

## `gram_per_kg`: Macro-first Planning

`gram_per_kg` is for users who want protein, carbs, and fat grams to be the primary target.

It works like this:

```text
bodyweight
-> goal phase
-> sex option
-> coarse training-frequency tier
-> protein/carbs/fat g/kg table
-> macro gram targets
```

Why this method exists:

- Many training-oriented users think of protein, carbs, and fat in grams per kg of bodyweight.
- Protein and carbohydrate needs often scale more naturally with body size and training context than with a single kcal number.
- A macro-first display can be easier to act on when the user cares about hitting protein/carbs/fat targets directly.

What users should know:

- `gram_per_kg` does not use BMR, activity level, daily deficit/surplus, logged exercise calories, or macro percentages.
- `training_frequency_per_week` is only a coarse lookup tier: 2, 3, 4, or 5 days per week.
- That tier is not a claim about intensity, training age, total volume, or performance demand.
- `prefer_not_to_say` uses the same-tier male/female average.
- In this mode, macro grams are primary.
- Kcal is auxiliary because `protein*4 + carbs*4 + fat*9` is only the energy equivalent of the macro targets. It is not the counter that drives the plan.

Why kcal is auxiliary here:

If FitLog used g/kg macros and then forced those macros back through an independent kcal target, the two systems could fight each other. A user might see macro targets saying one thing and the kcal counter saying another. FitLog avoids that confusion by making macro grams the source of truth in `gram_per_kg`.

Main evidence context:

- Macro energy conversion: `REF-ALG-03`.
- Protein g/kg range and sports nutrition context: `REF-ALG-05`, `REF-ALG-06`.
- Diet and body-composition framing: `REF-ALG-07`.

## Why The Two Diet Modes Must Not Be Mixed

The two modes answer different questions.

`energy_ratio` asks:

```text
Given my kcal target, how many grams of protein/carbs/fat should I eat?
```

`gram_per_kg` asks:

```text
Given my bodyweight and training context, what protein/carbs/fat gram targets should I aim for?
```

Both can be useful, but they should not control the same target at the same time. FitLog keeps them separate so the user always knows which number is primary.

## Carb Cycling

`carb_cycling` is a strategy layer for cutting. It redistributes carbs across the week after the base target is calculated.

It works like this:

```text
base carbs
-> choose high / medium / low days
-> normalize the 7-day multipliers
-> raise carbs on some days and lower them on others
-> keep weekly average carbs controlled
```

Why this method exists:

- Some users prefer more carbs on harder training days and fewer carbs on easier or rest days.
- Carb needs can vary with training demands.
- Weekly normalization helps avoid accidentally turning cycling into hidden overeating or excessive restriction.

What users should know:

- Carb cycling is not a magic fat-loss algorithm.
- It does not create better results by itself if weekly intake and adherence are poor.
- It keeps protein and fat stable while adjusting carbs.
- It applies a safety floor: carbs should not drop below `max(weightKg * 1.2, 100)`.
- If the floor is hit, FitLog clamps the target and records a local reason code.

Main evidence context:

- Periodized carbohydrate availability: `REF-ALG-13`.
- Limits of periodized carb restriction evidence: `REF-ALG-14`.
- Carbohydrate needs vary with training demands: `REF-ALG-15`.

## Carb Tapering

`carb_tapering` is a local review strategy for cutting. It does not auto-diet for the user.

It works like this:

```text
review recent weight trend
-> check food-log coverage
-> check training stability
-> compare current loss rate with target range
-> suggest keep, decrease carbs, pause taper, or no action
-> wait for user confirmation
```

Why this method exists:

- Cutting often needs small adjustments over time.
- Weight can fluctuate from water, food volume, sodium, digestion, and training stress.
- A rolling review is safer than reacting to a single day.
- User confirmation prevents the app from silently tightening the plan.

What users should know:

- FitLog uses a rolling trend, not one weigh-in.
- Food log coverage matters because poor logging makes the trend harder to interpret.
- Training stability matters because a drop in training can make an aggressive carb cut less appropriate.
- Suggested carb changes are small steps, not automatic punishment.
- If the data is weak, the app should say `no_data` instead of pretending to know.
- If loss is too fast, the app can suggest `pause_taper`.
- If carbs would fall below the safety floor, the app blocks the decrease.

Main evidence context:

- Protein preservation during training phases: `REF-ALG-16`.
- Conservative loss-rate framing: `REF-ALG-17`.
- Observed prep macro shifts: `REF-ALG-18`.
- Dynamic weight-change limitations: `REF-ALG-19`.

## Why Exercise Calories Are Net Calories

FitLog adds logged exercise calories to `energy_ratio` intake targets. To avoid double counting, those exercise calories must be net additional exercise calories.

The reason is simple:

The daily baseline already includes the calories the body would have burned at rest during that time. If FitLog added total exercise calories without removing resting burn, it would count the same resting calories twice.

For cardio, FitLog uses:

```text
netMet = max(0, MET - 1)
netCardioKcal = netMet * 3.5 * bodyWeightKg / 200 * durationMinutes
```

Why subtract 1 MET:

- 1 MET roughly represents resting energy cost.
- The no-exercise baseline already includes resting metabolism.
- Subtracting 1 MET estimates only the extra cost of doing the activity instead of resting.

Example:

If an activity is 8 MET, FitLog treats the extra exercise cost as about 7 MET, not 8 MET, because the first 1 MET was already part of baseline daily burn.

Main evidence context:

- MET values and conversion: `REF-ALG-08`, `REF-ALG-09`.

## Why Strength Training Is Not Just Minutes

Strength training is not modeled as simple calories per minute.

Why:

- A 60-minute strength session may include heavy sets, light sets, warmups, and long rests.
- Two sessions with the same duration can have very different loads, reps, and total volume.
- Counting every minute linearly would overvalue rest time and undervalue actual work.

FitLog uses training volume and movement type:

```text
effective load
-> reps
-> total volume
-> movement profile coefficients
-> active lifting cost
-> recovery and adaptation components
```

Duration still matters, but only as a capped recovery-density modifier. It can create a small difference between denser and slower sessions, but it does not linearly add calories.

What users should know:

- Strength calorie estimates are heuristic.
- They are useful for consistency inside FitLog, not lab-grade measurement.
- The app prioritizes avoiding obvious double counting over pretending to know exact exercise burn.

## Why FitLog Uses Boundaries And Confirmation

FitLog intentionally uses local deterministic rules and user confirmation because the data is imperfect.

Important uncertainty sources:

- Meal estimates can be wrong.
- External AI estimates can be wrong.
- Weight changes can reflect water, food volume, sodium, or training stress.
- Exercise calorie estimates are approximate.
- BMR and activity factors are population estimates.

FitLog's response to uncertainty:

- keep calculation modes separate
- use rolling windows instead of single days
- clamp unsafe or extreme values
- keep carb taper user-confirmed
- show strategy reason/context instead of hiding it
- avoid app-internal AI claims unless real AI is implemented

## Where To Read More

- Engineering formulas and implementation boundaries: [Algorithm](Algorithm.md)
- Evidence and source boundaries: [References](References.md)
- Product behavior and UX scope: [Product](Product.md)
- AI/Agent boundary: [Agent](Agent.md)
