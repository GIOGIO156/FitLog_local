# Product.md

## 1. 项目定位

FitLog Local 是一个 Flutter 本地优先的个人饮食与训练记录 App。当前代码库实现的核心能力是：记录饮食营养值、记录训练与估算运动净消耗、按日期汇总每日摄入/消耗/目标、管理个人资料与饮食算法模式，并导出本地数据。

当前产品不依赖后端、不包含账号系统。业务数据存储在本机 SQLite，语言偏好存储在 SharedPreferences。App 内提供可复制的 AI 食物估算 Prompt，并支持粘贴外部 ChatGPT/Gemini 产出的 JSON，但没有接入真实 AI API。

代码依据：`lib/app.dart`、`lib/data/db/app_database.dart`、`lib/features/home/home_page.dart`、`lib/features/food/*`、`lib/features/workout/*`、`lib/features/profile/profile_page.dart`、`README.md`。

## 2. 当前已实现的核心功能

| 功能 | 用户能做什么 | 当前状态 | 代码位置 |
| -- | -- | -- | -- |
| 首页每日看板 | 按选中日期查看摄入热量、运动消耗、BMR、TDEE 参考、目标摄入、剩余热量、三大营养素和当日记录列表 | 已实现 | `lib/features/home/home_page.dart`、`lib/domain/services/daily_summary_service.dart` |
| 共享日期导航 | 在首页、饮食、训练模块切换上一天/下一天或选择日期 | 已实现 | `SelectedDateNotifier` in `lib/app.dart`、`DateUtilsX` in `lib/core/utils/date_utils.dart` |
| 饮食记录列表 | 查看指定日期的食物记录、来源、热量、重量和宏量营养素 | 已实现 | `lib/features/food/food_log_page.dart`、`FoodRepository.getFoodRecordsByDate` |
| AI JSON 粘贴录入 | 粘贴外部模型生成的 JSON，解析为食物记录，预览后保存 | 已实现；仅解析文本，不调用 AI | `lib/features/food/add_food_page.dart`、`lib/features/food/paste_ai_result_page.dart`、`NutritionCalculator.parseAiFoodJson` |
| AI Prompt 复制 | 按当前语言复制内置食物估算 Prompt，供外部 ChatGPT/Gemini 使用 | 已实现；静态模板 | `PromptTemplates` in `lib/core/constants/prompt_templates.dart`、`AddFoodPage._copyPrompt` |
| 手动饮食录入 | 手动填写餐名、日期、重量、热量、蛋白质、碳水、脂肪和备注 | 已实现 | `lib/features/food/manual_food_entry_page.dart` |
| 饮食详情编辑 | 编辑既有食物记录及 item 行，更新 SQLite 数据 | 已实现 | `lib/features/food/food_detail_page.dart`、`FoodRepository.updateFoodRecord` |
| 饮食删除 | 在列表中二次确认后删除记录，关联 item 通过外键级联删除 | 已实现 | `FoodLogPage._deleteRecord`、`AppDatabase` 外键配置 |
| 饮食复制到指定日期 | 选择目标日期后复制餐名、营养值、来源、备注和 item 行，生成新记录 | 已实现 | `FoodLogPage._copyRecord` |
| 图片 AI 分析入口 | Add Food 页面显示 Photo AI Analysis / Coming soon | 当前未实现，仅占位 | `AddFoodPage` 中 `photoAiAnalysis` ListTile |
| 训练记录列表 | 查看指定日期训练计划块、开始时间、总时长、总消耗和动作名 | 已实现 | `lib/features/workout/workout_log_page.dart` |
| 多动作训练计划 | 选择多个动作，一次保存为同一个 `plan_id` 的多条训练 session | 已实现 | `lib/features/workout/add_workout_page.dart`、`WorkoutRepository.insertWorkoutSession` |
| 动作库筛选与搜索 | 按肌群筛选、搜索动作、多选动作 | 已实现 | `_ExerciseLibraryPickerPage` in `lib/features/workout/add_workout_page.dart`、`AppConstants.bodyPartExercises` |
| 力量训练组记录 | 输入重量、次数、完成状态；支持历史默认值复用 | 已实现 | `_SetDraft`、`_ExercisePlanDraft.fromHistory` in `lib/features/workout/add_workout_page.dart` |
| 有氧训练记录 | 为有氧动作填写时长并估算消耗；无组清单 | 已实现 | `AddWorkoutPage`、`WorkoutCalorieCalculator.estimateCardioCalories` |
| 训练计划详情与编辑 | 查看计划内动作，编辑日期、开始时间和总时长，并重算消耗 | 已实现 | `lib/features/workout/workout_plan_page.dart` |
| 训练单项详情与打卡 | 查看单个动作详情；力量训练可切换每组完成状态 | 已实现 | `lib/features/workout/workout_session_page.dart`、`WorkoutRepository.completeSet` |
| 个人资料与目标设置 | 设置年龄、身高、体重、性别、活动水平、目标类型、目标差值、饮食算法模式 | 已实现 | `lib/features/profile/profile_page.dart`、`UserProfile` |
| 饮食算法双模式 | `energy_ratio` 和 `gram_per_kg` 两种宏量目标计算模式 | 已实现 | `MacroTargetCalculator`、`DailySummaryService` |
| g/kg 训练频率自检 | 在 g/kg 模式下按历史训练日期计算建议训练频率，用户可应用或保留 | 已实现 | `TrainingFrequencySelfCheckService`、`ProfilePage._applySelfCheckSuggestion` |
| 未成年人减脂保护 | 年龄小于 18 时不允许 deficit，自动转为 maintenance | 已实现 | `UserProfile.copyWith`、`ProfilePage._normalizeGoalByAge` |
| 数据导出 | 导出 XLSX 或 CSV ZIP 到 App 文档目录 | 已实现 | `lib/export/xlsx_export_service.dart`、`lib/export/csv_export_service.dart` |
| 清空本地数据 | 二次确认后删除本地 SQLite 中全部业务数据 | 已实现 | `ProfilePage._clearAllData`、`AppDatabase.clearAllLocalData` |
| 中英文切换 | 切换 UI 语言并持久化语言代码 | 已实现 | `LanguageController`、`AppStrings` |

## 3. 页面 / 模块结构

| 页面 / 模块 | 作用 | 主要显示内容 | 用户操作 | 代码位置 |
| -- | -- | -- | -- | -- |
| Root Shell | 主导航壳 | Home、Food、Workout、Profile 四个底部 Tab | 切换模块 | `_RootShell` in `lib/app.dart` |
| HomePage | 每日汇总看板 | 日期、热量、目标、剩余量、三大营养素、当日饮食和训练列表 | 日期切换、展开/收起详细指标 | `lib/features/home/home_page.dart` |
| FoodLogPage | 饮食记录列表 | 指定日期记录、来源、热量、重量、P/C/F | 添加、打开详情、复制到日期、删除、日期切换 | `lib/features/food/food_log_page.dart` |
| AddFoodPage | 饮食添加入口 | 推荐流程、推荐 GPT、Prompt 复制、三种录入入口 | 复制 Prompt、进入粘贴 JSON、进入手动录入 | `lib/features/food/add_food_page.dart` |
| PasteAiResultPage | 粘贴外部 AI JSON | JSON 输入框、解析按钮、推荐 GPT 提示 | 粘贴并解析 JSON | `lib/features/food/paste_ai_result_page.dart` |
| FoodPreviewPage | AI JSON 预览与修正 | 餐食字段、item 明细、日期 | 修改字段并保存 | `lib/features/food/food_preview_page.dart` |
| ManualFoodEntryPage | 手动饮食录入 | 餐名、日期、重量、热量、P/C/F、备注 | 手动保存记录 | `lib/features/food/manual_food_entry_page.dart` |
| FoodDetailPage | 饮食详情编辑 | 主记录字段、item 明细、source | 修改并保存 | `lib/features/food/food_detail_page.dart` |
| WorkoutLogPage | 训练记录列表 | 指定日期计划块、开始时间、总时长、总消耗、动作名 | 添加、打开计划、删除、日期切换 | `lib/features/workout/workout_log_page.dart` |
| AddWorkoutPage | 新建训练计划 | 动作选择、每动作时长、力量组、备注、预计总消耗 | 选择动作、填写参数、保存计划 | `lib/features/workout/add_workout_page.dart` |
| ExerciseLibraryPickerPage | 动作库选择 | 肌群筛选、搜索、动作列表 | 多选动作 | `_ExerciseLibraryPickerPage` in `lib/features/workout/add_workout_page.dart` |
| WorkoutPlanPage | 训练计划详情 | 日期、开始时间、总时长、总消耗、计划内动作 | 打开动作详情、编辑计划日期/时间/时长 | `lib/features/workout/workout_plan_page.dart` |
| WorkoutSessionPage | 单个动作详情 | 动作、日期、肌群、时长、消耗、组完成情况 | 切换组完成状态 | `lib/features/workout/workout_session_page.dart` |
| ProfilePage | 资料、目标、导出和数据操作 | 语言、身体资料、饮食模式、目标、算法参考、导出按钮、清空数据 | 保存资料、切换语言、应用自检建议、导出、清空 | `lib/features/profile/profile_page.dart` |

## 4. 核心用户流程

### 饮食记录流程

1. 用户进入 Food Log，选择或使用当前日期：`FoodLogPage`、`SelectedDateNotifier`。
2. 用户点击 Add Food：`FoodLogPage._openAddFood`。
3. 用户可复制 Prompt 到外部 ChatGPT/Gemini：`AddFoodPage._copyPrompt`、`PromptTemplates`。
4. 用户将外部模型生成的 JSON 粘贴到 App：`PasteAiResultPage`。
5. App 用本地 JSON 解析逻辑生成 `FoodRecord` 与 `FoodItem`：`NutritionCalculator.parseAiFoodJson`。
6. 用户在预览页修正并保存：`FoodPreviewPage._save`、`FoodRepository.insertFoodRecord`。
7. 首页与 Food Log 通过 `RefreshNotifier` 和日期查询刷新汇总：`DailySummaryService.getSummaryForDate`。

### 手动饮食流程

1. 用户进入 Add Food -> Manual Entry。
2. 用户填写餐名、重量、热量、P/C/F 和备注。
3. App 以 `source = manual` 保存 `FoodRecord`，无 item 明细：`ManualFoodEntryPage._save`。

### 训练记录流程

1. 用户进入 Workout Log 并选择日期：`WorkoutLogPage`。
2. 用户点击 Add Workout，打开动作库选择动作：`AddWorkoutPage._openExerciseLibraryPicker`、`_ExerciseLibraryPickerPage`。
3. App 为新动作读取同名历史 session 作为默认组/时长来源：`WorkoutRepository.getLatestSessionByExerciseName`、`_ExercisePlanDraft.fromHistory`。
4. 用户填写每个动作的时长；力量动作填写组重量、次数、完成状态；有氧动作不填写组。
5. App 估算每个动作消耗并以同一 `plan_id` 保存多条 `WorkoutSession`：`WorkoutCalorieCalculator`、`WorkoutRepository.insertWorkoutSession`。
6. 训练列表按 `plan_id` 聚合显示；计划详情可编辑日期、开始时间、总时长并重算消耗：`WorkoutLogPage._groupSessions`、`WorkoutPlanPage._savePlanEdits`。
7. 力量单项详情可继续勾选/取消组完成状态：`WorkoutSessionPage._toggleSetCompletion`。

### 资料与目标流程

1. 用户进入 Profile，读取本地 `UserProfile` 或默认资料：`ProfileRepository.getProfile`、`UserProfile.defaults`。
2. 用户设置身体资料、饮食算法模式、目标差值、宏量比例或 g/kg 训练频率。
3. 保存资料时写入 `user_profile`，并将当天体重写入 `user_weight_logs`：`ProfileRepository.saveProfile`。
4. 首页按最新资料、食物记录、训练记录和校准状态计算每日汇总：`DailySummaryService.getSummaryForDate`。

## 5. 当前产品边界

### 当前已实现

- 本地饮食记录、手动录入、外部 AI JSON 粘贴解析、预览编辑、复制和删除。
- 本地训练记录、多动作计划、力量组记录、有氧时长记录、计划编辑和组打卡。
- 本地每日汇总、BMR、非运动 TDEE 参考、目标摄入、剩余量、宏量目标。
- 动态热量校准、g/kg 宏量目标、训练频率自检建议。
- SQLite 持久化、SharedPreferences 语言偏好、XLSX/CSV ZIP 导出、清空本地数据。
- 中英文 UI 文案。

### 当前未实现

- 当前未实现 App 内图片识别；`Photo AI Analysis` 仅显示 Coming soon。
- 当前未实现 OpenAI / Gemini / 任意 LLM API 调用。
- 当前未实现真正的 AI Agent、Agent loop、Tool Calling、RAG、向量检索、长期语义记忆。
- 当前未实现自动配餐建议、AI 饮食计划、AI 周复盘、AI Coach。
- 当前未实现账号系统、云同步、多设备同步、远程数据库。
- 当前未实现数据导入；当前仅发现 XLSX/CSV ZIP 导出。
- 当前未实现医疗建议能力；README 明确声明营养数据仅用于个人记录参考。

## 6. Product 层面的 Code References

- 应用入口与 Provider：`lib/main.dart`、`lib/app.dart`
- 首页：`lib/features/home/home_page.dart`
- 饮食页面：`lib/features/food/food_log_page.dart`、`add_food_page.dart`、`paste_ai_result_page.dart`、`food_preview_page.dart`、`manual_food_entry_page.dart`、`food_detail_page.dart`
- 训练页面：`lib/features/workout/workout_log_page.dart`、`add_workout_page.dart`、`workout_plan_page.dart`、`workout_session_page.dart`
- 设置页：`lib/features/profile/profile_page.dart`
- 数据模型：`lib/domain/models/*`
- 业务服务：`lib/domain/services/daily_summary_service.dart`、`macro_target_calculator.dart`、`workout_calorie_calculator.dart`、`training_frequency_self_check_service.dart`、`nutrition_calculator.dart`
- 数据访问：`lib/data/db/app_database.dart`、`lib/data/repositories/*`
- 导出：`lib/export/xlsx_export_service.dart`、`lib/export/csv_export_service.dart`
- 本地化与 Prompt：`lib/core/localization/*`、`lib/core/constants/prompt_templates.dart`
