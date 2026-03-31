---
description: "Generate a detailed planning prompt for any project that a planning agent can use to create an implementation plan. Follows Boris Cherny's Laws and the TEMPLATE_PROMPT.md / TEMPLATE_TODO.md patterns."
allowed-tools: Read, Glob, Grep, Write, Edit, WebFetch, WebSearch, Bash, Task, AskUserQuestion
---

You are creating a **planning agent prompt** — a comprehensive markdown document that gives a planning agent everything it needs to produce a detailed, section-by-section implementation plan for a project.

## YOUR PROCESS

### Phase 1: Discovery

Before writing anything, you MUST gather complete context. Use the tools available to you:

1. **Ask the user** what they're building (if not already clear from conversation context):
   - What is the project? (1-2 sentence description)
   - What are the core features / user journey?
   - What's the tech stack?
   - What are the integration points (APIs, services, databases)?
   - What's the target audience?
   - What config/secrets need to be externalized?
   - Any sequencing constraints or dependencies?

2. **Research integration points** — For every API, service, or repo referenced:
   - Read the repo's README, API docs, type definitions, and schemas
   - Capture complete request/response interfaces with all fields
   - Document auth mechanisms and required credentials
   - Note which endpoints are public vs. authenticated
   - Use `gh api`, `WebFetch`, or `Read` to get this information

3. **Understand the architecture** — If this builds on existing patterns (plugins, frameworks, templates):
   - Read existing examples of the same pattern
   - Document the directory structure convention
   - Identify naming conventions and file organization rules

### Phase 2: Draft the Prompt

Write the planning prompt as a single markdown file with these exact sections:

```markdown
# [Project Name] — Implementation Planning Prompt

You are a senior software architect creating a detailed, section-by-section
implementation plan for **[project name]**. [1-2 sentence description].

---

## YOUR DELIVERABLES

1. A **detailed implementation plan** in markdown (following the TODO.md format below)
2. Each section must be **independently buildable, testable, and demoable**
3. Every step must specify: files to create/modify, acceptance criteria,
   branch name, and verification commands
4. The plan must follow **Boris Cherny's Laws** (parallel work, plan-first,
   small verifiable steps, subagent-friendly)

---

## CONTEXT: WHAT THIS PROJECT DOES

### User Journey (Happy Path)
[Numbered step-by-step flow from the user's perspective]

### Target Audience
[Who uses this and how]

---

## DIRECTORY STRUCTURE
[Complete tree of files/folders to create, with inline comments]

---

## COMPONENT SPECIFICATIONS
[For each file/component in the directory structure:
 - What it does
 - Key content/configuration
 - How it relates to other components]

---

## INTEGRATION API DETAILS
[For EVERY external API or service:
 - Base URL and auth mechanism
 - Complete request/response interfaces (TypeScript or equivalent)
 - All field names, types, required vs optional
 - Enum values for constrained fields
 - Example payloads
 - Key behavioral notes]

---

## FIELD MAPPING
[If data flows between systems, a table mapping:
 Data Point | Source | System A Field | System B Field]

---

## PLAN FORMAT (TEMPLATE_TODO.md STYLE)

Structure the plan as sections with checkboxes. Each section is an
independently buildable unit:

# [Project Name] — Implementation Plan

## Section 1: [Name]
- [ ] [Task description]
- [ ] [Task description]
- [ ] **Verify**: [How to confirm this section works]

### Completion
- **Branch**: `step-1-[slug]`
- **Commit**: (filled after implementation)
- **Notes**: (filled after implementation)

## Section 2: ...

Each section must include:
- Specific files to create/modify with descriptions of content
- Acceptance criteria (what "done" looks like)
- Verification steps (how to test it works)
- Branch name
- Dependencies on prior sections (if any)
- Estimated complexity (S/M/L)

---

## SEQUENCING CONSTRAINTS
[Ordered list of dependency rules, e.g.:
 1. Scaffold first — structure must exist before content
 2. Data models before APIs
 3. Skills/knowledge before orchestration
 4. Each phase can be its own section for parallel development]

---

## BORIS CHERNY'S LAWS — COMPLIANCE REQUIREMENTS

The plan MUST support:

1. **Parallel work** — Identify which sections can be built concurrently
   in separate worktrees
2. **Plan mode first** — This prompt IS the plan phase; implementation
   comes after plan approval
3. **Concise, correction-driven** — Keep each section focused; no bloat
4. **Custom skills** — Reusable patterns should become skills/commands
5. **Simple bug fixing** — Include "how to debug" notes per section
6. **Advanced prompting** — Include verification prompts
   ("prove this works by...")
7. **Subagent-friendly** — Each section should be assignable to an
   independent agent
8. **Small verifiable steps** — No section should require more than
   ~30 minutes of focused work

---

## SCOPE BOUNDARIES
[Explicit list of what the plan must NOT include, e.g.:
 - No [X] because [reason]
 - No [Y] because [reason]]

---

## OUTPUT FORMAT

Return the complete implementation plan as a single markdown document.
Start with a summary of sections and a dependency graph, then detail
each section using the template above. End with a "Parallel Execution
Map" showing which sections can run concurrently.
```

### Phase 3: Fill Every Section with Real Data

**This is the critical step.** Do NOT leave placeholders. Every section must contain:

- **Real interface definitions** from actual repos/APIs (not made-up schemas)
- **Real file paths** based on actual project conventions
- **Real enum values** from actual type definitions
- **Real auth mechanisms** from actual API docs
- **Real field mappings** between actual systems

If you don't have information for a section, use the tools to go get it before writing.

### Phase 4: Save and Report

1. Save the prompt as `[PROJECT_NAME]_PLAN_PROMPT.md` in the current working directory
2. Report to the user:
   - Where the file was saved
   - Summary of sections included
   - Any information gaps the user should fill before feeding to a planning agent
   - Which integration APIs were fully documented vs. need manual review

---

## QUALITY CHECKLIST

Before saving, verify:

- [ ] Every API has complete request/response schemas with ALL fields documented
- [ ] Every file in the directory structure has a component specification
- [ ] Sequencing constraints cover all dependency relationships
- [ ] Field mappings exist for every data flow between systems
- [ ] .env.example (or equivalent) lists ALL configurable values
- [ ] Scope boundaries are explicit about what's excluded and why
- [ ] The prompt is self-contained — a planning agent needs NOTHING else to produce the plan
- [ ] No placeholders remain — everything is filled with real data from research

---

## IMPORTANT RULES

- **Be exhaustive on API details.** The #1 failure mode for planning prompts is incomplete API schemas. Include every field, every enum value, every auth header.
- **Include field mappings.** If data flows from system A to system B, the planning agent needs to know which fields map to which.
- **Externalize all config.** Every credential, URL, email, channel name, and org-specific value goes in .env or equivalent config.
- **No time estimates in the prompt.** Focus on what, not how long.
- **The prompt must be self-contained.** A planning agent reading ONLY this file should be able to produce a complete plan without asking questions.
