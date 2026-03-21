# Complete Pipeline

A Claude Code skill that chains 8 development phases into a single end-to-end workflow: from planning prompt to deployed, tested, production-verified code.

```
/full-pipeline
```

One command. Idea to production.

## What It Does

```
Phase 0: /protectrepo         Verify branch protection (main <-- dev <-- feature)
Phase 1: /completeplan        Plan, review, revise until approved
Phase 2: /plan-design-review  UI/UX review of the plan (skipped if no UI)
Phase 3: /makeprompts         Decompose plan into per-step agent prompts
Phase 4: /build               Execute steps sequentially, PRs to development
Phase 5: /design-review       Visual QA on development branch
Phase 6: /qa                  Systematic testing on development branch
Phase 7: /ship                Merge development to main (only after QA passes)
Phase 8: /browse              Post-deploy smoke test on production
```

Each phase has a gate check. If any phase fails, the pipeline stops and reports the failure. No broken code reaches production.

## Git Workflow

The pipeline enforces a strict branching model:

```
feature branches --> development --> main
                         |              |
                    QA happens      production
                      here          deploys here
```

- All implementation work happens on **feature branches** in isolated git worktrees
- Feature branches merge to **development** via reviewed PRs
- Design review and QA run against **development**
- Only after QA passes does `/ship` merge **development to main**
- Production deploys automatically on merge to main

## Prerequisites

### Required Tools

| Tool | Purpose | Install |
|------|---------|---------|
| [Claude Code](https://claude.ai/code) | AI coding agent | `npm i -g @anthropic-ai/claude-code` |
| [GitHub CLI](https://cli.github.com/) | PR creation, merging | `gh auth login` |
| [gstack](https://github.com/AskGarry/gstack) | Browse, QA, design review, ship skills | See gstack repo |
| Git | Version control | Pre-installed on most systems |

### Required Skills (installed via gstack or user-level)

The pipeline invokes these skills in sequence. All must be available:

| Skill | Source | Purpose |
|-------|--------|---------|
| `/completeplan` | User-level (`~/.claude/skills/`) | Planning pipeline |
| `/createplanprompt` | User-level | Generate planning prompt |
| `/createplan` | User-level | Generate implementation plan |
| `/reviewplan` | User-level | Audit plan for correctness |
| `/reviseplan` | User-level | Fix plan review issues |
| `/makeprompts` | User-level | Decompose plan into agent prompts |
| `/build` | User-level | Execute prompts with agents |
| `/plan-design-review` | gstack | Design review in plan mode |
| `/design-review` | gstack | Visual QA on live site |
| `/qa` | gstack | Systematic QA testing |
| `/ship` | gstack | Version bump, changelog, merge to main |
| `/browse` | gstack | Headless browser verification |

### Repository Setup

Your repository should have:

1. A `development` branch (the pipeline targets this for all feature PRs)
2. Branch protection on `main` (only `development` can merge to it)
3. A remote on GitHub (`gh repo view` must work)

To set this up automatically:

```bash
/protectrepo
```

## Installation

### Option 1: Copy to user skills (recommended)

```bash
# Clone this repo
git clone https://github.com/lendtrain/complete-pipeline.git

# Copy the skill to your Claude Code skills directory
cp -r complete-pipeline ~/.claude/skills/full-pipeline
```

### Option 2: Symlink

```bash
git clone https://github.com/lendtrain/complete-pipeline.git ~/Projects/complete-pipeline
ln -s ~/Projects/complete-pipeline ~/.claude/skills/full-pipeline
```

### Verify Installation

Start a new Claude Code session and check the skill appears:

```
> /full-pipeline
```

Or say: "run the full pipeline"

## Usage

### Basic Usage

```
> /full-pipeline
```

Claude will ask for a feature description or spec, then run all 8 phases automatically.

### With a Spec

```
> /full-pipeline Build a user authentication system with JWT tokens,
  refresh tokens, and role-based access control
```

### Resume After Interruption

If the pipeline was interrupted (crash, timeout, etc.), just run it again:

```
> /full-pipeline
```

It detects existing artifacts (`APPROVED_PLAN.md`, `prompts.md`, `TODO.md`) and resumes from the first incomplete phase.

### Skip Phases

If you already have an approved plan:

```
> I have an approved plan at APPROVED_PLAN.md.
  Run /makeprompts then /build then /qa then /ship
```

## Pipeline Details

### Phase 1: Plan (`/completeplan`)

Generates a detailed, section-by-section implementation plan using the full planning pipeline:

1. Gathers context about the project (APIs, schemas, architecture)
2. Generates a planning prompt with all specifications
3. Produces an implementation plan with sections, dependencies, and parallel execution groups
4. Reviews every section for buildability, testability, demoability, and correct sequencing
5. Revises until the review passes with 100% approval

**Output:** `APPROVED_PLAN.md`

### Phase 2: Plan Design Review (`/plan-design-review`)

Reviews the plan's UI/UX components before any code is written. Rates design dimensions (layout, typography, color, spacing, interaction, accessibility) on a 0-10 scale.

**Skipped** if the plan has no UI components (pure API/backend).

### Phase 3: Generate Prompts (`/makeprompts`)

Decomposes the approved plan into one self-contained agent prompt per implementation step. Each prompt includes:

- Complete implementation instructions
- Type definitions and API schemas inline
- Git workflow (branch, commit, push, PR)
- Acceptance criteria and verification commands
- Scope boundaries

**Output:** `prompts.md`

### Phase 4: Build (`/build`)

Executes each prompt sequentially (one agent at a time):

- Each agent runs in an isolated git worktree
- Creates a feature branch from `development`
- Implements the step, updates `TODO.md`
- Pushes and creates a PR targeting `development`
- PR is reviewed (scope, secrets, compliance) before merging
- Next agent only starts after the current PR is merged

### Phase 5: Design Review on Development (`/design-review`)

Visual QA on the development branch. Finds and fixes:

- Visual inconsistencies
- Spacing and alignment issues
- Hierarchy problems
- AI-generated design patterns ("AI slop")

Fixes are committed to development via feature branch PRs.

### Phase 6: QA on Development (`/qa`)

Systematic testing on the development branch:

- Navigates every reachable page
- Tests all interactive elements
- Checks console for errors
- Documents issues with screenshots
- Fixes bugs with atomic commits
- Produces a health score report

**Gate:** Health score must be >= 80 and no critical issues remain.

### Phase 7: Ship (`/ship`)

Only runs after QA passes on development:

- Runs final tests
- Reviews the full diff (development vs main)
- Bumps VERSION and updates CHANGELOG
- Creates release PR (development to main)
- Merges after review

### Phase 8: Browse Verification (`/browse`)

Post-deploy smoke test on the live production site:

- Navigates key pages
- Takes screenshots
- Verifies all core user flows
- Confirms production matches what was tested on development

## Lessons Learned

This skill was built during a real 16-step implementation across two repositories. Key learnings baked in:

1. **Sequential agents, not parallel.** Parallel agents consume too much memory and crash or stall. One agent at a time is faster in practice.

2. **QA before ship, not after.** All testing happens on `development`. Only clean, tested code gets merged to `main`.

3. **Gate checks matter.** Every phase must pass before the next begins. No cascading failures.

4. **TODO.md is the source of truth.** Every agent updates it. Enables resume after interruption.

5. **Feature branches only.** Never commit directly to `main` or `development`. All work goes through PRs.

## License

MIT
