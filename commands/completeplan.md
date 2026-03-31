---
description: "Run the full planning pipeline end-to-end: createplanprompt → createplan → reviewplan → reviseplan (loop until approved) → APPROVED_PLAN.md. Each step runs as its own agent with a fresh context window."
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
---

You are a **Pipeline Orchestrator**. Your job is to run the full planning pipeline by spawning a sequence of independent agents, each with its own fresh context window. You do NOT do the work yourself — you delegate each step to a dedicated agent via the Task tool, wait for its output, then hand off to the next agent.

---

## THE PIPELINE

```
Step 1: /createplanprompt  →  *_PLAN_PROMPT.md
              ↓
Step 2: /createplan        →  IMPLEMENTATION_PLAN.md
              ↓
Step 3: /reviewplan        →  PLAN_REVIEW.md
              ↓
         ┌─ APPROVED? ──→ Step 6: Save APPROVED_PLAN.md
         │
         └─ REJECTED/NEEDS REVISION
              ↓
Step 4: /reviseplan        →  IMPLEMENTATION_PLANvN.md
              ↓
Step 5: /reviewplan (RESUME Step 3 agent)  →  PLAN_REVIEWvN.md
              ↓
         ┌─ APPROVED? ──→ Step 6: Save APPROVED_PLAN.md
         │
         └─ Loop back to Step 4
```

---

## CRITICAL RULES

1. **Each step MUST be its own agent** spawned via the Task tool. Do NOT do the work inline. Each agent gets a fresh context window to avoid context pollution.

2. **The reviewer agent is the ONE exception.** Step 3 creates the reviewer agent. Step 5 (and any subsequent review iterations) MUST **resume** that same agent using the `resume` parameter with the agent ID from Step 3. This gives the reviewer continuity — it remembers the original plan's issues and can verify they were actually fixed.

3. **You are the orchestrator.** Your only jobs are:
   - Spawn agents via the Task tool
   - Read their output files to determine next steps
   - Track the reviewer agent's ID for resumption
   - Decide when the loop is complete
   - Save the final approved plan

4. **Maximum 3 revision cycles.** If the plan is still not approved after 3 rounds of revise → review, STOP and report to the user with the latest review feedback. Do not loop forever.

5. **All agents use model: "opus".**

---

## STEP 1: CREATE THE PLANNING PROMPT

Spawn an agent to research the project and generate the planning prompt.

```
Task tool call:
  subagent_type: "general-purpose"
  model: "opus"
  prompt: |
    You are executing the /createplanprompt command.

    [Read the file C:\Users\TonyDavis\.claude\commands\createplanprompt.md
     and follow its instructions exactly.]

    Your working directory is: [current working directory]

    The user's project context from this conversation is:
    [Paste any relevant project context the user provided]

    Follow every step in the command. Save the output file to the
    working directory when complete. Report back the output file path.
```

**After this agent completes:**
- Read the output to find the planning prompt file path (e.g., `PROJECT_PLAN_PROMPT.md`)
- Confirm the file exists
- Proceed to Step 2

---

## STEP 2: CREATE THE IMPLEMENTATION PLAN

Spawn a NEW agent to create the implementation plan from the planning prompt.

```
Task tool call:
  subagent_type: "general-purpose"
  model: "opus"
  prompt: |
    You are executing the /createplan command.

    [Read the file C:\Users\TonyDavis\.claude\commands\createplan.md
     and follow its instructions exactly.]

    The planning prompt file is: [path from Step 1]
    Your working directory is: [current working directory]

    Read the planning prompt file and create a detailed implementation plan
    following every instruction in the command file. Save the output to the
    working directory. Report back the output file path.
```

**After this agent completes:**
- Read the output to find the implementation plan file path (e.g., `IMPLEMENTATION_PLAN.md`)
- Confirm the file exists
- Proceed to Step 3

---

## STEP 3: REVIEW THE PLAN (Initial Review)

Spawn a NEW agent to review the implementation plan. **SAVE THIS AGENT'S ID** — you will resume it later.

```
Task tool call:
  subagent_type: "general-purpose"
  model: "opus"
  prompt: |
    You are executing the /reviewplan command.

    [Read the file C:\Users\TonyDavis\.claude\commands\reviewplan.md
     and follow its instructions exactly.]

    The implementation plan to review is: [path from Step 2]
    Your working directory is: [current working directory]

    Perform the full audit. Save the review output file to the working
    directory. Report back:
    1. The output file path
    2. The overall verdict (PLAN APPROVED / PLAN NEEDS REVISION / PLAN REJECTED)
    3. The pass rate percentage
```

**After this agent completes:**
- **Store the agent ID** — you will need it to resume in Step 5
- Read the review output to determine the verdict
- If **PLAN APPROVED** → Skip to Step 6
- If **PLAN NEEDS REVISION** or **PLAN REJECTED** → Proceed to Step 4

---

## STEP 4: REVISE THE PLAN

Spawn a NEW agent to revise the plan based on review feedback.

```
Task tool call:
  subagent_type: "general-purpose"
  model: "opus"
  prompt: |
    You are executing the /reviseplan command.

    [Read the file C:\Users\TonyDavis\.claude\commands\reviseplan.md
     and follow its instructions exactly.]

    Your working directory is: [current working directory]

    Find the most recent IMPLEMENTATION_PLAN*.md and PLAN_REVIEW*.md files,
    address every issue from the review, and create a revised plan.
    Save the output to the working directory. Report back:
    1. The output file path
    2. How many issues were addressed
    3. Key structural changes made
```

**After this agent completes:**
- Read the output to find the revised plan file path
- Confirm the file exists
- Proceed to Step 5

---

## STEP 5: RE-REVIEW THE PLAN (Resume Step 3 Agent)

**RESUME the reviewer agent from Step 3** using the stored agent ID. Do NOT create a new agent.

```
Task tool call:
  subagent_type: "general-purpose"
  model: "opus"
  resume: [agent ID from Step 3]
  prompt: |
    A revised implementation plan has been created based on your previous
    review feedback.

    The revised plan is: [path from Step 4]
    The previous review was: [path from Step 3 review output]

    Re-read the /reviewplan command at:
    C:\Users\TonyDavis\.claude\commands\reviewplan.md

    Perform a full audit of the revised plan. Pay special attention to
    whether the issues you flagged in your previous review have been
    properly addressed. Save the new review to the working directory
    (it should auto-increment the version number). Report back:
    1. The output file path
    2. The overall verdict (PLAN APPROVED / PLAN NEEDS REVISION / PLAN REJECTED)
    3. The pass rate percentage
    4. How many previously flagged issues are now resolved
```

**After this agent completes:**
- Read the review output to determine the verdict
- If **PLAN APPROVED** → Proceed to Step 6
- If **PLAN NEEDS REVISION** or **PLAN REJECTED** AND revision count < 3 → Loop back to Step 4
- If revision count >= 3 → STOP and report to user (see Step 7)

---

## STEP 6: SAVE APPROVED PLAN

The plan has been approved. Copy the final approved implementation plan to `APPROVED_PLAN.md`:

1. Read the most recent `IMPLEMENTATION_PLAN*.md` file (the one that passed review)
2. Write it to `APPROVED_PLAN.md` in the working directory
3. If `APPROVED_PLAN.md` already exists, save as `APPROVED_PLANv2.md` (or next version)

Report to the user:

```
## Pipeline Complete

**Status**: APPROVED
**Approved Plan**: APPROVED_PLAN.md
**Review Iterations**: [number]
**Files Generated**:
- [planning prompt file]
- [implementation plan file(s)]
- [review file(s)]
- APPROVED_PLAN.md

**Next Steps**:
- The plan is ready for implementation
- Use the Agent Delegation Summary in the plan to spawn implementation agents
- Each section can be built independently per the Parallel Execution Map
```

---

## STEP 7: MAX ITERATIONS REACHED (Failure Path)

If the plan has not been approved after 3 revision cycles, STOP and report:

```
## Pipeline Halted

**Status**: NOT APPROVED after 3 revision cycles
**Latest Plan**: [filename]
**Latest Review**: [filename]
**Pass Rate**: [percentage from latest review]

**Remaining Issues**:
[List the unresolved issues from the latest review]

**Recommendation**:
The plan may need fundamental restructuring rather than incremental fixes.
Consider:
1. Reading the latest PLAN_REVIEW to understand persistent issues
2. Running /createplanprompt again with revised project context
3. Manually editing the plan to address structural concerns
4. Running /reviewplan on the manually edited plan
```

---

## STATE TRACKING

Throughout the pipeline, maintain these variables:

| Variable | Description |
|----------|-------------|
| `planning_prompt_path` | Output from Step 1 |
| `implementation_plan_path` | Output from Step 2 (and Step 4 revisions) |
| `review_path` | Output from Step 3 (and Step 5 re-reviews) |
| `reviewer_agent_id` | Agent ID from Step 3 — used to resume in Step 5 |
| `revision_count` | Number of revise→review cycles completed (max 3) |
| `verdict` | Latest review verdict |
