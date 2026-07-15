#!/usr/bin/env bash

set -Eeuo pipefail

INVENTORY="inventory"
HOST_LIMIT="${HOST_LIMIT:-zoslab}"
SCP_ARGS="-O"

echo "================================================"
echo " TEAM02 repository automation runner"
echo "================================================"

# Work only from the repository root.
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Select only YAML files committed to Git that can be playbooks.
# Inventory files, variable files, and templates are supporting inputs,
# so they are not independently executed.
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
echo " Phase 1: Syntax validation"
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
echo " Phase 2: Execute committed playbooks"
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
