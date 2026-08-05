# Agent 边界

## 当前状态

FitLog Local 当前没有 App 内 AI、LLM 或 Agent 执行能力。

当前 App 没有实现：

- OpenAI、Gemini、ChatGPT 或其他 LLM API 调用
- LLM SDK 使用
- embeddings
- 向量数据库
- RAG
- function calling 或 tool calling
- Agent loop
- AI conversation memory
- Agent action logs

当前和 AI 相邻的能力都是静态的，或由用户手动介入：

| 功能 | 发生了什么 | 是否 App 内 AI | 主要代码 |
| --- | --- | --- | --- |
| Prompt 复制 | App 在 `AI 辅助录入` 工作台内按当前语言复制一次性对话初始化 Prompt；该 Prompt 可交给任意支持食物图片或文字的外部 AI。在外部对话中，新食物图片通常开始新餐，后续修改更新最近一餐，并始终使用不变 schema 返回完整 JSON。 | 否 | `PromptTemplates`, `PasteAiResultPage._copyPrompt` |
| 外部 AI JSON 粘贴 | 用户在同一个 `AI 辅助录入` 工作台内手动粘贴 App 外部产生的 JSON；该页显示包含三个一行式使用动作和推荐 GPT 信息的嵌套长期对话说明、paint-only 目标式键盘位移的固定 JSON 编辑器、全屏编辑和本地解析。 | 否 | `PasteAiResultPage`, `NutritionCalculator.parseAiFoodJson` |
| `source = ai_paste` | 保存记录可以标记来源为 AI paste 工作流。 | 否 | `AppConstants.sourceAiPaste`, `FoodRecord.source` |

## 本地确定性流程

App 中有一些看起来像自动化的流程，但它们都是确定性的 Dart/数据库流程，不是 Agent。

| 流程 | 输入 | 输出 | App 内是否使用 AI |
| --- | --- | --- | --- |
| Prompt 语言选择 | 当前 UI 语言 | 中文或英文 Prompt 文本 | 否 |
| JSON 解析 | 用户粘贴的 JSON 字符串 | `FoodRecord` 和 `FoodItem` 数据 | 否 |
| 饮食保存 | 饮食记录和 item | SQLite 行 | 否 |
| 饮食汇总 | 选中日期记录 | 每日 kcal/蛋白质/碳水/脂肪合计 | 否 |
| 自定义动作保存 | 用户填写的动作 metadata | 本地可复用动作定义 | 否 |
| 训练动作标准化 | 动作 metadata、组输入、时长、体重 | 保存原始输入值和标准化计算值 | 否 |
| 训练汇总 | 选中日期 sessions | 每日净运动 kcal | 否 |
| BMR 和目标计算 | Profile、饮食、训练、校准状态 | 每日目标和剩余量 | 否 |
| 宏量目标计算 | 饮食阶段和计算模式 | 蛋白质/碳水/脂肪目标 | 否 |
| 动态校准 | 饮食历史和体重日志 | 校准后的生活方式系数 | 否 |
| 训练频率自检 | 训练历史 | 建议共享训练频率设置 | 否 |
| 饮食策略 review | 体重趋势、饮食覆盖、训练稳定性 | 本地策略结果或 review 建议 | 否 |
| 导出 | SQLite 记录和运行时汇总 | XLSX 或 CSV ZIP | 否 |
| 清空本地数据 | 用户确认 | 删除本地表数据 | 否 |

## Agent 边界规则

- 任意支持图片/文字的外部 AI 都可以在数据进入 FitLog Local 前帮助估算食物；具体服务推荐不是 App 流程的必要条件。
- 复制 Prompt 建立的连续性只存在于外部对话中；FitLog Local 不保存该对话，也不提供 AI 记忆。
- FitLog Local 只负责本地数据的存储、解析、汇总、计算、复盘和导出。
- Prompt 模板不是 App 内 AI。
- JSON 解析不是 App 内 AI。
- `carb_tapering` 是确定性的本地 review 流程，不是会自行修改目标的 Agent。
- 自定义动作创建、有氧强度选择和训练组标准化都是确定性的本地 UI/数据库/计算器流程，不是 AI 分类。
- 除非明确要求，不得引入后端、云同步、LLM API、向量数据库、RAG、tool calling、语义记忆或 Agent loop。
- 如果未来增加 Agent 层，必须与当前本地确定性算法分开记录。

## 当前非目标

FitLog Local 当前不提供：

- Meal Decision Agent
- Weekly Review Agent
- Goal Review Agent
- AI Coach
- 自动饮食计划
- 自动目标更新
- 自动应用 carb taper
- App 内图片识别 API
- semantic memory
- vector search
- RAG
- tool calling
- multi-step Agent loop

## 代码引用

- Prompt 模板：`lib/core/constants/prompt_templates.dart`
- AI 相邻的饮食入口：`lib/features/food/add_food_page.dart`, `lib/features/food/paste_ai_result_page.dart`
- JSON parser：`lib/domain/services/nutrition_calculator.dart`
- 来源标记：`AppConstants.sourceAiPaste` in `lib/core/constants/app_constants.dart`
- 本地确定性 services：`daily_summary_service.dart`, `macro_target_calculator.dart`, `workout_calorie_calculator.dart`, `training_frequency_self_check_service.dart`, `diet_plan_strategy_service.dart`, `carb_cycling_calculator.dart`, `carb_taper_review_service.dart`
- 动作 metadata：`lib/core/constants/exercise_catalog.dart`, `lib/core/constants/exercise_definition.dart`, `lib/data/repositories/custom_exercise_repository.dart`
- 依赖检查：`pubspec.yaml`
