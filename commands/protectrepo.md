---
description: "Set up branch protection for the current repo: create development branch, protect main and development with PR-only rules, set development as default branch."
---

# Protect Repo — Standard Branch Protection Setup

Set up Tony's standard branch protection workflow for the current repository.

## Workflow
```
feature/* → PR → development → PR → main
```

## Steps

1. **Detect the current repo** — get the owner/repo from `gh repo view`
2. **Check if `development` branch exists** — create it from main if not
3. **Push `development` to remote** if it doesn't exist remotely
4. **Create ruleset: Protect main** — require PRs, block direct pushes, no bypass actors
5. **Create ruleset: Protect development** — require PRs, block direct pushes, no bypass actors
6. **Set default branch to `development`** — so new PRs target development by default
7. **Checkout `development`** — leave the user on the working branch

## Implementation

Run these commands in sequence:

```bash
# Step 1: Get repo info
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# Step 2-3: Create and push development if needed
git fetch origin
if ! git show-ref --verify --quiet refs/remotes/origin/development; then
  git checkout -b development main 2>/dev/null || git checkout development
  git push -u origin development
else
  git checkout development 2>/dev/null || git checkout -b development origin/development
fi

# Step 4: Protect main
gh api repos/$REPO/rulesets --method POST --input - <<'RULES'
{
  "name": "Protect main — PRs only from development",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }
  ],
  "bypass_actors": []
}
RULES

# Step 5: Protect development
gh api repos/$REPO/rulesets --method POST --input - <<'RULES'
{
  "name": "Protect development — PRs only from feature branches",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/development"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }
  ],
  "bypass_actors": []
}
RULES

# Step 6: Set default branch
gh api repos/$REPO --method PATCH -f default_branch=development

# Step 7: Confirm
echo "Done. Branch protection applied to $REPO"
echo "  main: PRs only (no direct push)"
echo "  development: PRs only (no direct push)"
echo "  Default branch: development"
```

After running all steps, confirm the results to the user with the repo name and protection status.
