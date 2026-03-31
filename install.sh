#!/bin/bash
# Install Complete Pipeline and all dependencies
# Usage: ./install.sh

set -e

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Complete Pipeline..."
echo ""

# Create directories if they don't exist
mkdir -p "$SKILLS_DIR"
mkdir -p "$COMMANDS_DIR"

# Install the main skill
echo "Installing main skill: full-pipeline"
cp -r "$SCRIPT_DIR/SKILL.md" "$SKILLS_DIR/full-pipeline/" 2>/dev/null || {
  mkdir -p "$SKILLS_DIR/full-pipeline"
  cp "$SCRIPT_DIR/SKILL.md" "$SKILLS_DIR/full-pipeline/SKILL.md"
}

# Install commands
echo "Installing commands..."
for cmd in "$SCRIPT_DIR"/commands/*.md; do
  name=$(basename "$cmd")
  if [ ! -f "$COMMANDS_DIR/$name" ]; then
    cp "$cmd" "$COMMANDS_DIR/$name"
    echo "  Installed: $name"
  else
    echo "  Skipped (exists): $name"
  fi
done

# Install skills
echo "Installing skills..."
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
  name=$(basename "$skill_dir")
  if [ ! -d "$SKILLS_DIR/$name" ]; then
    cp -r "$skill_dir" "$SKILLS_DIR/$name"
    echo "  Installed: $name"
  else
    echo "  Skipped (exists): $name"
  fi
done

echo ""
echo "Installation complete!"
echo ""
echo "To verify, start a new Claude Code session and run:"
echo "  /full-pipeline"
echo ""
echo "Prerequisites:"
echo "  - Claude Code: npm i -g @anthropic-ai/claude-code"
echo "  - GitHub CLI: gh auth login"
echo "  - gstack (for browse/QA): https://github.com/AskGarry/gstack"
