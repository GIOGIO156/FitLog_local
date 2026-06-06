# 产品设计

## 目的

FitLog Local 是一款 local-first 的个人饮食与训练记录 App。它的产品价值不是单纯“记录 kcal”，而是把食物估算、结构化记录、每日目标、剩余宏量、训练消耗、饮食策略、复盘和导出串成一个可长期使用的本地工作流。

这个 App 面向的用户可以借助外部多模态 AI 估算复杂餐食，但需要把这些估算结果沉淀成可编辑、可查询、可导出的本地记录。

## 产品原则

- 本地优先：业务数据留在 SQLite，除非用户主动导出。
- 确定性行为：核心计算由本地 Dart 逻辑完成，不依赖 App 内 LLM 推理。
- 用户掌控：App 可以展示目标、剩余量和复盘建议，但不自动配餐，也不自动修改目标。
- 加法式兼容：数据库迁移必须保留现有本地用户数据。
- 饮食模式保持分离：`gram_per_kg` 和 `energy_ratio` 是并列方法，不得合并。
- 阶段必须显式：`diet_goal_phase` 是 cutting/bulking 行为的来源。

## 当前模块

| 模块 | 当前能力 | 主要代码 |
| --- | --- | --- |
| Home | 按选中日期展示摄入、运动、目标、剩余 kcal/宏量、饮食阶段/模式/策略上下文、饮食记录和训练记录。 | `lib/features/home/home_page.dart`, `DailySummaryService` |
| Food Log | 按日期筛选饮食记录，支持打开/编辑、复制到指定日期、删除和添加入口。 | `lib/features/food/food_log_page.dart`, `FoodRepository` |
| Add Food | 手动录入、外部 AI JSON 粘贴、Prompt 复制和占位的 `Photo AI Analysis`。 | `add_food_page.dart`, `paste_ai_result_page.dart`, `manual_food_entry_page.dart` |
| Food Detail | 编辑已保存的饮食记录和 item 行。 | `food_detail_page.dart` |
| Workout Log | 按日期展示保存后的训练记录，内部通过 `plan_id` 分组。 | `workout_log_page.dart`, `WorkoutRepository` |
| Add/Edit Workout Record | 命名的多动作训练记录创建/编辑、动作选择器、有氧时长、力量组、已完成组持久化、备注和摘要计算。 | `add_workout_page.dart` |
| Workout Record Detail | 保存后记录详情、摘要指标、动作卡片和编辑入口。 | `workout_plan_page.dart` |
| Workout Session Detail | 单动作详情视图；当前记录流程中，保存后的力量详情不再用于切换完成状态。 | `workout_session_page.dart` |
| Profile | 身体资料、语言、饮食阶段、饮食模式、策略设置、g/kg 自检、导出和清空本地数据。 | `profile_page.dart`, `ProfileRepository` |
| Export | 导出 XLSX 和 CSV ZIP，覆盖原始记录、每日汇总、资料、策略字段和 review 历史。 | `lib/export/*` |

## 饮食流程

1. 用户打开 Food Log 并选择日期。
2. 用户选择 Add Food。
3. 如果使用外部 AI 辅助录入，用户复制 FitLog 的 Prompt，使用任意外部模型，并把返回 JSON 粘贴进 App。
4. FitLog 用 `NutritionCalculator.parseAiFoodJson` 在本地解析 JSON。
5. 用户预览、修正并保存 `FoodRecord` 和可选 `FoodItem` 行。
6. 手动录入会跳过 JSON 解析，并以 `source = manual` 保存记录。
7. 保存后的记录可以编辑、删除或复制到用户选择的目标日期。
8. Home 和 Food Log 通过本地 Repository 与刷新状态重新加载。

## 训练流程

1. 用户打开 Workout Log 并选择日期。
2. 用户创建 `Workout Record`，填写名称，并选择一个或多个动作。
3. 动作库支持按部位筛选、搜索、多选和显示选择顺序。
4. 有氧动作需要每个动作自己的时长，不使用组清单。
5. 力量动作使用包含重量、次数和完成状态的组行。
6. 保存前先完成所有校验，再执行任何持久化。
7. 力量训练保存时只持久化已完成组；未勾选组会被移除，保存后的组号按 `1..n` 重排。
8. 一条多动作记录存储为多条共享同一 `plan_id` 的 `workout_sessions`；每条 session 也保存相同的 `record_name`。
9. 保存后的记录展示总时长、总训练量、总组数、估算消耗和动作卡片。
10. 编辑保存后的记录会重新进入创建页面，并以事务替换整个 `plan_id` 分组。

## 每日看板行为

- Home、Food Log 和 Workout Log 共享选中日期。
- Home 展示饮食摄入、训练消耗、BMR、非运动 TDEE 参考、目标摄入、剩余 kcal、宏量目标和剩余宏量。
- 在 `energy_ratio` 中，kcal 目标/摄入/剩余是主计数器。
- 在 `gram_per_kg` 中，宏量克数是主计数器，kcal 只是辅助摄入信息。
- Home 同时展示 `diet_goal_phase`、`diet_calculation_mode` 和 `diet_plan_strategy` 上下文。
- `carb_cycling` 展示碳水日类型和碳水调整上下文。
- `carb_tapering` 在有数据时展示当前 taper 偏移和待处理 review 上下文。

## 饮食设置 UX

Profile 按以下顺序展示饮食设置：

1. 身体资料：年龄、身高、体重和性别选项。
2. 目标阶段：`cutting` 或 `bulking`。
3. 计算模式：`energy_ratio` 或 `gram_per_kg`。
4. 可选策略：`none`、`carb_cycling` 或 `carb_tapering`。
5. 阶段/模式/策略对应的控制项。

预期行为：

- `cutting + gram_per_kg`：展示训练频率档位、自检设置、减脂 g/kg 表上下文和宏量目标预览。
- `bulking + gram_per_kg`：展示训练频率档位、自检设置、增肌 g/kg 表上下文和宏量目标预览。
- `cutting + energy_ratio`：展示活动水平、每日赤字、宏量比例和目标预览。
- `bulking + energy_ratio`：展示活动水平、每日盈余、宏量比例、默认 25/50/25 建议和目标预览。
- `carb_cycling`：展示每周 high/medium/low 日选择、倍率和本周预览。
- `carb_tapering`：展示 review 周期、目标减重速度、taper 步长、当前碳水偏移和本地 review 的 Apply/Dismiss 流程。

## 已实现边界

已实现：

- 本地饮食记录 CRUD 和复制到指定日期
- 外部 AI JSON 粘贴和本地解析
- 内置中英 Prompt 复制
- 本地训练记录创建、编辑、分组、摘要和删除
- 每日汇总计算与展示
- 动态热量校准
- g/kg 训练频率自检
- cutting/bulking 阶段拆分
- `energy_ratio` 和 `gram_per_kg` 饮食计算模式
- 本地确定性的 `carb_cycling` 和 `carb_tapering`
- XLSX 和 CSV ZIP 导出
- 语言切换
- 二次确认后清空本地数据

未实现：

- 后端、云同步、账号系统、远程数据库或数据导入
- App 内图片识别
- App 内 LLM API 调用
- RAG、向量数据库、embedding 存储、语义记忆、tool calling 或 Agent loop
- 自动配餐、AI Coach 或自动修改目标
- 医疗建议

## 代码引用

- App 启动与 providers：`lib/main.dart`, `lib/app.dart`
- Home：`lib/features/home/home_page.dart`
- Food：`lib/features/food/*`
- Workout：`lib/features/workout/*`
- Profile：`lib/features/profile/profile_page.dart`
- Models：`lib/domain/models/*`
- Services：`lib/domain/services/*`
- Database 与 repositories：`lib/data/db/app_database.dart`, `lib/data/repositories/*`
- Export：`lib/export/*`
- 本地化与 Prompt：`lib/core/localization/*`, `lib/core/constants/prompt_templates.dart`
