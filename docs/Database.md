# Database.md

## 2026-06 Schema v7 Diet Strategy Update

Database version is now `7`.

Additive migration on `user_profile`:

```sql
ALTER TABLE user_profile ADD COLUMN diet_plan_strategy TEXT NOT NULL DEFAULT 'none';
ALTER TABLE user_profile ADD COLUMN carb_cycle_pattern_json TEXT;
ALTER TABLE user_profile ADD COLUMN carb_cycle_high_multiplier REAL NOT NULL DEFAULT 1.20;
ALTER TABLE user_profile ADD COLUMN carb_cycle_medium_multiplier REAL NOT NULL DEFAULT 1.00;
ALTER TABLE user_profile ADD COLUMN carb_cycle_low_multiplier REAL NOT NULL DEFAULT 0.80;
ALTER TABLE user_profile ADD COLUMN carb_taper_review_period_days INTEGER NOT NULL DEFAULT 14;
ALTER TABLE user_profile ADD COLUMN carb_taper_target_loss_pct_per_week REAL NOT NULL DEFAULT 0.50;
ALTER TABLE user_profile ADD COLUMN carb_taper_step_g REAL NOT NULL DEFAULT 10.0;
ALTER TABLE user_profile ADD COLUMN carb_taper_current_delta_g REAL NOT NULL DEFAULT 0.0;
ALTER TABLE user_profile ADD COLUMN last_carb_taper_review_at TEXT;
```

New table:

```sql
CREATE TABLE IF NOT EXISTS diet_adjustment_reviews (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  review_date TEXT NOT NULL,
  window_days INTEGER NOT NULL,
  diet_goal_phase TEXT NOT NULL,
  diet_calculation_mode TEXT NOT NULL,
  diet_plan_strategy TEXT NOT NULL,
  start_avg_weight_kg REAL,
  end_avg_weight_kg REAL,
  weight_change_kg REAL,
  loss_rate_pct_per_week REAL,
  target_loss_pct_per_week REAL,
  food_log_coverage REAL,
  active_training_days INTEGER,
  suggested_action TEXT NOT NULL,
  suggested_carb_delta_g REAL NOT NULL DEFAULT 0,
  applied_delta_after_g REAL,
  confidence REAL NOT NULL DEFAULT 0,
  reason_codes_json TEXT,
  user_decision TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

Compatibility notes:

- existing users default to `diet_plan_strategy = none`
- current phase, mode, macro ratio, and g/kg settings are preserved
- migration remains additive only

Export update:

- `user_profile` export now includes all diet-plan strategy fields
- `daily_summary` export now includes base targets, final targets, strategy metadata, and reason codes
- `diet_adjustment_reviews` is exported as a separate sheet / csv

## 2026-06 Schema v6 Update

Database version is now `6`.

Additive migration:

```sql
ALTER TABLE user_profile
ADD COLUMN diet_goal_phase TEXT NOT NULL DEFAULT 'cutting';
```

New `user_profile` field:

| Field | Type | Default | Meaning |
| -- | -- | -- | -- |
| `diet_goal_phase` | TEXT NOT NULL | `cutting` | Diet goal phase: `cutting` or `bulking`. Existing users migrate to `cutting`. |

Compatibility notes:

- Existing profile data is preserved.
- `diet_calculation_mode`, `training_frequency_per_week`, and macro ratio fields keep their previous values.
- `daily_energy_goal_type` remains available for compatibility, but phase is now the algorithm source of truth.

Export update:

- `user_profile.csv` / User Profile sheet include `diet_goal_phase`.
- `daily_summary.csv` / Daily Summary sheet include `diet_goal_phase`, `diet_calculation_mode`, and `macro_energy_equivalent_kcal`.

## 1. 当前数据存储方式

| 存储方式 | 用途 | 是否本地持久化 | 是否远程同步 | 代码位置 |
| -- | -- | -- | -- | -- |
| SQLite / sqflite | 用户资料、饮食记录、食物明细、训练 session、训练组、体重日志、热量校准状态 | 是 | 否 | `lib/data/db/app_database.dart` |
| SharedPreferences | UI 语言偏好 `language_code` | 是 | 否 | `lib/core/localization/language_controller.dart` |
| 本地文件 | 导出的 XLSX、CSV ZIP | 是 | 否 | `lib/export/xlsx_export_service.dart`、`lib/export/csv_export_service.dart` |
| 内存 Provider | AppServices、刷新版本、选中日期、语言状态 | 运行时 | 否 | `lib/app.dart` |

相关依赖：`sqflite`、`path`、`path_provider`、`shared_preferences`、`excel`、`csv`、`archive`，见 `pubspec.yaml`。当前未发现 Firebase、REST API、远程数据库或云同步实现。

## 2. 数据库初始化

| 项目 | 当前实现 |
| -- | -- |
| 数据库名称 | `fitlog_local.db` |
| 数据库版本 | `5` |
| 路径 | `getApplicationDocumentsDirectory()` 下的数据库文件 |
| 初始化 | `AppDatabase._initDatabase` 调用 `openDatabase` |
| 外键 | `onConfigure` 执行 `PRAGMA foreign_keys = ON` |
| onCreate | `_createTables` 创建全部表 |
| onUpgrade | v2 增加 `workout_sessions.plan_id`；v3 增加宏量比例字段；v4 创建体重日志与校准表；v5 增加饮食模式与 g/kg 自检字段 |
| seed data | 当前未发现数据库 seed data |
| 默认数据 | 未写入数据库；无 profile 时由 `UserProfile.defaults` 作为运行时默认值 |
| 清空数据 | `clearAllLocalData` 事务删除所有业务表 |

代码位置：`lib/data/db/app_database.dart`。

## 3. 表结构 / 存储结构

### Table: `user_profile`

用途：保存单一用户资料、目标设置、饮食算法模式和 g/kg 自检设置。创建位置：`AppDatabase._createTables`。

| 字段 | 类型 | 含义 | 是否可为空 | 默认值 | 备注 |
| -- | -- | -- | -- | -- | -- |
| `id` | INTEGER PRIMARY KEY | profile id | 否 | 无 | Repository 固定使用 `1` |
| `age` | INTEGER | 年龄 | 否 | 无 | BMR 与未成年人保护 |
| `height_cm` | REAL | 身高 cm | 否 | 无 | BMR |
| `weight_kg` | REAL | 体重 kg | 否 | 无 | BMR、g/kg、运动消耗 |
| `sex_for_formula` | TEXT | 性别公式选项 | 否 | 无 | `male/female/prefer_not_to_say` |
| `activity_level` | TEXT | 非运动活动水平 | 否 | 无 | energy_ratio 模式使用 |
| `daily_energy_goal_type` | TEXT | 目标类型 | 否 | 无 | `maintenance/deficit/surplus` |
| `daily_energy_goal_kcal` | REAL | 每日热量赤字 | 否 | 无 | kcal |
| `protein_ratio_percent` | REAL | 蛋白质比例 | 否 | 无 | v3 字段 |
| `carbs_ratio_percent` | REAL | 碳水比例 | 否 | 无 | v3 字段 |
| `fat_ratio_percent` | REAL | 脂肪比例 | 否 | 无 | v3 字段 |
| `diet_calculation_mode` | TEXT | 饮食算法模式 | 否 | `energy_ratio` | v5 字段 |
| `training_frequency_per_week` | INTEGER | 每周训练频率粗略档位 | 否 | `3` | v5 字段；仅用于减脂 g/kg MVP 默认表，不代表真实强度、训练容量或表现需求 |
| `macro_self_check_period_days` | INTEGER | 自检周期 | 否 | `14` | v5 字段 |
| `macro_self_check_enabled` | INTEGER | 自检开关 | 否 | `1` | bool 以 0/1 存储 |
| `last_macro_self_check_at` | TEXT | 上次自检反馈时间 | 是 | null | ISO datetime |
| `created_at` | TEXT | 创建时间 | 否 | 无 | ISO datetime |
| `updated_at` | TEXT | 更新时间 | 否 | 无 | ISO datetime |

### Table: `food_records`

用途：保存餐级饮食记录。创建位置：`AppDatabase._createTables`。

| 字段 | 类型 | 含义 | 是否可为空 | 默认值 | 备注 |
| -- | -- | -- | -- | -- | -- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | 记录 id | 否 | 自动 |  |
| `date` | TEXT | 记录日期 | 否 | 无 | `yyyy-MM-dd` |
| `meal_name` | TEXT | 餐名 | 否 | 无 |  |
| `total_weight_g` | REAL | 总重量 g | 否 | 无 |  |
| `calories_kcal` | REAL | 热量 kcal | 否 | 无 |  |
| `protein_g` | REAL | 蛋白质 g | 否 | 无 |  |
| `carbs_g` | REAL | 碳水 g | 否 | 无 |  |
| `fat_g` | REAL | 脂肪 g | 否 | 无 |  |
| `confidence` | REAL | 外部估算置信度 | 是 | null | 手动记录通常为空 |
| `estimation_notes` | TEXT | 估算备注 | 是 | null | Model fallback 为空字符串 |
| `source` | TEXT | 来源 | 否 | 无 | `ai_paste` 或 `manual` |
| `created_at` | TEXT | 创建时间 | 否 | 无 |  |
| `updated_at` | TEXT | 更新时间 | 否 | 无 |  |

### Table: `food_items`

用途：保存餐内明细项；随 `food_records` 删除级联删除。创建位置：`AppDatabase._createTables`。

| 字段 | 类型 | 含义 | 是否可为空 | 默认值 | 备注 |
| -- | -- | -- | -- | -- | -- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | item id | 否 | 自动 |  |
| `food_record_id` | INTEGER | 所属餐记录 | 否 | 无 | 外键到 `food_records.id`，ON DELETE CASCADE |
| `name` | TEXT | 食物名 | 否 | 无 |  |
| `estimated_weight_g` | REAL | 估算重量 g | 否 | 无 |  |
| `calories_kcal` | REAL | 热量 kcal | 否 | 无 |  |
| `protein_g` | REAL | 蛋白质 g | 否 | 无 |  |
| `carbs_g` | REAL | 碳水 g | 否 | 无 |  |
| `fat_g` | REAL | 脂肪 g | 否 | 无 |  |
| `notes` | TEXT | 备注 | 是 | null |  |

### Table: `workout_sessions`

用途：保存单个训练动作；同一训练计划由多条 session 共享 `plan_id`。创建位置：`AppDatabase._createTables`。

| 字段 | 类型 | 含义 | 是否可为空 | 默认值 | 备注 |
| -- | -- | -- | -- | -- | -- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | session id | 否 | 自动 |  |
| `plan_id` | TEXT | 训练计划 id | 是 | null | v2 字段 |
| `date` | TEXT | 训练日期 | 否 | 无 | `yyyy-MM-dd` |
| `body_part` | TEXT | 肌群 | 否 | 无 |  |
| `exercise_name` | TEXT | 动作名 | 否 | 无 |  |
| `exercise_type` | TEXT | `strength` 或 `cardio` | 否 | 无 |  |
| `duration_minutes` | INTEGER | 时长分钟 | 否 | 无 |  |
| `intensity` | TEXT | 强度 | 否 | 无 | 当前保存为 `medium` |
| `estimated_calories` | REAL | 估算净消耗 kcal | 否 | 无 |  |
| `notes` | TEXT | 备注 | 是 | null |  |
| `created_at` | TEXT | 创建时间/排序时间 | 否 | 无 | 用于时间线和开始时间 |
| `updated_at` | TEXT | 更新时间 | 否 | 无 |  |

### Table: `workout_sets`

用途：保存力量训练组；随 `workout_sessions` 删除级联删除。创建位置：`AppDatabase._createTables`。

| 字段 | 类型 | 含义 | 是否可为空 | 默认值 | 备注 |
| -- | -- | -- | -- | -- | -- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | set id | 否 | 自动 |  |
| `workout_session_id` | INTEGER | 所属训练 session | 否 | 无 | 外键到 `workout_sessions.id`，ON DELETE CASCADE |
| `set_number` | INTEGER | 组序号 | 否 | 无 |  |
| `weight_kg` | REAL | 重量 kg | 否 | 无 | 自重动作表示额外负重；0 表示纯自重 |
| `reps` | INTEGER | 次数 | 否 | 无 |  |
| `is_completed` | INTEGER | 是否完成 | 否 | 无 | bool 以 0/1 存储 |
| `completed_at` | TEXT | 完成时间 | 是 | null | ISO datetime |

### Table: `user_weight_logs`

用途：保存体重历史，用于动态热量校准。创建位置：`AppDatabase._createWeightAndCalibrationTables`。

| 字段 | 类型 | 含义 | 是否可为空 | 默认值 | 备注 |
| -- | -- | -- | -- | -- | -- |
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | 体重日志 id | 否 | 自动 |  |
| `date` | TEXT UNIQUE | 日期 | 否 | 无 | 每日唯一 |
| `weight_kg` | REAL | 体重 kg | 否 | 无 |  |
| `source` | TEXT | 来源 | 否 | 无 | 保存 profile 时为 `profile_save` |
| `created_at` | TEXT | 创建时间 | 否 | 无 |  |
| `updated_at` | TEXT | 更新时间 | 否 | 无 |  |

### Table: `calorie_calibration_state`

用途：保存动态热量校准状态。创建位置：`AppDatabase._createWeightAndCalibrationTables`。

| 字段 | 类型 | 含义 | 是否可为空 | 默认值 | 备注 |
| -- | -- | -- | -- | -- | -- |
| `id` | INTEGER PRIMARY KEY CHECK (id = 1) | 单例状态 id | 否 | 无 | 固定为 1 |
| `lifestyle_factor` | REAL | 校准后的非运动活动系数 | 否 | 无 |  |
| `confidence` | REAL | 校准置信度 | 否 | 无 | 0-1 |
| `window_days` | INTEGER | 校准窗口天数 | 否 | 无 | 7/14/21/28 |
| `valid_days` | INTEGER | 有效饮食天数 | 否 | 无 |  |
| `last_calibrated_date` | TEXT | 上次校准日期 | 是 | null | `yyyy-MM-dd` |
| `created_at` | TEXT | 创建时间 | 否 | 无 |  |
| `updated_at` | TEXT | 更新时间 | 否 | 无 |  |

### SharedPreferences

| Key | 类型 | 含义 | 默认值 | 代码位置 |
| -- | -- | -- | -- | -- |
| `language_code` | String | 当前 UI 语言代码 | `AppLanguage.english` | `LanguageController._languageCodeKey` |

## 4. 数据模型

| Model | 用途 | 主要字段 | 是否对应数据库表 | 序列化方法 | 代码位置 |
| -- | -- | -- | -- | -- | -- |
| `UserProfile` | 用户资料和目标设置 | age、height、weight、sex、activity、goal、macro ratio、diet mode、自检字段 | `user_profile` | `toMap` / `fromMap` | `lib/domain/models/user_profile.dart` |
| `FoodRecord` | 餐级饮食记录 | date、mealName、weight、kcal、P/C/F、confidence、source、items | `food_records` | `toMap` / `fromMap` | `lib/domain/models/food_record.dart` |
| `FoodItem` | 餐内食物明细 | foodRecordId、name、weight、kcal、P/C/F、notes | `food_items` | `toMap` / `fromMap` | `lib/domain/models/food_item.dart` |
| `WorkoutSession` | 单个训练动作记录 | planId、date、bodyPart、exerciseName、type、duration、estimatedCalories、sets | `workout_sessions` | `toMap` / `fromMap` | `lib/domain/models/workout_session.dart` |
| `WorkoutSet` | 力量训练组 | workoutSessionId、setNumber、weight、reps、isCompleted、completedAt | `workout_sets` | `toMap` / `fromMap` | `lib/domain/models/workout_set.dart` |
| `WeightLog` | 体重日志 | date、weightKg、source、timestamps | `user_weight_logs` | `toMap` / `fromMap` | `lib/domain/models/weight_log.dart` |
| `CalorieCalibrationState` | 动态校准状态 | lifestyleFactor、confidence、windowDays、validDays、lastCalibratedDate | `calorie_calibration_state` | `toMap` / `fromMap` | `lib/domain/models/calorie_calibration_state.dart` |
| `DailySummary` | 运行时每日汇总 | 摄入、运动、BMR、目标、剩余量、校准与自检字段、当日记录列表 | 不对应表 | 无；由 Service 组装 | `lib/domain/models/daily_summary.dart` |
| `TrainingFrequencySelfCheckResult` | g/kg 自检结果 | activeTrainingDays、averageWeekly、recommended、状态 flags | 不对应表 | 无；由 Service 组装 | `lib/domain/models/training_frequency_self_check_result.dart` |

## 5. DAO / Repository / Service / Provider

当前代码没有单独命名的 DAO 类；数据库访问集中在 Repository。

| 层级 | 类 / 文件 | 职责 | 代码位置 |
| -- | -- | -- | -- |
| Database | `AppDatabase` | 初始化 SQLite、建表、升级、清空本地数据 | `lib/data/db/app_database.dart` |
| Repository | `FoodRepository` | 饮食记录 CRUD、按日期查询、日期范围热量聚合 | `lib/data/repositories/food_repository.dart` |
| Repository | `WorkoutRepository` | 训练 session/set CRUD、按日期/计划/范围查询、完成组更新 | `lib/data/repositories/workout_repository.dart` |
| Repository | `ProfileRepository` | Profile 读写、体重日志 upsert、校准状态读写、自检反馈写入 | `lib/data/repositories/profile_repository.dart` |
| Service | `NutritionCalculator` | 外部 JSON 解析、饮食宏量/热量求和 | `lib/domain/services/nutrition_calculator.dart` |
| Service | `DailySummaryService` | 每日汇总、BMR、目标摄入、动态校准、自检整合 | `lib/domain/services/daily_summary_service.dart` |
| Service | `MacroTargetCalculator` | `energy_ratio` 热量赤字宏量比例换算与 `gram_per_kg` 减脂 g/kg 默认表计算 | `lib/domain/services/macro_target_calculator.dart` |
| Service | `WorkoutCalorieCalculator` | 有氧与力量净消耗估算 | `lib/domain/services/workout_calorie_calculator.dart` |
| Service | `TrainingFrequencySelfCheckService` | g/kg 模式训练频率自检 | `lib/domain/services/training_frequency_self_check_service.dart` |
| Export Service | `XlsxExportService`、`CsvExportService` | 本地数据导出 | `lib/export/*` |
| Provider 容器 | `AppServices` | 将 Repository、Service、Database 注入 UI | `lib/app.dart` |
| Provider 状态 | `RefreshNotifier` | 数据变更后通知页面重载 | `lib/app.dart` |
| Provider 状态 | `SelectedDateNotifier` | 跨首页/饮食/训练共享选中日期 | `lib/app.dart` |
| Provider 状态 | `LanguageController` | 语言状态与 SharedPreferences 持久化 | `lib/core/localization/language_controller.dart` |

UI 通常通过 `context.read<AppServices>()` 使用 Repository/Service；未发现 UI 直接拼接 SQL。`ProfilePage._clearAllData` 通过 `services.database.clearAllLocalData()` 触发数据库清空。

## 6. 原始数据与聚合数据

### 原始数据

| 数据 | 是否持久化 | 存储位置 | 写入入口 |
| -- | -- | -- | -- |
| 用户资料与目标 | 是 | `user_profile` | `ProfileRepository.saveProfile` |
| 体重日志 | 是 | `user_weight_logs` | `ProfileRepository.upsertWeightLog` |
| 饮食餐级记录 | 是 | `food_records` | `FoodRepository.insertFoodRecord` |
| 食物 item 明细 | 是 | `food_items` | `FoodRepository.insertFoodRecord` |
| 训练动作记录 | 是 | `workout_sessions` | `WorkoutRepository.insertWorkoutSession` |
| 力量训练组 | 是 | `workout_sets` | `WorkoutRepository.insertWorkoutSession` |
| 校准状态 | 是 | `calorie_calibration_state` | `ProfileRepository.saveCalorieCalibrationState` |
| 语言偏好 | 是 | SharedPreferences `language_code` | `LanguageController.setLanguage` |

### 聚合数据

| 聚合数据 | 是否长期存储 | 计算方式 | 代码位置 |
| -- | -- | -- | -- |
| 今日 kcal / P / C / F | 否 | 按日期查询 `food_records` 后求和 | `DailySummaryService`、`NutritionCalculator` |
| 今日运动消耗 | 否 | 按日期查询 `workout_sessions.estimated_calories` 后求和 | `DailySummaryService` |
| BMR / TDEE 参考 | 否 | 由 profile 与校准状态运行时计算 | `DailySummaryService.calculateBmr` |
| 今日目标摄入 | 否 | BMR、活动系数、每日热量赤字、运动消耗运行时计算 | `DailySummaryService` |
| 今日剩余 kcal/macros | 否 | 目标减去已摄入 | `DailySummaryService` |
| 导出 Daily Summary | 否 | 导出时按历史记录日期逐日计算 | `XlsxExportService`、`CsvExportService` |
| 校准 lifestyle factor | 是 | 动态校准后保存到单例表 | `calorie_calibration_state` |
| g/kg 自检推荐 | 否 | Profile 展示时根据训练历史计算；应用建议才写回 profile 频率 | `TrainingFrequencySelfCheckService`、`ProfileRepository.saveMacroSelfCheckFeedback` |

## 7. 关键数据流

### 用户资料 / 目标数据流

```text
ProfilePage 输入
-> UserProfile
-> ProfileRepository.saveProfile
-> user_profile + user_weight_logs
-> DailySummaryService.getSummaryForDate
-> HomePage / ProfilePage 参考值展示
```

代码位置：`lib/features/profile/profile_page.dart`、`UserProfile`、`ProfileRepository`、`DailySummaryService`、`HomePage`。

### 饮食记录数据流

```text
AddFoodPage / ManualFoodEntryPage / PasteAiResultPage
-> FoodRecord + FoodItem
-> FoodRepository.insertFoodRecord
-> food_records + food_items
-> FoodRepository.getFoodRecordsByDate
-> NutritionCalculator.sum*
-> DailySummary
-> HomePage / FoodLogPage
```

AI 粘贴路径额外经过 `NutritionCalculator.parseAiFoodJson` 和 `FoodPreviewPage`；手动录入路径直接构造 `FoodRecord`。

### 训练记录数据流

```text
AddWorkoutPage 选择动作和填写参数
-> WorkoutCalorieCalculator 估算消耗
-> WorkoutSession + WorkoutSet
-> WorkoutRepository.insertWorkoutSession
-> workout_sessions + workout_sets
-> WorkoutRepository.getWorkoutSessionsByDate
-> DailySummaryService 汇总 exerciseCalories
-> HomePage / WorkoutLogPage
```

训练计划编辑路径：

```text
WorkoutPlanPage 编辑日期/开始时间/总时长
-> 按原时长比例重分配 session 时长
-> WorkoutCalorieCalculator 重算消耗
-> WorkoutRepository.updateWorkoutSession
```

力量组打卡路径：

```text
WorkoutSessionPage 点击完成/取消
-> WorkoutRepository.completeSet
-> workout_sets.is_completed / completed_at
-> RefreshNotifier 刷新
```

### 导出数据流

```text
ProfilePage 点击导出
-> XlsxExportService 或 CsvExportService
-> Repository 读取原始记录
-> DailySummaryService 按有记录日期生成汇总
-> getApplicationDocumentsDirectory()
-> 写入 .xlsx 或 .zip
```

## 8. 当前未实现的数据能力

- 当前未实现云同步。
- 当前未实现账号系统。
- 当前未实现多设备同步。
- 当前未实现远程数据库。
- 当前未实现向量数据库。
- 当前未实现 embedding storage。
- 当前未实现 AI conversation history。
- 当前未实现 Agent action logs。
- 当前未实现 semantic memory。
- 当前未实现数据导入。
- 当前未发现 Firebase / REST API 数据传输层。

说明：当前已实现 SQLite onUpgrade 版本升级逻辑和本地数据导出，因此不应将“数据库升级”和“数据导出”视为未实现。

## 9. Database 层面的 Code References

- 数据库初始化与 schema：`lib/data/db/app_database.dart`
- Repository：`lib/data/repositories/food_repository.dart`、`workout_repository.dart`、`profile_repository.dart`
- Model：`lib/domain/models/user_profile.dart`、`food_record.dart`、`food_item.dart`、`workout_session.dart`、`workout_set.dart`、`weight_log.dart`、`calorie_calibration_state.dart`、`daily_summary.dart`、`training_frequency_self_check_result.dart`
- Service：`lib/domain/services/daily_summary_service.dart`、`nutrition_calculator.dart`、`macro_target_calculator.dart`、`workout_calorie_calculator.dart`、`training_frequency_self_check_service.dart`
- Provider / 状态：`lib/app.dart`、`lib/core/localization/language_controller.dart`
- 导出：`lib/export/xlsx_export_service.dart`、`lib/export/csv_export_service.dart`
- 配置：`pubspec.yaml`
