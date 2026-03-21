---
name: full-pipeline
description: This skill should be used when the user wants to run the full development pipeline end-to-end, from planning through deployment and QA. Chains 9 skills in sequence: /completeplan, /plan-design-review, /makeprompts, /build, push PRs, /ship, /design-review, /qa, /browse. Trigger phrases include "full pipeline", "plan to deploy", "build everything", "end to end build", "run the full pipeline", "plan build ship test".
---

# Full Pipeline: Plan to Production

Run the complete development pipeline from idea to deployed, tested, and verified production code. This skill orchestrates 9 phases sequentially, with gate checks between each phase.

## Prerequisites

- A git repository with a remote
- GitHub CLI (`gh`) authenticated
- A clear feature description or spec from the user

## Pipeline Phases

Execute each phase in order. After each phase, report status to the user before proceeding. If any phase fails, stop and report the failure — do not continue to the next phase.

### Phase 1: Plan (/completeplan)

Generate and approve the implementation plan.

```
Invoke Skill: completeplan
```

This runs the full planning pipeline:
1. `/createplanprompt` — gather context, research APIs, generate planning prompt
2. `/createplan` — produce detailed section-by-section implementation plan
3. `/reviewplan` — audit every step for dependencies, testability, sequence
4. `/reviseplan` — fix any review issues (loops until approved)
5. Output: `APPROVED_PLAN.md` (or highest version `IMPLEMENTATION_PLAN*.md` that passed review)

**Gate check:** Confirm the plan review passed with 100% approval rate. If not, loop revise/review until it does.

Report to user: "Phase 1 complete. Plan approved with [N] sections across [N] waves."

### Phase 2: Design Review (/plan-design-review)

Review the plan's UI/UX components before building.

```
Invoke Skill: plan-design-review
```

This reviews design dimensions (layout, typography, color, spacing, interaction, accessibility) and rates each 0-10. If any dimension scores below 7, the plan is revised to address design gaps.

**Gate check:** All design dimensions score 7+. If the plan has no UI components, skip this phase.

Report to user: "Phase 2 complete. Design review passed. [summary of scores]"

### Phase 3: Generate Prompts (/makeprompts)

Decompose the approved plan into per-step agent prompts.

```
Invoke Skill: makeprompts
```

Output: `prompts.md` (or highest version) with one self-contained prompt per implementation step, concurrency analysis, and wave execution order.

**Gate check:** Prompts file exists with one prompt per plan section. Verify no two concurrent prompts modify the same file.

Report to user: "Phase 3 complete. Generated [N] prompts across [N] waves."

### Phase 4: Build (/build)

Execute the implementation plan by spawning agents sequentially.

```
Invoke Skill: build
Args: prompts.md (or latest version)
```

**CRITICAL RULES (learned from experience):**
- Spawn agents ONE AT A TIME (sequential, not parallel) — parallel agents crash the machine
- Each agent runs in an isolated git worktree
- Each agent creates a feature branch, implements its step, updates TODO.md, pushes, and creates a PR
- After each agent completes: review the PR diff for scope/secrets/compliance, then merge
- Only advance to the next step after the current step's PR is merged
- All PRs target the `development` branch (never commit directly to main)

**Gate check:** All steps complete. All PRs merged to development. TODO.md fully updated.

Report to user: "Phase 4 complete. [N] steps built, [N] PRs merged. All tests passing."

### Phase 5: Design Review on Development (/design-review)

Run visual QA on the development branch BEFORE shipping to main. Start the dev server locally or use a staging/preview URL if available.

```
Invoke Skill: design-review
```

This finds visual inconsistencies, spacing issues, hierarchy problems, and AI slop patterns. Fixes are committed to development as atomic commits with before/after screenshots.

**Gate check:** No critical or high-severity visual issues remain. If the project has no UI (pure API/backend), skip this phase.

Report to user: "Phase 5 complete. [N] visual issues found, [N] fixed on development."

### Phase 6: QA on Development (/qa)

Systematic QA testing on development BEFORE shipping to main. All testing happens against the development branch — either via local dev server or staging URL.

```
Invoke Skill: qa
```

This runs the full test-fix-verify loop:
- Navigate every reachable page
- Test all interactive elements
- Check console for errors
- Document issues with screenshots
- Fix bugs with atomic commits (to development via feature branch PRs)
- Re-verify fixes
- Produce health score report

**Gate check:** Health score >= 80. No critical issues remain. All fixes merged to development.

Report to user: "Phase 6 complete. Health score: [N]/100. [N] issues found, [N] fixed, [N] deferred. Development is clean."

### Phase 7: Ship (/ship)

ONLY after QA passes on development. Merge development to main, bump version, update changelog.

```
Invoke Skill: ship
```

This handles:
- Running final tests on development
- Reviewing the full diff (development vs main)
- Bumping VERSION if it exists
- Updating CHANGELOG if it exists
- Creating the release PR (development to main)
- Merging `development` to `main` after review
- Deployment triggered automatically (Railway auto-deploys on merge to main)

**Gate check:** Release PR merged to main. Deployment triggered.

Report to user: "Phase 7 complete. Shipped to main. Deployment triggered."

### Phase 8: Browse Verification on Production (/browse)

Final verification on the LIVE production site after deployment completes.

```
Invoke Skill: browse
```

Navigate the deployed production site, take screenshots of key pages, verify all core user flows work end-to-end. This is the post-deploy smoke test confirming production matches what was tested on development.

**Gate check:** All core flows work on production. No broken pages or console errors. Production matches development behavior.

Report to user with screenshots: "Phase 8 complete. Production verified. All core flows working."

### Phase 9: Final Report

Compile and present the full pipeline report to the user:

```
## Full Pipeline Report

### Project: [name]
### Date: [date]
### Duration: [total time across all phases]

### Phase Results
| Phase | Skill | Status | Notes |
|-------|-------|--------|-------|
| 1. Plan | /completeplan | PASS | [N] sections, [N] waves |
| 2. Plan Design Review | /plan-design-review | PASS/SKIP | [scores or "no UI"] |
| 3. Prompts | /makeprompts | PASS | [N] prompts |
| 4. Build | /build | PASS | [N] PRs merged to development |
| 5. Visual QA (dev) | /design-review | PASS/SKIP | [N] fixes on development |
| 6. QA (dev) | /qa | PASS | Score: [N]/100 on development |
| 7. Ship | /ship | PASS | Merged development to main |
| 8. Browse (prod) | /browse | PASS | Production verified |

### Artifacts Created
- APPROVED_PLAN.md (or version)
- prompts.md (or version)
- TODO.md (updated)
- QA report at .gstack/qa-reports/
- [list of PRs merged]

### Known Issues / Deferred Items
- [any deferred items from QA or build]
```

## Error Handling

If any phase fails:
1. Stop the pipeline immediately
2. Report which phase failed and why
3. Provide the error details
4. Suggest the fix
5. Ask the user if they want to retry the failed phase or abort

Do NOT continue to subsequent phases after a failure. The pipeline is strictly sequential with gates.

## Resuming a Pipeline

If invoked when prior phases have already completed (detected via existing artifacts):
1. Check for `APPROVED_PLAN.md` / `IMPLEMENTATION_PLAN*.md` — skip Phase 1 if approved plan exists
2. Check for `prompts.md` — skip Phase 3 if prompts exist
3. Check TODO.md for completed steps — skip completed build steps in Phase 4
4. Report which phases are being skipped and why
5. Resume from the first incomplete phase
