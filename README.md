# FitLog Local

## 这个 App 解决什么问题？怎么解决？
**解决的问题**  
很多人会用 ChatGPT / Gemini 拍照估算食物热量和三大营养素，但结果常常散落在聊天记录里，最后还要手动抄到 Excel，记录成本高、容易漏记。

**解决方式**  
FitLog Local 把“AI 估算”和“本地记录”串成一个完整流程：
1. 在 ChatGPT / Gemini 上传食物照片并拿到标准 JSON。
2. 把 JSON 粘贴进 App，一键解析、预览、可手动修正。
3. 保存到手机本地 SQLite，按天汇总饮食 + 运动。
4. 自动计算 BMR / 目标摄入 / 剩余热量。
5. 随时导出 XLSX / CSV（zip）。

简单说就是：  
**ChatGPT / Gemini 负责“看图估算食物”**，  
**FitLog Local 负责“保存、统计、训练记录和导出”。**

---

## 项目定位
- 个人/朋友使用的本地记录工具（MVP 阶段）
- 不商业化、不依赖后端
- 不需要注册登录
- 所有数据仅保存在本机

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
- Add Food 与 Paste 页面会显示推荐 GPT 提示文案。
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
- 你也可以不用以上 GPT，直接在 App 里复制内置 Prompt 到任意大模型。
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

### 今日消耗与目标
- `actual_daily_expenditure = bmr + exercise_calories_today`
- maintenance: `target_intake = actual_daily_expenditure`
- deficit: `target_intake = actual_daily_expenditure - daily_energy_goal_kcal`
- surplus: `target_intake = actual_daily_expenditure + daily_energy_goal_kcal`
- `remaining_calories = target_intake - calories_in_today`

### 运动消耗估算
- Cardio（MET）：`calories = MET * body_weight_kg * duration_hours`
- Strength（简化）：`calories = duration_minutes * body_weight_kg * intensity_factor`
- 当前 MVP 中，训练计划保存时强度固定为 `medium`。

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
1. 打开 ChatGPT 或 Gemini。
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
当前版本是可用的 MVP，目标是把“AI 食物估算结果落地记录”这件事做顺手：  
低摩擦录入、按天汇总、训练联动、本地可导出。
