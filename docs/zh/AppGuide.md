# App 导览

## 目的

本文档解释 FitLog Local 每个 App 板块是干什么的、背后大致怎么工作、以及去哪里阅读设计细节。它是给用户和维护者看的地图，不替代 Product、Methodology、Algorithm、Database、Agent 或 References。

## 全局规则

- FitLog Local 是 local-first：业务数据存储在 SQLite，除非用户主动导出。
- Home、Food Log 和 Workout Log 共享选中日期。
- App 没有内部 LLM/API/Agent loop。
- 外部 AI 可以在数据进入 App 前帮助估算食物，但 FitLog 在本地存储和计算。
- `diet_goal_phase` 控制 cutting/bulking 语义。
- `energy_ratio` 和 `gram_per_kg` 保持分离。

继续阅读：

- 产品范围：[Product](Product.md)
- 方法原因：[Methodology](Methodology.md)
- AI 边界：[Agent](Agent.md)

## Home

Home 是选中日期的每日看板。

用户会看到：

- 选中日期
- 饮食摄入合计
- 训练消耗合计
- BMR 和非运动 TDEE 参考
- `energy_ratio` 下的目标摄入和剩余 kcal
- 宏量目标和剩余蛋白质/碳水/脂肪
- 当前 `diet_goal_phase`、`diet_calculation_mode` 和 `diet_plan_strategy`
- 选中日期饮食记录
- 选中日期训练记录

背后如何工作：

- `DailySummaryService` 读取 Profile、Food、Workout、校准、自检和策略数据。
- 饮食合计来自已保存的 `food_records`。
- 运动合计来自已保存的 `workout_sessions.estimated_calories`。
- `energy_ratio` 以 kcal 目标/摄入/剩余为主。
- `gram_per_kg` 以宏量克数为主，kcal 作为辅助信息。
- 策略字段展示 `none`、`carb_cycling` 或 `carb_tapering` 应用后的最终目标上下文。

继续阅读：

- 每日看板行为：[Product](Product.md#每日看板行为)
- 计算原因：[Methodology](Methodology.md)
- 公式：[Algorithm](Algorithm.md)
- 运行时聚合字段：[Database](Database.md#运行时聚合)

## Food Log

Food Log 是选中日期的饮食记录列表。

用户可以：

- 查看选中日期的已保存餐食
- 打开并编辑记录
- 复制记录到指定日期
- 二次确认后删除记录
- 进入 Add Food

背后如何工作：

- 一餐存储为一条 `FoodRecord`。
- 可选 item 行存储为 `FoodItem`。
- `source` 记录餐食来自手动录入还是外部 AI paste。
- 复制会创建新的本地记录，并生成新的 id/timestamp。
- 删除 food record 会级联删除它的 item 行。

继续阅读：

- 饮食流程：[Product](Product.md#饮食流程)
- 数据表：[Database](Database.md#food_records)、[Database](Database.md#food_items)
- AI 相邻边界：[Agent](Agent.md)

## Add Food

Add Food 是饮食录入入口。

录入方式：

- `Paste AI Result`：粘贴 App 外部产生的 JSON。
- `Manual Entry`：直接填写饮食数据。
- `Photo AI Analysis`：只是不具备内部图片识别的占位入口。
- Prompt 复制：复制中文或英文 prompt 到外部模型使用。

背后如何工作：

- Prompt 复制是静态文本，不是 AI 调用。
- 粘贴的 JSON 由 `NutritionCalculator` 在本地解析。
- 预览页允许用户修正解析值后再保存。
- 手动录入会直接写入本地记录，除非后续编辑，否则没有 item 行。

继续阅读：

- 产品行为：[Product](Product.md#饮食流程)
- AI 边界：[Agent](Agent.md)
- 解析和汇总公式：[Algorithm](Algorithm.md#饮食摄入汇总)

## Workout Log

Workout Log 是选中日期的训练记录列表。

用户可以：

- 查看选中日期的已保存训练记录
- 打开保存后的记录
- 删除保存后的记录
- 进入 Add/Edit Workout Record

背后如何工作：

- 面向用户的 `Workout Record` 可以包含多个动作。
- 内部一条多动作记录是多条共享同一 `plan_id` 的 `workout_sessions`。
- 同一记录内每条 session 也保存相同 `record_name`。
- 记录级摘要从已持久化 session 和 set 派生。

继续阅读：

- 训练流程：[Product](Product.md#训练流程)
- 训练表：[Database](Database.md#workout_sessions)、[Database](Database.md#workout_sets)

## Add/Edit Workout Record

Add/Edit Workout Record 用于创建或修改一条命名训练记录。

用户可以：

- 命名训练记录
- 选择一个或多个动作
- 保留用户选择动作的顺序
- 输入每个动作自己的时长
- 输入力量组的重量、次数和完成状态
- 添加备注
- 保存已完成力量组

背后如何工作：

- 动作选择支持部位筛选、搜索和多选顺序。
- 有氧动作使用时长，没有组清单。
- 力量动作使用 set 行。
- 保存前先完成校验，再持久化。
- 只保存已完成力量组；未勾选组会被丢弃。
- 编辑已保存记录时，以事务替换整个 `plan_id` 分组。

继续阅读：

- 产品流程：[Product](Product.md#训练流程)
- 运动消耗原因：[Methodology](Methodology.md#为什么运动消耗使用净消耗)、[Methodology](Methodology.md#为什么力量训练不简单按分钟计算)
- 公式：[Algorithm](Algorithm.md#运动消耗)
- 存储模型：[Database](Database.md#workout_sessions)

## Workout Record Detail

Workout Record Detail 解释保存后的训练记录。

用户会看到：

- 记录名称
- 日期和开始时间
- 总时长
- 总训练量
- 总组数
- 估算消耗
- 记录内动作
- 保存后的力量组详情

背后如何工作：

- 摘要指标来自已保存的 session 和 set。
- 总训练量基于已保存的力量组。
- 总组数是已保存力量组数量。
- 当前记录流程中，保存后的力量详情不再用于切换完成状态。

继续阅读：

- 产品行为：[Product](Product.md#训练流程)
- 数据模型：[Database](Database.md#workout_sessions)、[Database](Database.md#workout_sets)

## Profile

Profile 用于配置个人数据、饮食行为、语言、导出和本地数据操作。

用户可以设置：

- 年龄、身高、体重和性别选项
- 语言
- `diet_goal_phase`
- `diet_calculation_mode`
- `energy_ratio` 的活动水平、每日能量目标和宏量百分比
- `gram_per_kg` 的训练频率档位和自检设置
- `diet_plan_strategy`
- 碳循环 pattern 和倍率
- 碳水渐降 review 周期、目标减重速度、步长和当前偏移

背后如何工作：

- Profile 保存到单例 `user_profile`。
- 保存 Profile 也会 upsert 当天体重日志。
- 未成年人保护会阻止成人式减脂赤字行为和减脂碳水策略。
- g/kg 自检可以根据近期有效训练日推荐训练频率档位。
- 碳水渐降 review 可以建议本地操作，但必须用户确认。

继续阅读：

- 产品行为：[Product](Product.md#饮食设置-ux)
- 面向用户的方法解释：[Methodology](Methodology.md)
- 算法细节：[Algorithm](Algorithm.md)
- Profile 表：[Database](Database.md#user_profile)

## Export

Export 会为用户记录生成本地文件。

导出包含：

- food records
- food items
- workout records
- workout sets
- daily summary
- user profile
- diet adjustment review history
- 相关策略、校准和自检字段

背后如何工作：

- XLSX 和 CSV ZIP 写入 App 文档目录。
- daily summary 在导出时由 repositories 和 `DailySummaryService` 生成。
- 导出不会上传数据。

继续阅读：

- 导出覆盖：[Database](Database.md#导出覆盖)
- 产品边界：[Product](Product.md#已实现边界)

## Language

语言偏好控制 UI 文案和 Prompt 复制。

背后如何工作：

- 当前语言以 `language_code` 存储在 SharedPreferences。
- Prompt 复制跟随当前语言。
- 语言状态只保存在本地。

继续阅读：

- 存储概览：[Database](Database.md#存储概览)

## 隐私与 local-first 边界

FitLog Local 当前没有账号、后端同步、远程数据库或 App 内 AI 调用。

保持本地的数据：

- profile 数据
- 饮食记录
- 训练记录
- 体重日志
- 校准状态
- 饮食调整 review
- 导出文件
- 语言偏好

继续阅读：

- 数据库存储：[Database](Database.md)
- AI 边界：[Agent](Agent.md)
- 证据和安全边界：[References](References.md)
