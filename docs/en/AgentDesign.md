# Agent Boundary

## Current Status

FitLog Local currently has no app-internal AI, LLM, or Agent execution capability.

The app does not currently implement:

- OpenAI, Gemini, ChatGPT, or other LLM API calls
- LLM SDK usage
- embeddings
- vector database
- RAG
- function calling or tool calling
- Agent loop
- AI conversation memory
- Agent action logs

Current AI-adjacent features are static or user-mediated:

| Feature | What happens | App-internal AI? | Main code |
| --- | --- | --- | --- |
| Prompt copy | The app copies a language-matched, one-time conversation initializer from the `AI-assisted Entry` workspace. The copied prompt can be pasted into any external AI that supports food images or text. In the external conversation, a new food image normally starts a new meal and follow-up edits update the latest meal, always as complete JSON in the unchanged schema. | No | `PromptTemplates`, `PasteAiResultPage._copyPrompt` |
| External AI JSON paste | The user manually pastes JSON produced outside the app into the same `AI-assisted Entry` workspace. The page shows nested reusable-chat instructions with three one-line usage actions and a recommended GPT note, a fixed JSON editor with paint-only target keyboard lift, fullscreen editing, and local parsing only. | No | `PasteAiResultPage`, `NutritionCalculator.parseAiFoodJson` |
| `source = ai_paste` | Saved records can mark that their source was an AI paste workflow. | No | `AppConstants.sourceAiPaste`, `FoodRecord.source` |

## Deterministic Local Workflows

The app has local workflows that may feel automated, but they are deterministic Dart/database flows, not Agents.

| Workflow | Input | Output | AI used inside app? |
| --- | --- | --- | --- |
| Prompt language selection | Current UI language | Chinese or English prompt text | No |
| JSON parsing | User-pasted JSON string | `FoodRecord` and `FoodItem` data | No |
| Food save | Food record and items | SQLite rows | No |
| Food summary | Selected date records | Daily kcal/protein/carbs/fat totals | No |
| Custom exercise save | User-entered exercise metadata | Local reusable exercise definition | No |
| Workout exercise normalization | Exercise metadata, set input, duration, bodyweight | Saved raw input and normalized calculation values | No |
| Workout summary | Selected date sessions | Daily net exercise kcal | No |
| BMR and target calculation | Profile, food, workout, calibration state | Daily target and remaining values | No |
| Macro target calculation | Diet phase and calculation mode | Protein/carbs/fat targets | No |
| Dynamic calibration | Food history and weight logs | Calibrated lifestyle factor | No |
| Training-frequency self-check | Workout history | Suggested shared training-frequency setting | No |
| Diet strategy review | Weight trend, food coverage, training stability | Local strategy result or review suggestion | No |
| Export | SQLite records and runtime summaries | XLSX or CSV ZIP | No |
| Clear local data | User confirmation | Local table deletion | No |

## Agent Boundary Rules

- Any image/text-capable external AI may help estimate food before data enters FitLog Local; provider-specific suggestions are optional, not required by the app workflow.
- Any continuity created by the copied prompt exists only in the external conversation. FitLog Local does not store that conversation or provide AI memory.
- FitLog Local only stores, parses, summarizes, calculates, reviews, and exports local data.
- Prompt templates are not app-internal AI.
- JSON parsing is not app-internal AI.
- `carb_tapering` is a deterministic local review flow, not an Agent that changes goals by itself.
- Custom exercise creation, cardio-intensity selection, and workout-set normalization are deterministic local UI/database/calculator flows, not AI classification.
- The app must not introduce backend, cloud sync, LLM API, vector database, RAG, tool calling, semantic memory, or Agent loop unless explicitly requested.
- If a future Agent layer is added, it must be documented separately from current local deterministic algorithms.

## Current Non-goals

FitLog Local does not currently provide:

- Meal Decision Agent
- Weekly Review Agent
- Goal Review Agent
- AI Coach
- automatic meal plans
- automatic target updates
- automatic carb taper application
- app-internal photo recognition API
- semantic memory
- vector search
- RAG
- tool calling
- multi-step Agent loop

## Code References

- Prompt templates: `lib/core/constants/prompt_templates.dart`
- AI-adjacent food entry: `lib/features/food/add_food_page.dart`, `lib/features/food/paste_ai_result_page.dart`
- JSON parser: `lib/domain/services/nutrition_calculator.dart`
- Source marker: `AppConstants.sourceAiPaste` in `lib/core/constants/app_constants.dart`
- Local deterministic services: `daily_summary_service.dart`, `macro_target_calculator.dart`, `workout_calorie_calculator.dart`, `training_frequency_self_check_service.dart`, `diet_plan_strategy_service.dart`, `carb_cycling_calculator.dart`, `carb_taper_review_service.dart`
- Exercise metadata: `lib/core/constants/exercise_catalog.dart`, `lib/core/constants/exercise_definition.dart`, `lib/data/repositories/custom_exercise_repository.dart`
- Dependency check: `pubspec.yaml`
