# FitLog Local References

## 1. Scope

This file records only the external references that are actually needed to justify the current FitLog Local design.

It is limited to:

- algorithm references for formulas, ranges, and modeling choices used in the current local app
- AI boundary notes for what the local app does and does not implement
- database and engineering references for current local storage and architecture choices

It does not cite:

- ordinary product descriptions in `Product.md`
- UI copy, page names, button names, labels, localization strings, file structure, or class/table/field names
- `CHANGELOG.md` facts, migration history, or other internal implementation facts
- future Agent-version ideas such as RAG, vector databases, semantic memory, tool calling, agent loops, AI Coach, automatic meal planning, or automatic weekly review

Current source of truth for diet design is the latest 2026-06 update across `README.md`, `CHANGELOG.md`, and the top sections of the docs: `diet_goal_phase`, schema v6, and the `cutting/bulking x gram_per_kg/energy_ratio` matrix. Older notes may remain in the docs; the latest 2026-06 update is the source of truth.

## 2. Evidence Boundaries

- FitLog Local is a personal logging and estimation tool, not medical advice.
- Algorithm references support ranges, formulas, and modeling choices, not individualized prescriptions.
- g/kg tables are local product defaults within evidence-informed ranges; they are not a universal scientific standard.
- Strength calorie estimation coefficients are FitLog heuristics, not validated lab-grade energy models.
- Dynamic calibration uses 7700 kcal/kg only as a rough historical approximation and is bounded by modern limitations.
- Under-18 deficit protection is a safety boundary, not a pediatric treatment plan.
- Where the app uses coarse tiers, clamps, smoothing, or fallback rules, those remain local engineering decisions unless explicitly tied to a source below.

## 3. Algorithm References

| REF ID | Topic | Source | Used In | Supports Local Design | Evidence Boundary |
| --- | --- | --- | --- | --- | --- |
| REF-ALG-01 | BMR/RMR equation | Mifflin MD, St Jeor ST, Hill LA, Scott BJ, Daugherty SA, Koh YO. "A new predictive equation for resting energy expenditure in healthy individuals." Am J Clin Nutr. 1990. PMID: 2305711. | `docs/Algorithm.md` BMR/RMR calculation | Supports the Mifflin-St Jeor REE/BMR estimate formula used by `DailySummaryService.calculateBmr`. | Estimated RMR/BMR only; not a substitute for indirect calorimetry. |
| REF-ALG-02 | BMR/RMR estimate limitation | Frankenfield D, Roth-Yousey L, Compher C. "Comparison of predictive equations for resting metabolic rate in healthy nonobese and obese adults." J Am Diet Assoc. 2005. PMID: 15883556. | `docs/Algorithm.md` BMR limitation note | Supports stating that Mifflin is often closer than some alternatives but individual error remains meaningful. | Use to state estimation uncertainty, not exact personalization. |
| REF-ALG-03 | Macronutrient energy conversion | 21 CFR 101.9 Nutrition labeling of food, eCFR. | `docs/Algorithm.md` macro kcal conversion and `macro_energy_equivalent_kcal` | Supports fat 9 kcal/g, carbohydrate 4 kcal/g, protein 4 kcal/g. | Labeling/general conversion values; not a personalized nutrition target. |
| REF-ALG-04 | AMDR macro ratio context | National Academies / Institute of Medicine, Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids. | `docs/Algorithm.md` `energy_ratio` macro percentage mode | Supports percentage-of-energy framing for macro ratios. | Supports percentage-based framing; does not validate FitLog's specific user-entered ratios. |
| REF-ALG-05 | Protein g/kg range for active people | Jager R, Kerksick CM, Campbell BI, et al. "International Society of Sports Nutrition Position Stand: protein and exercise." J Int Soc Sports Nutr. 2017. PMID: 28642676. | `docs/Algorithm.md` `gram_per_kg` protein table | Supports the broad 1.4-2.0 g/kg/day protein range for most exercising individuals. | Supports broad protein range; does not prove every FitLog sex/frequency coefficient. |
| REF-ALG-06 | Sports nutrition macro context | Thomas DT, Erdman KA, Burke LM. "Position of the Academy of Nutrition and Dietetics, Dietitians of Canada, and the American College of Sports Medicine: Nutrition and Athletic Performance." J Acad Nutr Diet. 2016. PMID: 26920240. | `docs/Algorithm.md` g/kg macro table context, macro variability, training variability | Supports that nutrition needs vary by training, body composition, health, and performance goals, and that personalized planning is preferable. | Broad context and limitation only; FitLog Local is not prescribing athlete diets. |
| REF-ALG-07 | Diets and body composition | Aragon AA, Schoenfeld BJ, Wildman R, et al. "International Society of Sports Nutrition Position Stand: diets and body composition." J Int Soc Sports Nutr. 2017. | `docs/Algorithm.md` cutting/bulking phase and energy deficit/surplus context | Supports evidence-informed framing that body-composition change depends on energy balance, macronutrient composition, and individual factors. | Supports framing only; does not validate exact FitLog defaults. |
| REF-ALG-08 | MET values | Ainsworth BE, Haskell WL, Herrmann SD, et al. "2011 Compendium of Physical Activities: a second update of codes and MET values." Med Sci Sports Exerc. 2011. PMID: 21681120. | `docs/Algorithm.md` cardio exercise MET mapping | Supports using MET values as standardized activity energy-cost references. | App exercise MET values are approximate mappings. |
| REF-ALG-09 | MET definition and conversion | 2024 Adult Compendium of Physical Activities update; Compendium unit conversion notes. | `docs/Algorithm.md` cardio calorie formula | Supports 1 MET as a standardized resting reference and the common MET to kcal/min conversion `MET x 3.5 x body weight / 200`. | FitLog subtracts 1 MET as a net-exercise modeling choice to avoid baseline double counting. |
| REF-ALG-10 | 7700 kcal/kg historical rule | Wishnofsky M. "Caloric equivalents of gained or lost weight." Am J Clin Nutr. 1958. PMID: 13594881. | `docs/Algorithm.md` dynamic calorie calibration | Supports the historical 3500 kcal/lb about 7700 kcal/kg approximation. | Historical approximation only; not an exact prediction rule. |
| REF-ALG-11 | 7700 kcal/kg limitation | Hall KD. "Why is the 3500 kcal per pound weight loss rule wrong?" Int J Obes. 2013. | `docs/Algorithm.md` dynamic calibration limitation | Supports stating that static 3500 kcal/lb logic misses dynamic energy-balance change. | FitLog calibration must be described as a rough, smoothed heuristic. |
| REF-ALG-12 | Youth / under-18 safety boundary | USPSTF Recommendation: High Body Mass Index in Children and Adolescents: Interventions. 2024. | `docs/Algorithm.md` age `< 18` deficit protection | Supports keeping children/adolescents outside simple adult-style calorie-restriction logic. | FitLog Local is not a pediatric treatment tool. |
| REF-ALG-13 | Periodized carbohydrate availability | Jeukendrup AE. "Periodized Nutrition for Athletes." Sports Med. 2017. PMID: 28332115. | `docs/Algorithm.md` carb cycling framing | Supports understanding carb cycling as a carbohydrate-availability / periodized-nutrition concept rather than a magic fat-loss mechanism. | Concept support only; does not justify FitLog multiplier defaults. |
| REF-ALG-14 | Periodized carb restriction evidence boundary | Gejl KD, et al. "Performance effects of periodized carbohydrate restriction in endurance-trained athletes: a systematic review and meta-analysis." Sports Med. 2021. PMID: 34001184. | `docs/Algorithm.md` carb cycling limitation note | Supports not overselling cyclical carbohydrate restriction as strong proof of better performance or fat loss. | Endurance-performance context only; not direct ordinary-fat-loss evidence. |
| REF-ALG-15 | Carbohydrate availability and training demands | Burke LM, Hawley JA, Wong SHS, Jeukendrup AE. "Carbohydrates for training and competition." J Sports Sci. 2011. PMID: 21660838. | `docs/Algorithm.md` carb cycling context | Supports that carbohydrate needs vary with training demands and session intensity. | Performance context only; not a universal prescription. |
| REF-ALG-16 | Protein preservation during training phases | Jager R, et al. "International Society of Sports Nutrition Position Stand: protein and exercise." J Int Soc Sports Nutr. 2017. PMID: 28642676. | `docs/Algorithm.md` taper design | Supports keeping protein as a higher-priority macro during taper reviews instead of making it the first reduction lever. | Broad range support only; does not prove every FitLog coefficient. |
| REF-ALG-17 | Rate-of-loss and protein context during prep | Helms ER, Aragon AA, Fitschen PJ. "Evidence-based recommendations for natural bodybuilding contest preparation." J Int Soc Sports Nutr. 2014. PMID: 24864135. | `docs/Algorithm.md` taper target-loss framing | Supports conservative loss-rate framing and preserving protein while energy intake is reduced. | Contest-prep population; not a universal consumer prescription. |
| REF-ALG-18 | Observational contest-prep macro shifts | Chappell AJ, Simper T, Barker ME. "Nutritional strategies of high level natural bodybuilders during competition preparation." J Int Soc Sports Nutr. 2018. PMID: 29371857. | `docs/Algorithm.md` taper context note | Supports the observation that carbs and fats often trend down while protein stays relatively high during prep phases. | Observational only; not causal proof or a general rule. |
| REF-ALG-19 | Dynamic weight-change limitation for taper review | Hall KD. "Why is the 3500 kcal per pound weight loss rule wrong?" Int J Obes. 2013. PMID: 23774459. | `docs/Algorithm.md` taper-review modeling limitation | Supports using rolling trend review and user confirmation instead of a naive fixed linear calorie-to-weight rule. | Supports limits of static rules, not FitLog's exact taper step size. |

Additional local-design note: current 2026-06 source of truth is the phase/mode matrix in which `daily_energy_goal_kcal` means deficit in `cutting + energy_ratio` and surplus in `bulking + energy_ratio`, while `gram_per_kg` remains independent from BMR, activity level, exercise kcal, and macro-ratio percentages. That matrix split is a local product design decision informed by the references above, not something directly dictated by a single paper.

## 4. Agent / AI Boundary References

Current local version has no true app-internal AI / LLM / Agent implementation.

Current local version only has:

- static prompt templates
- external AI JSON paste
- local JSON parsing
- deterministic local workflows

No Agent implementation references are needed for the current local version.

| Status | Local Version Fact | Reference Needed? | Reason |
| --- | --- | --- | --- |
| No app-internal AI/LLM | No OpenAI/Gemini API, no LLM SDK, no embedding/vector/RAG/tool calling | No | Internal code boundary, confirmed by current repository contents |
| External AI JSON paste | User manually pastes JSON generated outside the app | Optional / No | Product workflow, not app-internal AI implementation |
| Deterministic local workflows | Parser, summary, export, calibration, and self-check are local Dart workflows | No Agent reference | Algorithm and database docs already cover those deterministic systems |

## 5. Database and Engineering References

| REF ID | Topic | Source | Used In | Supports Local Design | Evidence Boundary |
| --- | --- | --- | --- | --- | --- |
| REF-DB-01 | SQLite local structured storage | SQLite official documentation / homepage. | `docs/Database.md` SQLite / local-first storage | Supports SQLite as a small, fast, self-contained, high-reliability embedded SQL database engine. | Supports the local embedded storage choice; does not validate every schema decision. |
| REF-DB-02 | Flutter SQLite persistence | Flutter docs, "Persist data with SQLite"; `sqflite` package documentation. | `docs/Database.md` `sqflite` usage | Supports `sqflite` and `path` as standard Flutter choices for SQLite persistence. | Supports package choice; schema and repository design remain project-specific. |
| REF-DB-03 | SharedPreferences for simple settings | Flutter `shared_preferences` package documentation. | `docs/Database.md` `language_code` storage | Supports SharedPreferences for simple persistent key-value pairs. | Not appropriate for complex relational business records. |
| REF-DB-04 | Repository pattern | Martin Fowler, Repository pattern. | `docs/Database.md` Repository / Service separation | Supports repository mediation between domain logic and data mapping/storage layers. | Engineering pattern reference only; this project has repositories but no separate DAO layer. |

## 6. Internal Design Decisions That Should Not Be Over-Cited

The following do not need external references in this local repository:

- Product page descriptions and normal UX behavior.
- Page names, button names, labels, and localization strings.
- File paths, class names, table names, and field names.
- `CHANGELOG.md` history and validation-status statements.
- Schema migration statements themselves.
- `diet_goal_phase` field name and enum names.
- `prefer_not_to_say` averaging rule.
- g/kg self-check thresholds and clamp/rounding logic.
- Strength calorie coefficients and density modifier.
- `DailySummary` being runtime-only rather than a persisted table.
- Future Agent/RAG/vector DB/semantic memory/AI Coach concepts that are not implemented in the local version.

## 7. Writing Style Notes

- Keep REF IDs stable and unique.
- Use references to support only the narrow claims they actually justify.
- Do not turn this file into a literature review.
- Do not claim stronger evidence than the cited sources support.
- When a rule is heuristic, bounded, or product-specific, label it that way.
- For any lingering old doc wording such as schema v5, cut-only, or deficit-only notes, treat the latest 2026-06 update as the source of truth.
