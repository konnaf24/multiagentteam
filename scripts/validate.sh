#!/usr/bin/env sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

required_files="
AGENTS.md
README.md
.github/copilot-instructions.md
.github/agents/network-engineer.agent.md
.github/agents/network-researcher.agent.md
.github/agents/adversarial-reviewer.agent.md
docs/templates/CASE.md
docs/templates/CLAIMS.md
docs/templates/TASK.md
docs/templates/FINDING.md
docs/templates/REVIEW.md
scripts/new-case.sh
"

for path in $required_files; do
  if [ ! -f "$repo_root/$path" ]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
done

for agent in network-engineer network-researcher adversarial-reviewer; do
  agent_file="$repo_root/.github/agents/$agent.agent.md"
  if ! grep -q "^name: $agent$" "$agent_file"; then
    echo "Agent name does not match filename: $agent_file" >&2
    exit 1
  fi
done

for template in "$repo_root"/docs/templates/*.md; do
  if grep -q '{{CASE_TITLE}}' "$template" &&
    ! grep -q '{{CASE_SLUG}}' "$template"; then
    echo "Case template lacks a case slug: $template" >&2
    exit 1
  fi
done

echo "Repository structure is valid."
