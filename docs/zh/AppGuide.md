# App Guide

## Purpose

本文档解释 FitLog Local 每个 App 板块做什么、背后大致如何工作、以及应去哪里继续阅读。它是给用户和维护者看的地图，不替代 Product、Methodology、Algorithm、Database、Agent 或 References。

## App-wide Rules

- FitLog Local 是 local-first：业务数据存储在 SQLite，除非用户主动导出。
- Home、Food Log 和 Workout Log 共享选中日期。
- App 没有内部 LLM/API/Agent loop。
- 外部 AI 可以帮助生成餐食估算，但数据进入 App 之后的存储、计算和展示都在本地完成。
- `diet_goal_phase` 控制 cutting/bulking 语义。
- `energy_ratio` 和 `gram_per_kg` 保持分离。

Read more:

- 产品范围：[Product](Product.md)
- 方法原因：[Methodology](Methodology.md)
- AI 边界：[Agent](Agent.md)

## Home

Home 是选中日期的每日入口页。

What users see:

- 根据本地时间变化的问候语；当昵称过长时，昵称会单独从第二行开始显示
- 已保存昵称；若为空则使用本地 fallback
- 选中日期
- `energy_ratio` 下的主 kcal 概览
- `gram_per_kg` 下的主宏量概览
- 蛋白质、碳水、脂肪的三张等尺寸宏量小卡片，并使用独立 SVG 资产渲染图标
- 当前 `diet_goal_phase`、`diet_calculation_mode` 和 `diet_plan_strategy`
- 简洁的当日饮食/训练摘要，并可跳转到副页

How it works:

- `DailySummaryService` 读取 Profile、Food、Workout、校准、自检和策略数据。
- 食物总量来自已保存的 `food_records`。
- 训练总量来自已保存的 `workout_sessions.estimated_calories`。
- `energy_ratio` 以 kcal 目标/摄入/剩余为主。
- `gram_per_kg` 以宏量克数为主，kcal 只是辅助信息。
- 策略字段展示 `none`、`carb_cycling` 或 `carb_tapering` 应用后的最终目标上下文。
- 当碳循环或碳水渐降启用时，Home 的策略卡片可以点开，并展示面向非熟悉用户的结构化方法说明。
- BMR、TDEE、校准细节和长表单设置不堆在 Home。

Read more:

- 每日看板行为：[Product](Product.md#daily-dashboard-behavior)
- 计算原因：[Methodology](Methodology.md)
- 公式：[Algorithm](Algorithm.md)
- 运行时聚合字段：[Database](Database.md#runtime-aggregates)

## Food Log

Food Log 是选中日期的饮食记录列表。

What users can do:

- 查看选中日期的已保存餐食
- 打开并编辑一条记录
- 把记录复制到其他日期
- 确认后删除记录
- 进入 Add Food
- 滑到当天记录列表底部后查看估算说明

How it works:

- 一餐存为一条 `FoodRecord`。
- 可选 item 行存为 `FoodItem`。
- `source` 记录该餐来自手动录入还是外部 AI 粘贴。
- 复制会创建新的本地记录和新的 id/timestamp。
- 删除一条饮食记录会级联删除其 item 行。

Read more:

- 饮食流程：[Product](Product.md#food-workflow)
- 数据表：[Database](Database.md#food_records)、[Database](Database.md#food_items)
- AI 相邻边界：[Agent](Agent.md)

## Add Food

Add Food 是饮食录入入口页。

Entry options:

- `Paste AI Result`：粘贴 App 外部生成的 JSON。
- `Manual Entry`：手动输入食物数据。
- `Photo AI Analysis`：可见占位入口，尚未实现 App 内图片识别。
- Prompt copy：复制中英文静态 prompt 给外部模型使用。

How it works:

- Prompt copy 是静态文本复制，不是 AI 调用。
- 粘贴的 JSON 由 `NutritionCalculator` 在本地解析。
- 预览页允许用户修正解析结果后再保存。
- 手动录入会直接写入本地记录。

Read more:

- 产品行为：[Product](Product.md#food-workflow)
- AI 边界：[Agent](Agent.md)
- 解析与汇总公式：[Algorithm](Algorithm.md#food-intake-summary)

## Workout Log

Workout Log 是选中日期的训练记录列表。

页面标题下方直接进入共享日期条，不再额外放置日历前说明文字。

What users can do:

- 查看选中日期的训练记录
- 打开一条已保存记录
- 删除已保存记录
- 进入 Add/Edit Workout Record

How it works:

- 一条面向用户的 `Workout Record` 可以包含多个动作。
- 在存储层，一个多动作记录是多条共享 `plan_id` 的 `workout_sessions`。
- 同一记录内每条 session 也保存相同的 `record_name`。
- 记录级摘要由已保存的 session 和 set 推导而来。
- 身体部位缩略图和关键训练图标现在来自共享 SVG 资产，而不是临时手绘的小图标。

Read more:

- 训练流程：[Product](Product.md#workout-workflow)
- 训练表：[Database](Database.md#workout_sessions)、[Database](Database.md#workout_sets)

## Add/Edit Workout Record

Add/Edit Workout Record 是创建或修改训练记录的页面。

What users can do:

- 给训练记录命名
- 从当前胸部、背部、腿部、臀部、肩部、手臂、核心、全身和有氧动作库中选择一个或多个动作
- 保持动作的用户选择顺序
- 输入每个动作的时长
- 输入力量组的重量、次数和完成状态
- 添加备注
- 保存已完成的力量组

How it works:

- 动作选择支持按部位筛选、搜索和多选顺序。
- 有氧动作只需要时长，不需要组清单。
- 力量动作使用组行。
- 辅助类自重动作在重量字段里记录的是辅助重量；估算消耗时按 `体重 - 辅助重量` 计算实际负重。
- 保存前先完成校验。
- 只有已完成的力量组会被保存；未勾选组会被丢弃。
- 编辑已保存记录时，会事务性替换整个 `plan_id` 分组。

Read more:

- 产品流程：[Product](Product.md#workout-workflow)
- 运动消耗原因：[Methodology](Methodology.md#为什么运动消耗使用净消耗)、[Methodology](Methodology.md#为什么力量训练不简单按分钟计算)
- 公式：[Algorithm](Algorithm.md#workout-calories)
- 存储模型：[Database](Database.md#workout_sessions)

## Workout Record Detail

Workout Record Detail 用来解释一条已保存训练记录。

What users see:

- 记录名
- 日期和开始时间
- 总时长
- 总训练量
- 总组数
- 估算消耗
- 记录中的动作
- 已保存的力量组细节

How it works:

- 摘要指标由已保存的 session 和 set 推导。
- 总训练量基于已保存的力量组。
- 组数是已保存力量组的数量。
- 在当前记录流中，已保存力量详情的完成状态是只读的。

Read more:

- 产品行为：[Product](Product.md#workout-workflow)
- 数据模型：[Database](Database.md#workout_sessions)、[Database](Database.md#workout_sets)

## Profile

Profile 用于配置本地身份、身体资料、饮食行为、语言、导出和本地数据操作。

What users can set:

- 仅用于本地 UI 展示的昵称
- 年龄、身高、体重和公式性别
- 语言
- `diet_goal_phase`
- `diet_calculation_mode`
- `energy_ratio` 的活动水平、每日能量目标和宏量百分比
- `gram_per_kg` 的训练频率档位和自检设置
- `diet_plan_strategy`
- carb cycling pattern 和 multiplier
- carb taper review 周期、目标减重速度、步长和当前 offset

How it works:

- Profile 保存到单例 `user_profile`。
- `nickname` 是本地 UI 数据，不是账号名。
- 保存 Profile 也会 upsert 当天体重日志。
- 未成年人保护会阻止成人式 cutting deficit 行为和 cutting carb 策略。
- g/kg 自检可以根据最近有效训练日推荐训练频率档位。
- Carb taper review 可以给出本地建议，但必须由用户确认。

Read more:

- 产品行为：[Product](Product.md#diet-setup-ux)
- 面向用户的方法解释：[Methodology](Methodology.md)
- 算法细节：[Algorithm](Algorithm.md)
- Profile 表：[Database](Database.md#user_profile)

## Export

Export 为用户记录生成本地文件。

What exports include:

- food records
- food items
- workout records
- workout sets
- daily summary
- user profile
- diet adjustment review history
- 策略、校准和自检字段，以及本地 nickname 等相关字段

How it works:

- XLSX 和 CSV ZIP 写入 app documents directory。
- Daily summary export 在导出时由 repositories 和 `DailySummaryService` 生成。
- Export 不会上传任何数据。

Read more:

- 导出覆盖：[Database](Database.md#export-coverage)
- 产品边界：[Product](Product.md#implemented-boundaries)

## Language

Language 负责切换中英文 UI。

What users can do:

- 切换 English 和 中文

How it works:

- 语言偏好保存到 `SharedPreferences`。
- Prompt 文案和普通 UI 文案都随语言切换。

## Privacy And Local-first Boundary

- 业务数据保存在本地 SQLite。
- 导出生成本地文件，不做云上传。
- `Photo AI Analysis` 仍是占位入口，不代表 App 内部具备识图能力。
- Prompt 复制和 JSON 粘贴是用户驱动的外部 AI 辅助流程，不是 App 内 AI。

Read more:

- 数据库存储：[Database](Database.md)
- AI 边界：[Agent](Agent.md)
- 证据和安全边界：[References](References.md)
