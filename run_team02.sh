#!/usr/bin/env bash

set -Eeuo pipefail

INVENTORY="inventory"
HOST_LIMIT="${HOST_LIMIT:-zoslab}"
SCP_ARGS="-O"
REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-main}"

echo "================================================"
echo " TEAM02 repository automation runner"
echo "================================================"

# Always run from the repository root.
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo
echo "================================================"
echo " Phase 1: Update local repository"
echo "================================================"

# Do not pull over local uncommitted changes.
if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: The repository has uncommitted changes."
  echo
  git status --short
  echo
  echo "Commit, stash, or restore those changes before running this script."
  exit 1
fi

echo "Fetching latest changes from $REMOTE..."
git fetch "$REMOTE"

echo "Updating local $BRANCH branch..."
git pull --ff-only "$REMOTE" "$BRANCH"

echo
echo "Repository is up to date."

echo
echo "================================================"
echo " Phase 2: Discover committed Ansible playbooks"
echo "================================================"

# Find committed YAML files that appear to be Ansible playbooks.
# Supporting YAML files and GitHub Actions workflows are excluded.
mapfile -t PLAYBOOKS < <(
  git ls-files '*.yml' '*.yaml' |
    grep -Ev '^\.github/' |
    grep -Ev '^(inventory|vars|templates)/' |
    grep -Ev '(^|/)(group_vars|host_vars)/' |
    while read -r file; do
      if grep -Eq '^[[:space:]]*-[[:space:]]+name:' "$file" &&
         grep -Eq '^[[:space:]]+hosts:' "$file"; then
        echo "$file"
      fi
    done |
    sort
)

if [[ ${#PLAYBOOKS[@]} -eq 0 ]]; then
  echo "ERROR: No committed Ansible playbooks were found."
  exit 1
fi

echo
echo "Committed playbooks found:"
printf '  - %s\n' "${PLAYBOOKS[@]}"

echo
echo "================================================"
echo " Phase 3: Syntax validation"
echo "================================================"

for playbook in "${PLAYBOOKS[@]}"; do
  echo
  echo "Syntax-checking: $playbook"

  ansible-playbook \
    -i "$INVENTORY" \
    "$playbook" \
    --syntax-check \
    --scp-extra-args="$SCP_ARGS"
done

echo
echo "All committed playbooks passed syntax validation."

echo
echo "================================================"
echo " Phase 4: Execute committed playbooks"
echo "================================================"

for playbook in "${PLAYBOOKS[@]}"; do
  echo
  echo "Running: $playbook"

  ansible-playbook \
    -i "$INVENTORY" \
    "$playbook" \
    --limit "$HOST_LIMIT" \
    --scp-extra-args="$SCP_ARGS"

  echo "Completed: $playbook"
done

echo
echo "================================================"
echo " All committed repository playbooks completed"
echo "================================================"