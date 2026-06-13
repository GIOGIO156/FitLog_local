# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

## FitLog Project Rules

- This is a Flutter + Dart local-first app.
- Always preserve current Local version behavior unless the task explicitly asks to change it.
- Do not introduce backend, cloud sync, account system, LLM API, vector database, RAG, or Agent loop unless explicitly requested.
- Preserve SQLite migrations and additive compatibility.
- Do not merge gram_per_kg and energy_ratio logic.
- diet_goal_phase is the source of truth for cutting/bulking phase.
- In gram_per_kg mode, macros are primary and kcal target is auxiliary only.
- In energy_ratio mode, kcal target/intake/remaining is primary.
- After code changes, run:
  - flutter analyze
  - flutter test
- For audit/refactor tasks, report risks before modifying code.

## FitLog Design Documentation Rules

Design docs are maintained as finished source-of-truth documents, not as running notes.

Required structure:

```text
README.md
CHANGELOG.md
docs/
  en/
    Product.md
    AppGuide.md
    Methodology.md
    Algorithm.md
    Database.md
    AgentDesign.md
    References.md
  zh/
    Product.md
    AppGuide.md
    Methodology.md
    Algorithm.md
    Database.md
    AgentDesign.md
    References.md
```

File responsibilities:

- `README.md`: project face and quick-start overview. Keep English first and Chinese second in the same file. The two language sections must match in facts, scope, commands, and links. Do not append date-based update sections.
- `CHANGELOG.md`: English only. Record dated changes under Added/Changed/Fixed/Validation style headings. Concise implementation details and engineering rationale are allowed when they explain a shipped fix. Do not store product design, architecture explanations, future notes, or agent memory here.
- `docs/en/Product.md` and `docs/zh/Product.md`: stable product design. Cover purpose, product principles, modules, workflows, UX behavior, implemented scope, non-goals, and code references. Do not write release notes here.
- `docs/en/AppGuide.md` and `docs/zh/AppGuide.md`: app-area guide. Explain what each app module does, how it works at a high level, and which design file to read for details. Keep it navigational; do not duplicate all Product/Algorithm/Database content.
- `docs/en/Methodology.md` and `docs/zh/Methodology.md`: user-facing method explanation. Explain why the app uses `energy_ratio`, `gram_per_kg`, carb cycling, carb tapering, net exercise calories, and strength calorie heuristics. Keep it understandable, evidence-aware, and honest about limitations.
- `docs/en/Algorithm.md` and `docs/zh/Algorithm.md`: stable algorithm design. Cover inputs, formulas, diet phase/mode/strategy separation, workout calorie logic, calibration, self-check, boundaries, and code references. Do not merge `gram_per_kg` and `energy_ratio`.
- `docs/en/Database.md` and `docs/zh/Database.md`: stable database design. Cover current schema version, additive migrations, tables, fields, runtime aggregates, data flows, export coverage, non-implemented storage capabilities, and code references. Preserve migration compatibility.
- `docs/en/AgentDesign.md` and `docs/zh/AgentDesign.md`: current AI/Agent boundary. State clearly that the local app has no internal LLM/API/Agent loop unless code actually adds one. External AI prompt copy and JSON paste are not app-internal AI.
- `docs/en/References.md` and `docs/zh/References.md`: evidence and citation boundaries. Keep reference IDs stable. Cite narrow claims only. Do not turn this file into a literature review or changelog.

Language and sync rules:

- `CHANGELOG.md` stays English only.
- `README.md` is bilingual in one file: English first, Chinese second, with matching content.
- All other design docs live in both `docs/en` and `docs/zh`; when one changes, update the other in the same task.
- Keep docs concise but complete: every important field, mode, formula, boundary, and non-goal must appear exactly where it belongs.
- New feature details should be integrated into the stable section they affect, not appended as "2026-xx update" blocks.
- Historical implementation details belong in `CHANGELOG.md`; durable design facts belong in `README.md` or `docs/*`.

Encoding and terminal-output rules:

- Markdown files are UTF-8.
- PowerShell or terminal output may display valid UTF-8 Chinese or symbols as mojibake. Do not treat terminal display mojibake as file corruption.
- Before changing text for suspected encoding issues, verify the actual file content by reading it as UTF-8, checking Unicode code points, or inspecting it in an editor that correctly renders UTF-8.
- Do not record a "garbled text fix" in `CHANGELOG.md` unless the source file or rendered app/docs are actually corrupted.
- Prefer ASCII punctuation in English docs when it does not reduce clarity; Chinese docs may use normal Chinese punctuation.
- For Chinese-heavy files or bilingual docs, first verify the real UTF-8 source content before editing; do not spend time "repairing" text based only on PowerShell or terminal mojibake.
- Keep edits small and surgical after encoding verification: apply the minimal patch, run a local targeted check when available, then run `flutter analyze`, `flutter test`, and build only after code changes are stable.

Validation for documentation-only changes:

- Confirm the required documentation tree exists.
- Run text searches for old root-level design docs, date-appended headings in stable docs, stale paths, and obvious replacement characters.
- Flutter analysis/tests are required after code changes; for documentation-only edits, do not run them unless the task also touched code.

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
