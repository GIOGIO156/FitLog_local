# 数据库设计

## 存储概览

FitLog Local 将业务数据存储在本地。

| 存储 | 用途 | 远程同步 |
| --- | --- | --- |
| SQLite / `sqflite` | Profile、饮食记录、食物 item、训练 session、训练组、体重日志、校准状态、饮食调整 review。 | 无 |
| SharedPreferences | UI 语言偏好，目前是 `language_code`。 | 无 |
| 本地文件 | App 文档目录中的 XLSX 和 CSV ZIP 导出文件。 | 无 |
| 内存 providers | App services、刷新版本、选中日期、语言状态。 | 无 |

数据库名：`fitlog_local.db`。

当前 SQLite schema version：`8`。

通过 `PRAGMA foreign_keys = ON` 启用外键。

## 迁移策略

迁移必须保持加法式，并保留现有本地数据。

| 版本 | 变化 |
| ---: | --- |
| 1 | 初始 profile、饮食、训练和组表。 |
| 2 | 添加 `workout_sessions.plan_id`。 |
| 3 | 添加 profile 宏量比例字段：`protein_ratio_percent`、`carbs_ratio_percent`、`fat_ratio_percent`。 |
| 4 | 添加 `user_weight_logs` 和 `calorie_calibration_state`。 |
| 5 | 添加 `diet_calculation_mode`、`training_frequency_per_week` 和宏量自检字段。 |
| 6 | 添加 `user_profile.diet_goal_phase TEXT NOT NULL DEFAULT 'cutting'`。 |
| 7 | 添加饮食策略 profile 字段和 `diet_adjustment_reviews`。 |
| 8 | 添加 `workout_sessions.record_name`。 |

兼容规则：

- 不因为当前 schema 改变就合并或重写旧迁移。
- 优先使用加字段/加表，避免破坏式重建。
- 现有用户使用安全兼容默认值，例如 `cutting`、`energy_ratio`、`none`。
- `daily_energy_goal_type` 为兼容继续存储，但 `diet_goal_phase` 是阶段来源。

## 数据表

### `user_profile`

用途：单例用户资料、饮食设置、策略设置和自检设置。Repository 使用 `id = 1`。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY | 单例 profile id。 |
| `age` | INTEGER NOT NULL | BMR 与未成年人保护。 |
| `height_cm` | REAL NOT NULL | BMR。 |
| `weight_kg` | REAL NOT NULL | BMR、g/kg 宏量、运动消耗。 |
| `sex_for_formula` | TEXT NOT NULL | `male`、`female`、`prefer_not_to_say`。 |
| `activity_level` | TEXT NOT NULL | `energy_ratio` 使用的非运动活动档位。 |
| `daily_energy_goal_type` | TEXT NOT NULL | 兼容字段：`maintenance`、`deficit`、`surplus`。 |
| `daily_energy_goal_kcal` | REAL NOT NULL | 根据 `diet_goal_phase` 表示赤字或盈余。 |
| `protein_ratio_percent` | REAL NOT NULL | `energy_ratio` 宏量百分比。 |
| `carbs_ratio_percent` | REAL NOT NULL | `energy_ratio` 宏量百分比。 |
| `fat_ratio_percent` | REAL NOT NULL | `energy_ratio` 宏量百分比。 |
| `diet_goal_phase` | TEXT NOT NULL DEFAULT `cutting` | `cutting` 或 `bulking`；阶段来源。 |
| `diet_calculation_mode` | TEXT NOT NULL DEFAULT `energy_ratio` | `energy_ratio` 或 `gram_per_kg`。 |
| `diet_plan_strategy` | TEXT NOT NULL DEFAULT `none` | `none`、`carb_cycling`、`carb_tapering`。 |
| `carb_cycle_pattern_json` | TEXT | 星期到 high/medium/low 的映射。 |
| `carb_cycle_high_multiplier` | REAL NOT NULL DEFAULT 1.20 | 高碳日倍率。 |
| `carb_cycle_medium_multiplier` | REAL NOT NULL DEFAULT 1.00 | 中碳日倍率。 |
| `carb_cycle_low_multiplier` | REAL NOT NULL DEFAULT 0.80 | 低碳日倍率。 |
| `carb_taper_review_period_days` | INTEGER NOT NULL DEFAULT 14 | 14/21/28/7。 |
| `carb_taper_target_loss_pct_per_week` | REAL NOT NULL DEFAULT 0.50 | 由 app constants clamp。 |
| `carb_taper_step_g` | REAL NOT NULL DEFAULT 10.0 | 5/10/15/20 风格步长。 |
| `carb_taper_current_delta_g` | REAL NOT NULL DEFAULT 0.0 | 累计碳水偏移。 |
| `last_carb_taper_review_at` | TEXT | 上次 taper review 时间/日期。 |
| `training_frequency_per_week` | INTEGER NOT NULL DEFAULT 3 | g/kg 查表档位 2/3/4/5。 |
| `macro_self_check_period_days` | INTEGER NOT NULL DEFAULT 14 | 7/14/21/28。 |
| `macro_self_check_enabled` | INTEGER NOT NULL DEFAULT 1 | bool 以 0/1 存储。 |
| `last_macro_self_check_at` | TEXT | 自检冷却时间/日期。 |
| `created_at` | TEXT NOT NULL | ISO datetime。 |
| `updated_at` | TEXT NOT NULL | ISO datetime。 |

### `food_records`

用途：餐级饮食记录。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | 记录 id。 |
| `date` | TEXT NOT NULL | `yyyy-MM-dd`。 |
| `meal_name` | TEXT NOT NULL | 餐名。 |
| `total_weight_g` | REAL NOT NULL | 总估算重量。 |
| `calories_kcal` | REAL NOT NULL | 餐级 kcal。 |
| `protein_g` | REAL NOT NULL | 蛋白质克数。 |
| `carbs_g` | REAL NOT NULL | 碳水克数。 |
| `fat_g` | REAL NOT NULL | 脂肪克数。 |
| `confidence` | REAL | 外部估算置信度；手动记录通常为空。 |
| `estimation_notes` | TEXT | 外部估算或用户备注。 |
| `source` | TEXT NOT NULL | `ai_paste` 或 `manual`。 |
| `created_at` | TEXT NOT NULL | ISO datetime。 |
| `updated_at` | TEXT NOT NULL | ISO datetime。 |

### `food_items`

用途：餐内 item 行。随父饮食记录级联删除。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | item id。 |
| `food_record_id` | INTEGER NOT NULL | 外键到 `food_records.id`，ON DELETE CASCADE。 |
| `name` | TEXT NOT NULL | 食物 item 名称。 |
| `estimated_weight_g` | REAL NOT NULL | item 估算重量。 |
| `calories_kcal` | REAL NOT NULL | item kcal。 |
| `protein_g` | REAL NOT NULL | 蛋白质克数。 |
| `carbs_g` | REAL NOT NULL | 碳水克数。 |
| `fat_g` | REAL NOT NULL | 脂肪克数。 |
| `notes` | TEXT | 可选 item 备注。 |

### `workout_sessions`

用途：单个已保存训练动作。一条多动作训练记录由多条共享 `plan_id` 的 session 表示。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | session id。 |
| `plan_id` | TEXT | 一条训练记录分组的共享 id。 |
| `record_name` | TEXT | 面向用户的训练记录名称，在同组内重复保存。 |
| `date` | TEXT NOT NULL | `yyyy-MM-dd`。 |
| `body_part` | TEXT NOT NULL | 部位/类别。 |
| `exercise_name` | TEXT NOT NULL | 动作展示名。 |
| `exercise_type` | TEXT NOT NULL | `strength` 或 `cardio`。 |
| `duration_minutes` | INTEGER NOT NULL | 每个动作自己的时长。 |
| `intensity` | TEXT NOT NULL | 当前保存为类似 `medium` 的强度标签。 |
| `estimated_calories` | REAL NOT NULL | 已保存净运动 kcal 估算。 |
| `notes` | TEXT | 可选备注。 |
| `created_at` | TEXT NOT NULL | 时间线/开始时间排序。 |
| `updated_at` | TEXT NOT NULL | ISO datetime。 |

训练记录行为：

- `plan_id` 仍是分组 key。
- 当前没有单独的父级 workout-record 表。
- 编辑已保存记录会以事务替换整个 `plan_id` 分组。
- 摘要时长、消耗、训练量和组数从已持久化 session/set 派生。

### `workout_sets`

用途：力量训练组行。随父训练 session 级联删除。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | set id。 |
| `workout_session_id` | INTEGER NOT NULL | 外键到 `workout_sessions.id`，ON DELETE CASCADE。 |
| `set_number` | INTEGER NOT NULL | 保存后的组顺序。 |
| `weight_kg` | REAL NOT NULL | 外部负荷；自重动作中 `0` 表示纯自重。 |
| `reps` | INTEGER NOT NULL | 次数。 |
| `is_completed` | INTEGER NOT NULL | bool 以 0/1 存储。 |
| `completed_at` | TEXT | 完成时的 ISO datetime。 |

当前保存行为：

- 只持久化已完成力量组。
- 未勾选组在 insert/update 前丢弃。
- 剩余组按 `1..n` 重新编号。
- `is_completed` 为兼容继续存储，但保存后的力量组预期都是已完成组。

### `user_weight_logs`

用途：用于校准和 review 的每日体重历史。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | 体重日志 id。 |
| `date` | TEXT NOT NULL UNIQUE | 每日唯一。 |
| `weight_kg` | REAL NOT NULL | 体重。 |
| `source` | TEXT NOT NULL | 当前由 profile save 写入。 |
| `created_at` | TEXT NOT NULL | ISO datetime。 |
| `updated_at` | TEXT NOT NULL | ISO datetime。 |

### `calorie_calibration_state`

用途：单例动态热量校准状态。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY CHECK (`id = 1`) | 单例行。 |
| `lifestyle_factor` | REAL NOT NULL | 校准后的非运动生活方式系数。 |
| `confidence` | REAL NOT NULL | 0 到 1 置信度。 |
| `window_days` | INTEGER NOT NULL | 7/14/21/28。 |
| `valid_days` | INTEGER NOT NULL | 有效饮食记录天数。 |
| `last_calibrated_date` | TEXT | `yyyy-MM-dd`。 |
| `created_at` | TEXT NOT NULL | ISO datetime。 |
| `updated_at` | TEXT NOT NULL | ISO datetime。 |

### `diet_adjustment_reviews`

用途：本地碳水 taper review 历史和用户决策记录。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | review id。 |
| `review_date` | TEXT NOT NULL | review 日期。 |
| `window_days` | INTEGER NOT NULL | review 窗口。 |
| `diet_goal_phase` | TEXT NOT NULL | review 时的阶段。 |
| `diet_calculation_mode` | TEXT NOT NULL | review 时的模式。 |
| `diet_plan_strategy` | TEXT NOT NULL | review 时的策略。 |
| `start_avg_weight_kg` | REAL | 起点平均体重。 |
| `end_avg_weight_kg` | REAL | 终点平均体重。 |
| `weight_change_kg` | REAL | 终点减起点。 |
| `loss_rate_pct_per_week` | REAL | 滚动趋势。 |
| `target_loss_pct_per_week` | REAL | 用户目标。 |
| `food_log_coverage` | REAL | 覆盖率。 |
| `active_training_days` | INTEGER | 训练稳定性输入。 |
| `suggested_action` | TEXT NOT NULL | `no_data`、`keep`、`decrease_carbs`、`pause_taper`、`increase_carbs_small` 或 `blocked_by_safety_floor`。 |
| `suggested_carb_delta_g` | REAL NOT NULL DEFAULT 0 | 建议变化。 |
| `applied_delta_after_g` | REAL | 接受后的累计偏移。 |
| `confidence` | REAL NOT NULL DEFAULT 0 | review 置信度。 |
| `reason_codes_json` | TEXT | 内部 reason codes。 |
| `user_decision` | TEXT | `pending`、`accepted`、`dismissed` 或 `expired`。 |
| `created_at` | TEXT NOT NULL | ISO datetime。 |
| `updated_at` | TEXT NOT NULL | ISO datetime。 |

## 运行时聚合

`DailySummary` 不是表。它在运行时由 profile、饮食记录、训练记录、校准状态、自检结果和策略结果组装。

派生数据包括：

- 摄入 kcal/蛋白质/碳水/脂肪
- 运动消耗
- BMR 和非运动 TDEE 参考
- `energy_ratio` 的目标摄入和剩余 kcal
- 宏量目标和剩余宏量
- 策略基础目标和最终目标
- 策略 reason codes 和置信度
- 校准元数据
- 自检元数据
- 选中日期饮食和训练记录列表

## 数据流

Profile：

```text
ProfilePage
-> UserProfile
-> ProfileRepository.saveProfile
-> user_profile + user_weight_logs
-> DailySummaryService
-> Home/Profile display
```

Food：

```text
AddFoodPage / PasteAiResultPage / ManualFoodEntryPage
-> FoodRecord + FoodItem
-> FoodRepository
-> food_records + food_items
-> DailySummaryService
-> Home/Food display
```

Workout：

```text
AddWorkoutPage
-> WorkoutCalorieCalculator
-> WorkoutSession + WorkoutSet
-> WorkoutRepository
-> workout_sessions + workout_sets
-> DailySummaryService
-> Home/Workout display
```

Export：

```text
ProfilePage export action
-> XlsxExportService or CsvExportService
-> repositories + DailySummaryService
-> local .xlsx or .zip file
```

## 导出覆盖

导出包含 food records、food items、workout records、workout sets、daily summary、user profile 和 diet adjustment review history。相关位置会包含策略字段、基础/最终目标字段、校准元数据、g/kg 自检字段和 `record_name`。

## 未实现

- 云同步
- 账号系统
- 远程数据库
- 数据导入
- 向量数据库
- embedding 存储
- AI conversation history
- Agent action logs
- semantic memory

## 代码引用

- Database：`lib/data/db/app_database.dart`
- Repositories：`lib/data/repositories/food_repository.dart`, `workout_repository.dart`, `profile_repository.dart`
- Models：`lib/domain/models/*`
- Services：`lib/domain/services/*`
- Export：`lib/export/xlsx_export_service.dart`, `lib/export/csv_export_service.dart`
- App state：`lib/app.dart`, `lib/core/localization/language_controller.dart`
