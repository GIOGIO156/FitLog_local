# References

## 范围

本文档记录当前 FitLog Local 设计中有用的外部引用。它不是文献综述，也不负责证明每一个产品选择。

引用用于支持：

- 当前本地算法使用的公式、范围和限制
- AI/Agent 相关表述的边界
- SQLite 和本地工程选择

以下内容不需要引用：

- UI 文案、页面名、按钮名或本地化字符串
- 内部字段名、表名、类名或文件路径
- changelog 历史
- 纯产品行为描述
- 尚未实现的未来 Agent/RAG/vector/semantic-memory 想法

## 证据边界

- FitLog Local 是个人记录与估算工具，不是医疗建议。
- 营养和运动数值都是近似估算。
- BMR/RMR、MET、g/kg、校准和 taper 规则都是有边界的启发式方法。
- g/kg 表是证据范围内的本地产品默认值，不是通用处方。
- 力量消耗系数是项目启发式，不是实验室级能量模型。
- 7700 kcal/kg 只作为粗略历史近似，并通过平滑和 clamp 限制。
- 未成年人保护是安全边界，不是儿科治疗指导。

## 算法引用

| ID | 主题 | 来源 | FitLog 用途 | 边界 |
| --- | --- | --- | --- | --- |
| REF-ALG-01 | BMR/RMR 公式 | Mifflin MD, St Jeor ST, Hill LA, Scott BJ, Daugherty SA, Koh YO. "A new predictive equation for resting energy expenditure in healthy individuals." Am J Clin Nutr. 1990. PMID: 2305711. | BMR 估算公式。 | 只是估算，不等于间接测热。 |
| REF-ALG-02 | BMR/RMR 限制 | Frankenfield D, Roth-Yousey L, Compher C. "Comparison of predictive equations for resting metabolic rate in healthy nonobese and obese adults." J Am Diet Assoc. 2005. PMID: 15883556. | 说明个体误差仍然明显。 | 仅作为限制背景。 |
| REF-ALG-03 | 宏量 kcal 换算 | 21 CFR 101.9 Nutrition labeling, eCFR. | 蛋白质/碳水 4 kcal/g，脂肪 9 kcal/g。 | 通用换算值。 |
| REF-ALG-04 | 宏量百分比框架 | National Academies / Institute of Medicine. Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids. | `energy_ratio` 百分比框架。 | 不证明用户输入比例一定合适。 |
| REF-ALG-05 | 蛋白质 g/kg 范围 | Jager R, Kerksick CM, Campbell BI, et al. "International Society of Sports Nutrition Position Stand: protein and exercise." J Int Soc Sports Nutr. 2017. PMID: 28642676. | 活跃人群蛋白范围背景。 | 不证明每个 FitLog 系数。 |
| REF-ALG-06 | 运动营养差异 | Thomas DT, Erdman KA, Burke LM. "Nutrition and Athletic Performance." J Acad Nutr Diet. 2016. PMID: 26920240. | 训练和身体成分差异背景。 | 仅广义背景。 |
| REF-ALG-07 | 饮食与身体成分 | Aragon AA, Schoenfeld BJ, Wildman R, et al. "International Society of Sports Nutrition Position Stand: diets and body composition." J Int Soc Sports Nutr. 2017. | cutting/bulking 与能量平衡框架。 | 不证明精确默认值。 |
| REF-ALG-08 | MET 数值 | Ainsworth BE, Haskell WL, Herrmann SD, et al. "2011 Compendium of Physical Activities." Med Sci Sports Exerc. 2011. PMID: 21681120. | 有氧 MET 映射。 | 活动映射是近似值。 |
| REF-ALG-09 | MET 换算 | 2024 Adult Compendium of Physical Activities update and Compendium unit conversion notes. | MET 到 kcal/min 公式。 | FitLog 减去 1 MET 是本地净运动建模选择。 |
| REF-ALG-10 | 7700 kcal/kg 历史规则 | Wishnofsky M. "Caloric equivalents of gained or lost weight." Am J Clin Nutr. 1958. PMID: 13594881. | 历史 kcal/kg 近似。 | 不是精确预测规则。 |
| REF-ALG-11 | 7700 kcal/kg 限制 | Hall KD. "Why is the 3500 kcal per pound weight loss rule wrong?" Int J Obes. 2013. PMID: 23774459. | 校准限制表述。 | 支持平滑启发式，不支持精确更新。 |
| REF-ALG-12 | 未成年人安全边界 | USPSTF Recommendation: High Body Mass Index in Children and Adolescents: Interventions. 2024. | 未成年人成人式赤字保护。 | 安全边界，不是治疗方案。 |
| REF-ALG-13 | 周期化碳水可用性 | Jeukendrup AE. "Periodized Nutrition for Athletes." Sports Med. 2017. PMID: 28332115. | carb cycling 概念框架。 | 仅支持概念。 |
| REF-ALG-14 | 周期化碳水限制证据边界 | Gejl KD, et al. "Performance effects of periodized carbohydrate restriction in endurance-trained athletes: a systematic review and meta-analysis." Sports Med. 2021. PMID: 34001184. | 避免夸大 carb cycling。 | 耐力表现语境。 |
| REF-ALG-15 | 碳水需求随训练变化 | Burke LM, Hawley JA, Wong SHS, Jeukendrup AE. "Carbohydrates for training and competition." J Sports Sci. 2011. PMID: 21660838. | 碳水策略背景。 | 运动表现语境。 |
| REF-ALG-16 | 蛋白质保留 | Jager R, et al. ISSN protein position stand. 2017. PMID: 28642676. | taper 时保持蛋白优先级。 | 仅支持广义范围。 |
| REF-ALG-17 | 保守减重速度框架 | Helms ER, Aragon AA, Fitschen PJ. "Evidence-based recommendations for natural bodybuilding contest preparation." J Int Soc Sports Nutr. 2014. PMID: 24864135. | taper 目标减重速度背景。 | 健美备赛人群。 |
| REF-ALG-18 | 备赛宏量变化观察 | Chappell AJ, Simper T, Barker ME. "Nutritional strategies of high level natural bodybuilders during competition preparation." J Int Soc Sports Nutr. 2018. PMID: 29371857. | 观察到碳水/脂肪常下降，蛋白保持较高。 | 仅观察性证据。 |
| REF-ALG-19 | 动态体重变化限制 | Hall KD. "Why is the 3500 kcal per pound weight loss rule wrong?" Int J Obes. 2013. PMID: 23774459. | 支持滚动趋势 review 和用户确认。 | 不证明精确 taper 步长。 |

## Agent / AI 边界引用

当前 local 版本没有 App 内 Agent，因此不需要外部 Agent 实现引用。

当前本地事实：

- 没有 OpenAI/Gemini API
- 没有 LLM SDK
- 没有 embedding/vector/RAG/tool-calling 实现
- 没有 Agent loop
- 外部 AI JSON 粘贴是用户手动介入的产品流程
- 汇总、校准、自检、导出和策略 review 都是本地 Dart 确定性流程

## 数据库与工程引用

| ID | 主题 | 来源 | FitLog 用途 | 边界 |
| --- | --- | --- | --- | --- |
| REF-DB-01 | SQLite 本地存储 | SQLite official documentation/homepage. | 本地嵌入式结构化存储。 | 不证明每个 schema 决策。 |
| REF-DB-02 | Flutter SQLite 持久化 | Flutter docs "Persist data with SQLite"; `sqflite` package documentation. | 包和平台持久化选择。 | Schema 仍是项目特定。 |
| REF-DB-03 | SharedPreferences | Flutter `shared_preferences` package documentation. | 简单语言偏好存储。 | 不适合复杂关系记录。 |
| REF-DB-04 | Repository pattern | Martin Fowler, Repository pattern. | Repository/service 分层。 | 仅模式参考。 |

## 不应过度引用的内部决策

- 产品页面描述和普通 UX 行为。
- 页面名、标签、本地化字符串和文件路径。
- 字段名、枚举名、类名和表名。
- Changelog 和验证状态。
- SQLite 迁移语句本身。
- `diet_goal_phase`、`diet_calculation_mode` 和 `diet_plan_strategy` 名称。
- `prefer_not_to_say` 平均规则。
- g/kg 自检阈值和冷却。
- 力量消耗系数。
- `DailySummary` 是运行时聚合而非表。
- 当前没有 Agent/RAG/vector/semantic-memory 功能这一事实。

## 写作规则

- 保持 reference ID 稳定。
- 只引用来源真正支持的窄主张。
- 对启发式或产品特定选择标注为本地设计决策。
- 不把本文档变成实现历史堆放处。
