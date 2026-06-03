# Agent.md

## 1. 当前是否存在 AI / LLM 功能

当前 local 版未发现真正的 AI / LLM / Agent 执行能力。代码中没有发现 OpenAI、Gemini、ChatGPT API、LLM SDK、embedding、向量数据库、RAG、function calling、tool calling 或 agent loop。

当前代码中存在的是“外部 AI 辅助输入”相关静态能力：

| 项目 | 当前状态 | 是否 App 内 AI | 代码位置 |
| -- | -- | -- | -- |
| AI 食物估算 Prompt 模板 | App 内提供中英文 Prompt，可复制到外部 ChatGPT/Gemini 使用 | 否 | `PromptTemplates`、`AddFoodPage._copyPrompt` |
| 粘贴 AI JSON | 用户手动粘贴外部模型输出，App 用本地 JSON 解析器转换为 `FoodRecord` | 否 | `PasteAiResultPage`、`NutritionCalculator.parseAiFoodJson` |
| `source = ai_paste` | 标记记录来源为 AI 粘贴 | 否 | `AppConstants.sourceAiPaste`、`FoodRecord.source` |
| Photo AI Analysis | 页面显示 Coming soon | 当前未实现 | `AddFoodPage` |

依赖扫描依据：`pubspec.yaml` 中未发现 AI/LLM/HTTP 类依赖；`rg` 搜索 `OpenAI / LLM / embedding / vector / RAG / agent / function calling / tool calling` 未发现 App 内实现。

## 2. 当前是否存在确定性自动化流程

以下流程是本地确定性 workflow，不是 LLM Agent。

| 自动化流程 | 输入 | 输出 | 是否使用 AI | 代码位置 |
| -- | -- | -- | -- | -- |
| AI Prompt 按语言选择 | 当前语言 | 中文或英文 Prompt 文本 | 否 | `PromptTemplates.promptForLanguage`、`LanguageController` |
| 粘贴 JSON 解析 | 用户粘贴的 JSON 字符串 | `FoodRecord`、`FoodItem` | 否 | `NutritionCalculator.parseAiFoodJson` |
| 饮食记录保存 | `FoodRecord` 与 item 行 | SQLite `food_records`、`food_items` | 否 | `FoodRepository.insertFoodRecord` |
| 今日摄入汇总 | 指定日期食物记录 | kcal、protein、carbs、fat 合计 | 否 | `DailySummaryService.getSummaryForDate`、`NutritionCalculator` |
| 运动消耗汇总 | 指定日期训练 session | 当日训练净消耗合计 | 否 | `WorkoutRepository.getWorkoutSessionsByDate`、`DailySummaryService` |
| BMR 与目标摄入计算 | 用户资料、热量赤字、校准系数、运动消耗 | BMR、TDEE 参考、目标摄入、剩余热量 | 否 | `DailySummaryService` |
| 宏量目标计算 | `energy_ratio` 热量赤字模式，或 `gram_per_kg` 减脂 g/kg 默认表 | protein/carbs/fat 目标 | 否 | `MacroTargetCalculator` |
| 动态热量校准 | 饮食历史、体重日志、训练消耗 | 校准后的 lifestyle factor | 否 | `DailySummaryService._resolveCalibration` |
| g/kg 训练频率自检 | 训练历史、周期、当前粗略频率档位 | 推荐训练频率档位与提醒状态；不代表强度或运动表现需求 | 否 | `TrainingFrequencySelfCheckService` |
| 日期筛选 | `SelectedDateNotifier.selectedDate` | 对应日期记录与汇总 | 否 | `SelectedDateNotifier`、各页面 Repository 查询 |
| UI 刷新 | 数据写入完成 | 首页/列表 FutureBuilder 重新加载 | 否 | `RefreshNotifier.markDataChanged` |
| 语言持久化 | 用户选择语言 | SharedPreferences `language_code` | 否 | `LanguageController` |
| 数据导出 | SQLite 记录与运行时 DailySummary | XLSX 或 CSV ZIP 文件 | 否 | `XlsxExportService`、`CsvExportService` |
| 清空本地数据 | 用户二次确认 | 删除本地表数据 | 否 | `AppDatabase.clearAllLocalData` |

## 3. AI 功能说明

当前未实现 App 内 AI 功能。

说明：`PromptTemplates` 和 `PasteAiResultPage` 只负责静态提示词与外部 JSON 文本解析；模型推理发生在 App 外部的 ChatGPT/Gemini，不属于当前代码库内的 AI 功能。

## 4. 当前未实现的 Agent 能力

- 当前未实现 Meal Decision Agent。
- 当前未实现 Weekly Review Agent。
- 当前未实现 Goal Review Agent。
- 当前未实现 AI Coach。
- 当前未实现 Semantic Memory。
- 当前未实现 Vector Search。
- 当前未实现 RAG。
- 当前未实现 Tool Calling。
- 当前未实现 Multi-step Agent Loop。
- 当前未实现 AI 自动修改用户目标。
- 当前未实现 AI 自动生成饮食计划。
- 当前未实现 AI 图片识别 API；`Photo AI Analysis` 只是占位入口。
- 当前未实现 AI conversation history 或 Agent action logs。

## 5. Agent 与算法边界

当前 local 版不存在真正的 Agent。当前所有核心流程均由本地 UI、数据库和确定性算法完成。

| 边界项 | 当前事实 | 代码位置 |
| -- | -- | -- |
| 营养目标 | 本地 Dart 代码计算 | `DailySummaryService`、`MacroTargetCalculator` |
| 摄入汇总 | 本地按日期查询并求和 | `FoodRepository`、`NutritionCalculator` |
| 剩余量 | 本地目标减去已摄入 | `DailySummaryService` |
| 运动消耗 | 本地公式估算并保存 | `WorkoutCalorieCalculator`、`WorkoutRepository` |
| 动态校准 | 本地历史数据窗口计算 | `DailySummaryService._buildCalibrationSample` |
| 训练频率自检 | 本地历史训练记录计算建议 | `TrainingFrequencySelfCheckService` |
| AI 修改用户数据 | 当前未实现 | 未发现对应代码 |
| AI 生成饮食建议 | 当前未实现 | 未发现对应代码 |

## 6. Agent 层面的 Code References

- Prompt 模板：`lib/core/constants/prompt_templates.dart`
- AI 粘贴入口：`lib/features/food/add_food_page.dart`、`lib/features/food/paste_ai_result_page.dart`
- JSON 解析：`lib/domain/services/nutrition_calculator.dart`
- 来源标记：`AppConstants.sourceAiPaste` in `lib/core/constants/app_constants.dart`
- 本地算法：`lib/domain/services/daily_summary_service.dart`、`macro_target_calculator.dart`、`workout_calorie_calculator.dart`、`training_frequency_self_check_service.dart`
- Provider / 状态：`lib/app.dart`
- 依赖配置：`pubspec.yaml`
- 搜索结论：未发现 OpenAI/Gemini API、embedding、vector database、RAG、Agent loop、tool calling 相关实现。
