# FitLog Local

## 2026-06 Workout Record Summary Layout Follow-up

This follow-up refines the saved workout-record summary and exercise cards:

- the summary now uses a wider dedicated volume column so `volume + kg` stay on one line more reliably
- the sets metric is pushed farther right to preserve horizontal space for volume
- collapsed exercise cards keep kcal on the body-part row and keep set count out of the collapsed view
- saved single-exercise strength tables keep the `#` column fixed while shifting the `weight + reps` block to the right

## 2026-06 Workout Record Update

Workout logging now uses the user-facing term `Workout Record` instead of `Workout Plan` for saved entries.

This release adds:

- record naming before save
- a summary header on saved workout records showing total duration, total volume, total sets, and estimated calories
- full record editing after save, using the same page as record creation
- completed-set row highlighting during creation/editing
- completed-only save behavior for strength exercises: unchecked sets are removed before persistence
- read-only post-save exercise detail rows, so saved records no longer use the detail page to toggle set completion

Behavior notes:

- the database still groups one multi-exercise saved record by shared `plan_id`
- each saved session in the same record now also stores the same `record_name`
- total sets are counted as the number of saved strength sets across all exercises in the record
- total volume is calculated as `sum(weight_kg * reps)` across all saved strength sets

Migration note:

- schema v8 adds `workout_sessions.record_name`

## 2026-06 Workout Record UI Refinement

This follow-up keeps the same workout-record data flow while refining the training UI:

- the strength-calorie estimation notice is now shown once in the training-parameters area when at least one strength exercise is selected, instead of repeating under every strength exercise
- workout notes now use their own optional card below training parameters
- the saved workout-record summary gives the total-sets metric more breathing room so it no longer crowds the volume metric
- saved single-exercise strength details now use table-style headers for weight and reps
- set rows now display weight and reps as separate columns, with reps shown as `× reps`
- the workout-record name field no longer suggests a sample naming style
- the workout-record name field spacing inside training parameters has been rebalanced for better visual rhythm
- workout records now preserve the user's exercise selection order instead of falling back to the exercise-library order
- when selecting multiple exercises in one pass, the exercise library now shows selection order as `1 / 2 / 3...`
- the saved workout-record summary now keeps duration, volume, and sets aligned on one row without forcing `kg` onto a second line
- saved exercise cards in `Exercises in this record` now place kcal beside the body-part line and remove the set-count line
- saved single-exercise strength tables now shift the `weight + reps` block to the right while keeping the `#` column fixed

## 2026-06 Cutting Diet Strategy Update

FitLog Local now separates diet setup into three layers:

```text
diet_goal_phase:
  - cutting
  - bulking

diet_calculation_mode:
  - gram_per_kg
  - energy_ratio

diet_plan_strategy:
  - none
  - carb_cycling
  - carb_tapering
```

The first two layers keep their current responsibilities:

- `gram_per_kg` still uses bodyweight, sex, and training-frequency table lookup only. kcal remains auxiliary analysis.
- `energy_ratio` still uses BMR, non-exercise lifestyle factor, `daily_energy_goal_kcal`, logged net exercise, and macro ratios.

The new strategy layer only adjusts the final displayed daily target after the base target is calculated:

- `carb_cycling`: redistributes weekly carbs across high / medium / low days while keeping weekly average carbs normalized.
- `carb_tapering`: runs a local deterministic review of rolling weight trend, food-log coverage, and training stability, then suggests whether to reduce average carbs. It never auto-applies changes.

Release boundaries:

- This round supports `cutting` only. `bulking` hides these strategy settings for now.
- This is a deterministic local algorithm update, not an Agent / LLM / API feature.
- No backend, no cloud sync, no OpenAI/Gemini API, no RAG, no vector database.
- Under-18 protection remains active: users under 18 cannot enable cutting deficit, carb cycling, or carb tapering.

## 2026-06 Diet Goal Phase Update

FitLog Local now separates diet setup into two dimensions:

```text
diet_goal_phase:
  - cutting
  - bulking

diet_calculation_mode:
  - gram_per_kg
  - energy_ratio
```

This creates four combinations: `cutting + gram_per_kg`, `cutting + energy_ratio`, `bulking + gram_per_kg`, and `bulking + energy_ratio`.

The two calculation modes stay independent. `gram_per_kg` uses bodyweight, sex, and training-frequency table lookup only. It does not use BMR, activity level, daily deficit/surplus, logged exercise calories, or macro-ratio percentages. `energy_ratio` uses BMR, non-exercise lifestyle factor, `daily_energy_goal_kcal`, logged net exercise, and macro ratios.

Phase semantics:

- cutting + g/kg: uses the cutting lower-carb g/kg table.
- bulking + g/kg: uses the bulking higher-carb g/kg table.
- cutting + energy_ratio: `daily_energy_goal_kcal` means daily calorie deficit.
- bulking + energy_ratio: `daily_energy_goal_kcal` means daily calorie surplus.
- In g/kg mode, `macro_energy_equivalent_kcal = protein*4 + carbs*4 + fat*9` is auxiliary analysis/export data, not the calorie target counter.

Database note: schema v6 adds `user_profile.diet_goal_phase` with default `cutting` for existing local users.

FitLog Local 是一款 local-first 的个人饮食与训练记录 App。它的重点不是在 App 内做 AI 推理，而是把复杂食物估算、每日记录、目标与剩余量查看、饮食策略执行与复盘，组织成一个可长期使用的本地数据工作流。

## 这个 App 解决什么问题？怎么解决？
**解决的问题**  
FitLog Local 解决的不只是“记一顿饭”这件事，而是三个经常被低估的高学习成本问题：

1. 现实食物本身就很难估算营养。很多人吃的不是有包装标签的标准食品，而是外卖、食堂、混合菜、汤粉面、便当、非包装食物，或者只吃了一部分、去皮、剩余、份量不确定的餐食，单靠手工很难估出真实 kcal 和 protein / carbs / fat。
2. AI 估算结果很难沉淀成长线记录。很多人会把复杂餐食先交给外部多模态大模型估算，但如果结果只留在聊天记录里，后续复盘、按天汇总和长期追踪都很麻烦。
3. 剩余量和饮食计划都不容易直接转成行动。即使用户已经看到当天剩余 kcal、protein、carbs、fat，也不一定马上知道下一餐应该往哪个方向调；而 cutting / bulking、`energy_ratio`、`gram_per_kg`、`carb_cycling`、`carb_tapering` 这些方法本身也有不低的理解和执行门槛。

**解决方式**  
FitLog Local 把“外部 AI 辅助估算”和“本地结构化追踪”串成一个完整流程：
1. 用户可在任意外部多模态大模型中上传食物照片或描述餐食，按 Prompt 拿到结构化 JSON。
2. 把 JSON 粘贴进 App，一键解析、预览、可手动修正。
3. 保存到手机本地 SQLite，按天汇总饮食 + 运动。
4. App 本地计算每日目标、已摄入、剩余 kcal / protein / carbs / fat，帮助用户理解当天还剩多少空间、当前缺口主要在哪。
5. App 用本地确定性算法承载饮食策略层，让 `energy_ratio`、`gram_per_kg`、`carb_cycling`、`carb_tapering` 这些方法变成可设置、可展示、可复盘的规则，而不是只停留在概念。
6. 随时导出 XLSX / CSV（zip）。

它的定位不是在 App 内做 AI 推理，也不是自动替用户决定下一餐吃什么。Local 版当前提供的是可保存、可修正、可追踪的数据工作流，以及目标与剩余量的结构化依据；不内置 OpenAI / Gemini API，不自动配餐，不自动修改目标。

简单说就是：  
**外部多模态大模型负责“看图或看描述估算食物”**，  
**FitLog Local 负责“把结果落成可修正、可统计、可复盘、可导出的本地记录”。**

---

## 项目定位
- 个人/朋友使用的本地记录工具（MVP 阶段）
- 不商业化、不依赖后端
- 不需要注册登录
- 所有数据仅保存在本机
- 不内置多模态模型，不接入云端 AI API

---

## 功能概览

### 1) Food Log（饮食记录）
- `Paste AI Result`：粘贴 JSON，解析失败会给友好错误提示。
- `Manual Entry`：手动录入餐食和营养值。
- `Photo AI Analysis`：预留占位（Coming soon）。
- 食物记录支持：
  - 列表展示（日期、热量、重量、三大营养素、来源）
  - 详情查看与编辑
  - 删除确认

### 2) AI Prompt 模板与双语提示
- App 内可一键复制 AI Prompt（中/英文随语言切换）。
- Add Food 与 Paste 页面会显示推荐 Prompt，也提供现成 GPT 文案入口。
- 即使粘贴的是不同语言 JSON，记录仍可互通（解析层兼容中英文字段别名）。

### 3) Workout Log（训练记录）
- 支持一次创建**多动作训练计划**（同一次保存归为一个计划块）。
- 支持按肌群筛选、搜索动作、动作预选。
- 力量动作可设置多组：重量、次数、完成勾选。
- 保存前即可勾选已完成组；保存后在详情页可继续打卡。
- 有氧动作不需要组数计划。
- 训练列表按计划聚合显示：开始时间、总时长、总消耗、动作名列表。

### 4) Home / Daily Dashboard（每日看板）
- 今日摄入热量
- 今日运动消耗
- BMR
- TDEE 参考值
- 今日目标摄入
- 剩余热量
- 今日三大营养素（蛋白/碳水/脂肪）
- 今日饮食记录与训练记录列表
- 用结构化的目标 / 已摄入 / 剩余量展示，降低用户自己判断下一餐方向的成本，但当前版本不自动配餐

### 5) Profile & Settings（资料与设置）
- 身体资料与目标管理
- 中英文切换
- 激进热量缺口提醒（deficit > 700）
- 未成年人目标保护（<18 禁止 deficit）
- 数据导出与一键清空本地数据（二次确认）

---

## 你可以直接使用的 GPT
- 英文助手：[FitLog Food Estimator](https://chatgpt.com/g/g-69ebda4e37308191add32b105a6a183e-fitlog-estimator)
- 中文助手：[FitLog 中文助手](https://chatgpt.com/g/g-69ebe98d5cec819181a79003f6298695-fitlog-zhong-wen-zhu-shou)

说明：
- 以上 GPT 只是现成可用的 ChatGPT 入口，不是唯一支持方式。
- 你也可以不用以上 GPT，直接在 App 里复制内置 Prompt 到任意支持图像或文本理解的外部多模态大模型。
- 本 App 不接入任何真实 AI API，只做本地记录和计算。

---

## 技术栈
- Flutter + Dart
- SQLite（`sqflite`）
- 状态管理：`provider`
- 导出：
  - XLSX：`excel`
  - CSV + ZIP：`csv` + `archive`
- 本地配置：`shared_preferences`

---

## 目录结构

```text
lib/
  main.dart
  app.dart
  core/
    constants/
    localization/
    utils/
    widgets/
  data/
    db/
    repositories/
  domain/
    models/
    services/
  export/
  features/
    home/
    food/
    workout/
    profile/
```

---

## 本地数据库（SQLite）

### `user_profile`
- `id`, `age`, `height_cm`, `weight_kg`
- `sex_for_formula`, `activity_level`
- `daily_energy_goal_type`, `daily_energy_goal_kcal`
- `created_at`, `updated_at`

### `food_records`
- `id`, `date`, `meal_name`
- `total_weight_g`, `calories_kcal`
- `protein_g`, `carbs_g`, `fat_g`
- `confidence`, `estimation_notes`, `source`
- `created_at`, `updated_at`

### `food_items`
- `id`, `food_record_id`, `name`
- `estimated_weight_g`, `calories_kcal`
- `protein_g`, `carbs_g`, `fat_g`, `notes`

### `workout_sessions`
- `id`, `plan_id`, `date`
- `body_part`, `exercise_name`, `exercise_type`
- `duration_minutes`, `intensity`
- `estimated_calories`, `notes`
- `created_at`, `updated_at`

### `workout_sets`
- `id`, `workout_session_id`, `set_number`
- `weight_kg`, `reps`, `is_completed`, `completed_at`

---

## 计算规则

### BMR
- male: `10 * weight + 6.25 * height - 5 * age + 5`
- female: `10 * weight + 6.25 * height - 5 * age - 161`
- prefer_not_to_say: male 与 female 的平均值

### TDEE 参考
- sedentary: `1.2`
- lightly_active: `1.375`
- moderately_active: `1.55`
- very_active: `1.725`
- `tdee = bmr * multiplier`

### 今日消耗与目标（新版）
- `baseline_no_exercise_tdee = bmr * lifestyle_factor_non_exercise`
- `no_exercise_target = baseline_no_exercise_tdee - daily_energy_goal_kcal`（减脂赤字口径）
- `final_food_target = no_exercise_target + logged_net_exercise_kcal`
- `remaining_calories = final_food_target - calories_in_today`
- `lifestyle_factor_non_exercise` 只代表非专项训练活动（通勤、站立、家务、体力工作等）。

### 运动消耗估算（净额外消耗）
- Cardio（净 MET）：
  - `net_cardio_kcal = (MET - 1) * 3.5 * body_weight_kg / 200 * duration_minutes`
- Strength（训练量主导）：
  - `total_volume_kg = Σ(weight_kg * reps)`
  - `active_lifting_kcal = total_volume_kg * strength_coefficient * body_factor * intensity_factor`
  - `net_strength_kcal = active_lifting_kcal + post_training_recovery_kcal + muscle_repair_adaptation_kcal`
- 力量训练总时长只用于恢复部分的小幅封顶修正，不做线性累加。
- 原因：每日基线已包含静息代谢，运动模块只加“额外净消耗”，避免重复计入。

---

## 导出说明

### XLSX
文件名：`fitlog_local_YYYY_MM_DD.xlsx`  
包含 6 个 sheet：
1. Food Records
2. Food Items
3. Workout Records
4. Workout Sets
5. Daily Summary
6. User Profile

### CSV
文件名：`fitlog_local_YYYY_MM_DD.zip`  
包含：
- `food_records.csv`
- `food_items.csv`
- `workout_records.csv`
- `workout_sets.csv`
- `daily_summary.csv`
- `user_profile.csv`

导出文件保存到 App 文档目录（系统私有本地路径）。

---

## 快速开始（Android 优先）

### 环境要求
- Flutter 3.x
- Dart 3.x
- Android Studio / VS Code
- Android 模拟器或真机

### 运行
```bash
flutter pub get
flutter run
```

### 常用检查
```bash
flutter analyze
flutter test
```

### 构建 Debug APK
```bash
flutter build apk --debug
```

---

## 推荐使用流程（食物记录）
1. 打开任意你想用的外部多模态大模型。
2. 上传/拍摄食物照片。
3. 使用你自己的 FitLog GPT，或先从 App 复制 Prompt。
4. 获取标准 JSON 输出。
5. 回到 App -> Add Food -> Paste AI Result。
6. 预览并修正后保存。

---

## 隐私与边界
- 本应用不提供医疗建议。
- 营养数据均为估算值，仅用于个人记录与管理参考。
- 所有数据默认仅保存在本地 SQLite，不上传云端。

---

## 当前阶段
当前版本仍是 local MVP。它的核心目标是把外部 AI 食物估算结果落地为本地记录，并把饮食目标、已摄入、剩余量和计划策略用可理解的方式展示出来：  
低摩擦录入、按天汇总、训练联动、本地可导出、可复盘。

当前版本不包含 App 内 AI API、不自动配餐、不提供 Meal Decision Agent、不自动生成饮食计划，也不自动替用户调整目标。`Photo AI Analysis` 仍然只是 Coming soon 占位入口。

---

## 2026-05 动态热量目标校准（新版）

### 核心原则
- 先算“不运动时的一天基线消耗”，再把“当天已记录的净运动消耗”加上去。
- 不再用“每周计划训练几天”去抬高默认活动系数，避免计划未执行时目标偏高。
- 所有运动都只计“净额外消耗”，不重复计入静息代谢。

### 1) 每日基线与目标
- `BMR/RMR` 由年龄、身高、体重、性别估算。
- `baseline_no_exercise_tdee = BMR * lifestyle_factor_non_exercise`
- `no_exercise_target = baseline_no_exercise_tdee - daily_energy_goal_kcal`
- `final_food_target = no_exercise_target + logged_net_exercise_kcal`

说明：这里的 `lifestyle_factor` 只代表非专项训练的日常活动（通勤、站立、家务、工作体力等）。

### 2) 有氧与力量的净消耗口径
- 有氧（步行/跑步/骑行/楼梯机等）按净 MET：
  - `net_cardio_kcal = (MET - 1) * 3.5 * weight_kg / 200 * duration_min`
- 力量训练按训练量主导：
  - `net_strength_kcal = active_lifting_kcal + post_training_recovery_kcal + muscle_repair_adaptation_kcal`
  - 总时长仅作为“训练密度”的小幅封顶修正，不能线性累加热量。
  - 示例（当前实现）：`recovery_density_modifier = clamp(1 + (density_ratio - 1) * 0.28, 0.85, 1.35)`
  - 其中 `density_ratio = (completed_sets / total_session_minutes) / baseline_density`，仅影响恢复项，不直接按时长加热量。

### 3) 动态校准（每 7 天最多一次）
- 采用 7–28 天滚动窗口（优先更长窗口）。
- 使用 7 日均重的“窗口起点 vs 终点”差值，降低水分波动噪声。
- 估算观测 TDEE：
  - `observed_total_tdee = avg_intake - weight_change_kg * 7700 / days`
  - `observed_no_exercise_tdee = observed_total_tdee - avg_logged_net_exercise`
  - `observed_lifestyle_factor = observed_no_exercise_tdee / avg_bmr`
- 系数平滑更新：
  - `new_factor = old_factor * 0.8 + observed_factor * 0.2`
  - 单次更新限幅 `±0.03`
  - 全局约束 `1.10–1.70`

### 4) 稳定性与安全策略
- 数据不足（饮食日志或体重日志覆盖不足）则跳过校准。
- 遇到异常日不会单日直接改目标；更新使用区间平均与平滑。
- 校准结果带置信度，窗口越长、日志覆盖越好，置信度越高。

---

## 2026-05 Diet Dual-Mode Update (Cut MVP)

This release adds two parallel local diet calculation modes:

1. `energy_ratio`
2. `gram_per_kg`

All logic remains local-only (Flutter + SQLite), no backend and no AI API integration.

### Concept Split

- `activity_level`: non-exercise daily activity level for baseline energy calculations.
- `training_frequency_per_week`: coarse training-frequency tier (2/3/4/5) for g/kg macro table lookup. It does not represent real intensity, training age, volume, or performance demand.

These are different concepts and must not be merged.

### Mode A: `energy_ratio` (deficit algorithm, kept)

- `baseline_no_exercise_tdee = BMR * lifestyle_factor_non_exercise`
- `no_exercise_target = baseline_no_exercise_tdee - daily_energy_goal_kcal`
- `final_food_target = no_exercise_target + logged_net_exercise_kcal`
- Macro targets are converted from kcal target using macro percentages.

### Mode B: `gram_per_kg` (cut MVP default table)

Directly compute cut-phase macro targets from bodyweight and coefficients:

- `protein_target_g = weight_kg * protein_coeff`
- `carbs_target_g = weight_kg * carbs_coeff`
- `fat_target_g = weight_kg * fat_coeff`

Coefficients come from `(sex, training_frequency_per_week)` table.
For `prefer_not_to_say`, use male/female average in the same frequency tier.

Male default table:

| training_frequency_per_week | protein g/kg | carbs g/kg | fat g/kg |
| --: | --: | --: | --: |
| 2 | 1.4 | 1.5 | 0.8 |
| 3 | 1.6 | 1.8 | 0.8 |
| 4 | 1.7 | 2.0 | 0.9 |
| 5 | 1.8 | 2.2 | 1.0 |

Female default table:

| training_frequency_per_week | protein g/kg | carbs g/kg | fat g/kg |
| --: | --: | --: | --: |
| 2 | 1.4 | 1.4 | 1.0 |
| 3 | 1.6 | 1.6 | 1.0 |
| 4 | 1.7 | 1.7 | 1.1 |
| 5 | 1.8 | 1.9 | 1.2 |

This is not a bulking table, a maximum sports-performance table, or an endurance carb-loading table.
It does not mix with the `energy_ratio` deficit calculation and does not use BMR, activity level, daily deficit, logged exercise calories, or macro ratio percentages.

Auxiliary field:

- `macro_energy_equivalent_kcal = protein*4 + carbs*4 + fat*9`

This is for analysis/export only, not the kcal target counter in g/kg mode.

### Home Display Behavior

- `energy_ratio`: kcal target/intake/remaining + macros.
- `gram_per_kg`: macros are the primary counters; kcal can appear only as auxiliary intake info.

### g/kg Training-Frequency Self-check (new)

Profile fields:

- `macro_self_check_enabled`
- `macro_self_check_period_days` (7/14/21/28)
- `last_macro_self_check_at`

Self-check works only in `gram_per_kg` mode and is intentionally isolated from dynamic calorie calibration.

`activeTrainingDays` counts distinct valid training dates (not session count):

A day is valid if any condition is true:

1. has at least one strength session
2. cardio total duration >= 20 minutes
3. daily total estimated exercise kcal >= 80

Frequency recommendation:

- `averageWeeklyTrainingFrequency = activeTrainingDays / periodDays * 7`
- `recommended = clamp(round(averageWeeklyTrainingFrequency), 2, 5)`

### Boundary with dynamic calorie calibration

The new g/kg self-check:

- does **not** update `lifestyle_factor_non_exercise`
- does **not** use weight-change 7700 kcal/kg equations
- does **not** use observed TDEE EWMA updates

Dynamic calorie calibration and g/kg self-check are independent systems.

## 2026-05 饮食算法双模式（中文精简版）

本版新增两套并列算法：

1. `energy_ratio`（能量百分比）
2. `gram_per_kg`（按体重 g/kg）

### 核心区别

- `activity_level`：日常非专项活动水平，用于基础能量计算。
- `training_frequency_per_week`：每周训练频率粗略档位（2/3/4/5），只用于 g/kg 查表；不代表真实训练强度、训练年限、训练容量或竞技表现需求。

### energy_ratio（热量赤字算法）

- 先算不运动日基线：`BMR * lifestyle_factor_non_exercise`
- 再减去每日热量赤字：`daily_energy_goal_kcal`
- 再加当天已记录净运动消耗
- 最后用宏量营养素百分比换算每日蛋白/碳水/脂肪目标克数

### gram_per_kg（减脂 MVP 默认表）

直接按体重和查表系数算减脂期三大营养素目标：

- 蛋白质 = 体重 * 蛋白系数
- 碳水 = 体重 * 碳水系数
- 脂肪 = 体重 * 脂肪系数

新版 male 表：

| 每周训练频率档位 | protein g/kg | carbs g/kg | fat g/kg |
| --: | --: | --: | --: |
| 2 | 1.4 | 1.5 | 0.8 |
| 3 | 1.6 | 1.8 | 0.8 |
| 4 | 1.7 | 2.0 | 0.9 |
| 5 | 1.8 | 2.2 | 1.0 |

新版 female 表：

| 每周训练频率档位 | protein g/kg | carbs g/kg | fat g/kg |
| --: | --: | --: | --: |
| 2 | 1.4 | 1.4 | 1.0 |
| 3 | 1.6 | 1.6 | 1.0 |
| 4 | 1.7 | 1.7 | 1.1 |
| 5 | 1.8 | 1.9 | 1.2 |

`prefer_not_to_say` 使用男女同档位平均值。
这不是增肌期表，不是运动表现最大化表，也不是耐力训练补糖表。
`gram_per_kg` 与 `energy_ratio` 是两套互不干涉的减脂期饮食计算方法。

---

## 2026-05-31 Update

### 1) Workout set input overwrite UX fix
- Historical set values are still shown as muted defaults for quick reuse.
- Tapping a default value now reliably selects the full value before editing.
- Typing a new number replaces old value directly (no middle-cursor insertion issue such as `60 -> 6650`).

### 2) Food record copy action
- Added a copy button on each food record card in Food Log.
- One tap duplicates a record into the currently selected date.
- Copied fields include:
  - meal name
  - calories/weight/macros
  - confidence/source/notes
  - item rows (if any)
- Copy creates a new local record (new ID), preserving original history.

---

## 2026-06-01 Update

### 1) Workout logging UI compactness refresh
- The strength set area was reworked to be denser and less bloated.
- Main direction:
  - reduce nested-card visual heaviness
  - keep high information density for many sets
  - improve decimal visibility (e.g. `42.5`)
- Practical changes:
  - compact table-like row layout for sets (`# / Previous / Weight / Reps / Actions`)
  - denser input fields (smaller padding, tighter border radius, compact style)
  - smaller action button footprint for check/remove
  - previous-set summary shown inline (`weight x reps`)

### 2) Food record copy now supports target-date selection
- Copy action no longer forces same-day duplication.
- Tapping copy opens a date picker first.
- The selected date is used as the duplication target.
- Copied data still includes:
  - meal name
  - calories/weight/macros
  - confidence/source/notes
  - item rows (if any)

---

## 2026-06-01 UI Iteration (Readability-first)

### 1) Workout set table simplified again
- Removed the `Previous` column from set entry rows.
- Purpose:
  - return horizontal space to the actual editable fields (`Weight` / `Reps`)
  - prevent the main training data from becoming visually compressed.

### 2) Less boxed, less crowded set-entry visuals
- Reworked set rows to reduce heavy nested/boxed input visuals:
  - removed per-cell rounded capsule/border style
  - used lighter borderless numeric entry for weight/reps
  - retained row-level structure with subtle separators for scanning.

### 3) UX direction
- Goal is not "larger gaps", but:
  - high information density
  - clear numbers at first glance
  - reduced visual clutter from repeated small rectangles.

系数由“性别 + 每周训练频率档位”查减脂 MVP 默认表得到。
`prefer_not_to_say` 使用男女同档位平均值。
训练频率只作为粗略档位，不代表真实训练强度、训练年限、训练容量或竞技表现需求。

### 首页展示规则

- energy_ratio：显示 kcal 目标/已摄入/剩余。
- gram_per_kg：以三大营养素克数为主，不显示“剩余 kcal 目标计数器”。
  可显示“今日已摄入 kcal”作为辅助信息。

### g/kg 训练频率自检

- 只在 g/kg 模式运行。
- activeTrainingDays 按“有效训练日期去重”统计，不按 session 条数统计。
- 有效训练日判定（满足其一）：
  1. 当天有力量训练
  2. 当天有氧总时长 >= 20 分钟
  3. 当天估算消耗总和 >= 80 kcal
- 推荐频率：
  - `averageWeekly = activeDays / periodDays * 7`
  - `recommended = clamp(round(averageWeekly), 2, 5)`

### 与动态热量校准的边界

g/kg 自检不会参与原有动态热量校准：

- 不改 lifestyle_factor_non_exercise
- 不用 7700 kcal/kg 体重变化公式
- 不用 observed TDEE / EWMA 校准流程

两套机制相互独立。
