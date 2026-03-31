---
description: "Revise a rejected implementation plan based on review feedback. Reads the most recent IMPLEMENTATION_PLAN and PLAN_REVIEW files, addresses every issue, and creates a new version."
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
---

You are a planning agent. Your job is to create a revised implementation plan that addresses every issue raised in a plan review.

## STEP 1: FIND THE MOST RECENT FILES

Search the current working directory for all versions of the implementation plan and plan review:

**Implementation plans:** Look for `IMPLEMENTATION_PLAN.md`, `IMPLEMENTATION_PLANv2.md`, `IMPLEMENTATION_PLANv3.md`, etc. Use the **highest version number** as the plan that was rejected.

**Plan reviews:** Look for `PLAN_REVIEW.md`, `PLAN_REVIEWv2.md`, `PLAN_REVIEWv3.md`, etc. Use the **highest version number** as the review containing the feedback to address.

If no implementation plan or plan review is found, tell the user: "No implementation plan or review found. Run `/createplan` and `/reviewplan` first."

Read both files in full.

## STEP 2: DETERMINE OUTPUT FILE NAME

Check the current working directory for existing implementation plan files and pick the next version:

- If only `IMPLEMENTATION_PLAN.md` exists → save as `IMPLEMENTATION_PLANv2.md`
- If `IMPLEMENTATION_PLANv2.md` exists → save as `IMPLEMENTATION_PLANv3.md`
- Continue incrementing until you find a version that does not exist

## STEP 3: SCAN FOR ADDITIONAL CONTEXT

Check the current working directory for any additional files that may inform the revised plan:

- `*_PLAN_PROMPT.md` — the original planning prompt with full API schemas, architecture, and constraints
- `*.xlsx`, `*.xls`, `*.csv` — data files (rate sheets, spreadsheets) referenced by the plan
- `CLAUDE.md` — project conventions and coding standards
- `.env.example`, `.env` — configuration values
- `README.md` — project overview

Read any files that are relevant to the issues raised in the review.

## STEP 4: SUMMARIZE BEFORE REVISING

Before writing the new plan, output a summary:

```markdown
## Revision Summary

### Plan Being Revised
- **File**: [filename of rejected plan]
- **Review**: [filename of review with feedback]
- **Review Verdict**: [REJECTED / NEEDS REVISION]
- **Pass Rate**: [from review]

### Key Problems with the Original Plan
1. [Problem from review]
2. [Problem from review]
3. [Problem from review]
...

### How Each Problem Will Be Addressed
| Problem | Fix |
|---------|-----|
| [Problem 1] | [How the revised plan fixes it] |
| [Problem 2] | [How the revised plan fixes it] |
| ... | ... |

### Structural Changes
- [Any sections being added, removed, reordered, or split]
```

## STEP 5: CREATE THE REVISED PLAN

Write the new implementation plan that:

1. **Addresses every issue raised in the review** — Do not skip any. If the review flagged a dependency problem, fix the dependency. If it flagged a testability gap, add verification steps. If it flagged a missing step, add the step.

2. **Follows the structure requirements the reviewer specified** — If the review said steps need acceptance criteria, add them. If it said the first step must produce a running artifact, ensure it does.

3. **Ensures each step can be built, tested, and committed independently** — Every section must have:
   - Specific files to create/modify
   - Acceptance criteria
   - Verification commands with expected output
   - Branch name
   - Dependencies on prior sections
   - Complexity estimate (S/M/L)
   - "How to Debug" notes
   - Completion block (branch, commit, notes, deviations, next)

4. **Preserves what worked** — If the review approved certain steps, keep them (with any minor fixes noted). Don't rewrite the entire plan if only parts were rejected.

5. **Adds a revision log at the top** — Document what changed and why:

```markdown
## Revision Log
- **Previous version**: [filename]
- **Review**: [filename]
- **Changes made**:
  - [Change 1 — addresses review issue X]
  - [Change 2 — addresses review issue Y]
  - [Change 3 — addresses review issue Z]
```

## STEP 6: SAVE AND REPORT

1. Save the revised plan to the determined output file name
2. Report to the user:
   - Output file path
   - Number of issues addressed from the review
   - Key structural changes made
   - Suggest running `/reviewplan` again to validate the revision
