# Algorithm.md

## 1. 算法依赖的用户数据

| 字段 | 含义 | 来源 | 是否必需 | 代码位置 |
| -- | -- | -- | -- | -- |
| `age` | 年龄；用于 BMR 和未成年人保护 | Profile 输入或默认值 | 是 | `UserProfile.age`、`ProfilePage` |
| `height_cm` | 身高 cm；用于 BMR | Profile 输入或默认值 | 是 | `UserProfile.heightCm` |
| `weight_kg` | 体重 kg；用于 BMR、g/kg 宏量目标、运动消耗 | Profile 输入或默认值；保存资料时写入体重日志 | 是 | `UserProfile.weightKg`、`ProfileRepository.saveProfile` |
| `sex_for_formula` | `male` / `female` / `prefer_not_to_say`；用于 BMR 与 g/kg 系数 | Profile 下拉 | 是 | `AppConstants.sexOptions`、`DailySummaryService.calculateBmr` |
| `activity_level` | 非专项训练日常活动水平 | Profile 下拉；仅 energy_ratio 模式显示 | energy_ratio 需要 | `AppConstants.activityLevels`、`DailySummaryService.defaultLifestyleFactorForActivity` |
| `daily_energy_goal_type` | 当前减脂 MVP 使用 `deficit`；代码保留 `maintenance/surplus` 兼容值，但本轮不设计增肌期算法 | Profile 下拉 | energy_ratio 需要 | `AppConstants.dailyEnergyGoalTypes` |
| `daily_energy_goal_kcal` | 每日热量赤字 kcal | Profile 输入 | energy_ratio 需要 | `UserProfile.dailyEnergyGoalKcal` |
| `protein_ratio_percent` | 蛋白质热量比例 | Profile 输入 | energy_ratio 需要 | `MacroTargetCalculator.calculateByEnergyRatio` |
| `carbs_ratio_percent` | 碳水热量比例 | Profile 输入 | energy_ratio 需要 | `MacroTargetCalculator.calculateByEnergyRatio` |
| `fat_ratio_percent` | 脂肪热量比例 | Profile 输入 | energy_ratio 需要 | `MacroTargetCalculator.calculateByEnergyRatio` |
| `diet_calculation_mode` | `energy_ratio` 或 `gram_per_kg` | Profile 下拉 | 是 | `AppConstants.dietCalculationModes`、`DailySummaryService` |
| `training_frequency_per_week` | 每周训练频率粗略档位 2/3/4/5；仅用于减脂 g/kg 系数，不代表真实训练强度、训练年限、训练容量或竞技表现需求 | Profile 下拉 | gram_per_kg 需要 | `MacroTargetCalculator.calculateByGramPerKg` |
| `macro_self_check_period_days` | g/kg 自检观察周期 7/14/21/28 天 | Profile 下拉 | 自检需要 | `TrainingFrequencySelfCheckService.evaluate` |
| `macro_self_check_enabled` | 是否启用训练频率自检提醒 | Profile 开关 | 自检需要 | `UserProfile.macroSelfCheckEnabled` |
| `food_records.*` | 每餐热量、P/C/F、日期 | 饮食录入 | 汇总需要 | `FoodRecord`、`FoodRepository.getFoodRecordsByDate` |
| `workout_sessions.*` | 训练类型、动作、时长、估算消耗、日期 | 训练录入 | 运动消耗需要 | `WorkoutSession`、`WorkoutRepository.getWorkoutSessionsByDate` |
| `workout_sets.*` | 力量训练重量、次数、完成状态 | 训练录入 | 力量消耗需要 | `WorkoutSet`、`WorkoutCalorieCalculator` |
| `user_weight_logs.*` | 日期体重历史 | 保存 Profile 时自动 upsert | 动态校准需要 | `WeightLog`、`ProfileRepository.upsertWeightLog` |
| `calorie_calibration_state.*` | 已校准活动系数、置信度、窗口 | 动态校准写入 | TDEE 参考可用 | `CalorieCalibrationState` |

## 2. BMR / RMR 计算

当前代码中存在 BMR/RMR 估算，位于 `DailySummaryService.calculateBmr`。

| 性别字段 | 公式 | 输出 |
| -- | -- | -- |
| `male` | `10 * weightKg + 6.25 * heightCm - 5 * age + 5` | kcal/day |
| `female` | `10 * weightKg + 6.25 * heightCm - 5 * age - 161` | kcal/day |
| `prefer_not_to_say` | 男性公式结果与女性公式结果的平均值 | kcal/day |

输入单位：体重 kg、身高 cm、年龄 years。代码未单独命名 RMR，但 README 将 BMR/RMR 作为同一基础代谢估算口径描述。

## 3. TDEE / 活动系数计算

当前代码计算的是“不含专项训练的日常活动基线”：`baselineNoExerciseTdee = bmr * lifestyleFactorUsed`。

活动系数来源优先级：

1. 若存在 `calorie_calibration_state.lifestyle_factor` 且大于 0，使用校准系数：`ProfilePage._currentLifestyleFactor`、`DailySummaryService._resolveCalibration`。
2. 否则根据 `activity_level` 使用默认非运动活动系数。

| activity_level | 当前代码默认 multiplier | 代码位置 |
| -- | -- | -- |
| `sedentary` | `1.20` | `DailySummaryService._defaultNoExerciseLifestyleFactor` |
| `lightly_active` | `1.30` | 同上 |
| `moderately_active` | `1.425` | 同上 |
| `very_active` | `1.60` | 同上 |

README 中仍保留旧 TDEE 档位示例 `1.2 / 1.375 / 1.55 / 1.725`；当前源码确认的计算值以上表为准。

## 4. 每日目标热量计算

当前每日目标热量由 `DailySummaryService.getSummaryForDate` 计算。

### energy_ratio 模式（热量赤字算法）

```text
bmr = calculateBmr(profile)
lifestyleFactorUsed = calibratedFactor 或 defaultLifestyleFactorForActivity(activity_level)
baselineNoExerciseTdee = bmr * lifestyleFactorUsed

noExerciseTarget = baselineNoExerciseTdee - dailyEnergyGoalKcal

targetIntake = noExerciseTarget + loggedNetExerciseKcal
remainingCalories = targetIntake - caloriesInToday
```

未成年人保护：当 `age < 18` 且目标为 `deficit` 时，代码按 `maintenance` 处理；Profile 页面也会移除 deficit 选项。代码位置：`UserProfile.isMinor`、`UserProfile.copyWith`、`ProfilePage._goalTypeOptions`、`DailySummaryService.getSummaryForDate`。

### gram_per_kg 模式

`gram_per_kg` 模式下，热量目标计数器不是主目标：

```text
targetIntake = 0
remainingCalories = 0
macro targets = calculateByGramPerKg(profile)
```

代码位置：`DailySummaryService.getSummaryForDate`。食物热量仍会汇总为辅助信息：`DailySummary.caloriesIn`。

## 5. 三大营养素目标计算

当前代码存在两套宏量目标算法，位于 `MacroTargetCalculator`。

### energy_ratio 模式

算法先归一化用户输入的三大营养素比例，再按热量目标换算克数。

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

若比例总和小于等于 0，Calculator fallback 为 30% / 40% / 30%；但 Profile 保存时要求三项合计等于 100%。代码位置：`MacroTargetCalculator._resolveMacroRatio`、`ProfilePage._save`。

### gram_per_kg 模式

算法按体重和 `(sex_for_formula, training_frequency_per_week)` 查减脂 MVP 默认表计算。
`training_frequency_per_week` 只是粗略训练频率档位，不代表真实训练强度、训练年限、训练容量或竞技表现需求。

| 性别 | 每周训练 | protein g/kg | carbs g/kg | fat g/kg |
| -- | --: | --: | --: | --: |
| male | 2 | 1.4 | 1.5 | 0.8 |
| male | 3 | 1.6 | 1.8 | 0.8 |
| male | 4 | 1.7 | 2.0 | 0.9 |
| male | 5 | 1.8 | 2.2 | 1.0 |
| female | 2 | 1.4 | 1.4 | 1.0 |
| female | 3 | 1.6 | 1.6 | 1.0 |
| female | 4 | 1.7 | 1.7 | 1.1 |
| female | 5 | 1.8 | 1.9 | 1.2 |

`prefer_not_to_say` 使用同频率男女系数平均值。公式：

```text
targetProteinG = weightKg * proteinCoeff
targetCarbsG = weightKg * carbsCoeff
targetFatG = weightKg * fatCoeff
macroEnergyEquivalentKcal = protein*4 + carbs*4 + fat*9
```

当前 local 版已实现减脂 g/kg 体重算法。它不是增肌期表，不是运动表现最大化表，也不是耐力训练补糖表。
`gram_per_kg` 与 `energy_ratio` 是两套互不干涉的减脂期饮食计算方法；g/kg 不使用 BMR、`activity_level`、`daily_energy_goal_kcal`、`loggedNetExerciseKcal` 或 P/C/F 热量比例重算碳水。代码位置：`MacroTargetCalculator.calculateByGramPerKg`。

## 6. 今日摄入汇总

当前摄入汇总由 `DailySummaryService.getSummaryForDate(day)` 完成：

1. `FoodRepository.getFoodRecordsByDate(day)` 按 `food_records.date = ?` 查询。
2. `NutritionCalculator.sumCalories / sumProtein / sumCarbs / sumFat` 对记录求和。
3. 汇总值写入运行时对象 `DailySummary`，不长期存储到 daily summary 表。

```text
caloriesIn = sum(foodRecords.caloriesKcal)
proteinG = sum(foodRecords.proteinG)
carbsG = sum(foodRecords.carbsG)
fatG = sum(foodRecords.fatG)
```

代码位置：`FoodRepository.getFoodRecordsByDate`、`NutritionCalculator`、`DailySummaryService.getSummaryForDate`。

## 7. 剩余量计算

| 剩余量 | 当前公式 | 适用模式 | 代码位置 |
| -- | -- | -- | -- |
| kcal | `targetIntake - caloriesIn` | `energy_ratio` | `DailySummaryService.getSummaryForDate` |
| kcal | `0` | `gram_per_kg`，热量非主计数器 | 同上 |
| protein | `targetProteinG - proteinG` | 两种模式 | 同上 |
| carbs | `targetCarbsG - carbsG` | 两种模式 | 同上 |
| fat | `targetFatG - fatG` | 两种模式 | 同上 |

## 8. 运动 / 训练消耗计算

训练消耗在创建或编辑训练记录时计算，并保存到 `workout_sessions.estimated_calories`。每日汇总直接求和当日已保存的 `estimatedCalories`。

### 有氧净消耗

代码位置：`WorkoutCalorieCalculator.estimateCardioCalories`。

| 动作 | MET |
| -- | --: |
| Walking | 4.3 |
| Running | 8 |
| Cycling | 6 |
| Rowing Machine | 7 |
| Stair Climber | 8 |

```text
netMet = max(0, MET - 1)
netCardioKcal = netMet * 3.5 * bodyWeightKg / 200 * durationMinutes
```

该公式剔除了 1 MET 静息部分，避免与非运动日常活动基线重复计算。

### 力量训练净消耗

代码位置：`WorkoutCalorieCalculator.estimateStrengthCalories`。

核心流程：

1. 优先使用已完成且 reps > 0 的 sets；若没有完成组，则使用所有 reps > 0 的有效组。
2. 自重动作使用 `bodyWeightKg * bodyweightShare + externalLoadKg` 作为有效负荷；非自重动作使用外部负荷。
3. `totalVolumeKg = Σ(effectiveLoadKg * reps)`。
4. 根据动作类别选择力量系数、训练后恢复率、肌肉修复适应率。
5. 根据 reps、相对负荷、动作类别推断强度系数。
6. 时长只进入恢复密度修正，不线性累加热量。

```text
activeLiftingKcal = totalVolumeKg * strengthCoefficient * bodyFactor * intensityFactor
postTrainingRecoveryKcal = activeLiftingKcal * postTrainingRecoveryRate * recoveryDensityModifier
muscleRepairAdaptationKcal = activeLiftingKcal * muscleRepairAdaptationRate
netStrengthKcal = activeLiftingKcal + postTrainingRecoveryKcal + muscleRepairAdaptationKcal
```

动作类别系数：

| 类别 | strengthCoefficient | postTrainingRecoveryRate | muscleRepairAdaptationRate |
| -- | --: | --: | --: |
| upperBodyCompound | 0.013 | 0.28 | 0.12 |
| lowerBodyCompound | 0.019 | 0.34 | 0.16 |
| isolation | 0.0085 | 0.12 | 0.06 |
| fullBodyPowerOrHighDensity | 0.024 | 0.45 | 0.20 |

`bodyFactor = clamp(sqrt(bodyWeightKg / 80), 0.85, 1.15)`；`recoveryDensityModifier = clamp(1 + (densityRatio - 1) * 0.28, 0.85, 1.35)`。

运动消耗会加入 energy_ratio 模式的每日可摄入热量：`targetIntake = noExerciseTarget + loggedNetExerciseKcal`。运动消耗不直接改变 g/kg 宏量目标。

## 9. 历史统计 / 自检 / 复盘算法

### 动态热量校准

当前代码存在本地动态热量校准，位于 `DailySummaryService._resolveCalibration` 和 `_buildCalibrationSample`。

计算规则：

| 项目 | 当前实现 |
| -- | -- |
| 窗口候选 | 28 / 21 / 14 / 7 天，按顺序尝试 |
| 触发间隔 | 同一状态每 7 天最多校准一次 |
| 体重要求 | 窗口内至少 7 条体重记录；首尾 7 天窗口各至少 3 条 |
| 饮食覆盖 | 14 天及以上窗口要求 `ceil(windowDays * 0.75)`，否则至少 6 天；总体至少 7 天 |
| 体重变化 | 起点 7 日均重 vs 终点 7 日均重 |
| 能量换算 | `7700 kcal/kg` |
| 平滑 | `new = old * 0.8 + observed * 0.2` |
| 单次限幅 | `±0.03` |
| 全局范围 | `1.10 - 1.70` |
| 最低置信度 | `0.35` |

```text
observedTotalTdee = avgDailyIntake - weightChangeKg * 7700 / windowDays
observedNoExerciseTdee = observedTotalTdee - avgDailyExercise
observedLifestyleFactor = observedNoExerciseTdee / avgBmr
```

校准结果存储到 `calorie_calibration_state`，用于后续每日目标计算。

### g/kg 训练频率自检

当前代码存在 `gram_per_kg` 模式下的训练频率自检，位于 `TrainingFrequencySelfCheckService.evaluate`。

| 项目 | 当前实现 |
| -- | -- |
| 适用模式 | 仅 `gram_per_kg` |
| 周期 | 7 / 14 / 21 / 28 天 |
| 有效训练日口径 | 按日期去重，不按 session 数 |
| 有效训练日条件 | 有力量 session，或有氧总时长 >= 20 分钟，或当天训练总消耗 >= 80 kcal |
| 推荐频率 | `clamp(round(activeTrainingDays / periodDays * 7), 2, 5)` |
| 提醒冷却 | `last_macro_self_check_at` 距参考日 >= 7 天 |
| 写入方式 | 用户在 Profile 点击应用建议后写入 `training_frequency_per_week` |

### 当前未实现

- 当前未实现 AI 周复盘。
- 当前未实现独立的周报/复盘页面。
- 当前未实现根据 AI 建议自动调整目标。
- 当前未实现根据记录完整度生成自然语言建议。

## 10. 算法边界

- 当前核心营养目标、摄入汇总、运动净消耗、剩余量、动态热量校准和训练频率自检均由本地确定性 Dart 代码完成。
- 当前 local 版核心营养目标、摄入汇总和剩余量计算均由本地确定性代码完成，没有发现 AI / LLM 参与核心计算。
- App 有可复制 Prompt 和 AI JSON 粘贴解析，但它们不构成 App 内 LLM 推理。
- 当前没有自动配餐、自动饮食推荐、AI 自动修改用户目标或向量检索算法。

## 11. Algorithm 层面的 Code References

- `lib/domain/services/daily_summary_service.dart`
- `lib/domain/services/macro_target_calculator.dart`
- `lib/domain/services/workout_calorie_calculator.dart`
- `lib/domain/services/training_frequency_self_check_service.dart`
- `lib/domain/services/nutrition_calculator.dart`
- `lib/domain/models/user_profile.dart`
- `lib/domain/models/daily_summary.dart`
- `lib/domain/models/workout_session.dart`
- `lib/domain/models/workout_set.dart`
- `lib/domain/models/weight_log.dart`
- `lib/domain/models/calorie_calibration_state.dart`
- `lib/data/repositories/food_repository.dart`
- `lib/data/repositories/workout_repository.dart`
- `lib/data/repositories/profile_repository.dart`
- `lib/features/profile/profile_page.dart`
- `lib/features/home/home_page.dart`
- `test/macro_target_calculator_test.dart`
- `test/workout_calorie_calculator_test.dart`
