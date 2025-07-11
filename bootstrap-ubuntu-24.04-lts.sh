#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# Ubuntu 24.04 LTS Bootstrap Runner
# Executes modular scripts, resumes on failure.
# ----------------------------------------------------------------------------

STATE_FILE="$HOME/.bootstrap_state"
mkdir -p "$(dirname "$STATE_FILE")"

# Define steps in order: name:script-path
steps=(
  "ssh-server:./ubuntu-24.04-lts/ssh-server"
  "core:./ubuntu-24.04-lts/core.sh"
  "graphics-drivers:./ubuntu-24.04-lts/graphics-drivers.sh"
  "dbeaver:./ubuntu-24.04-lts/dbeaver.sh"
  "github-cli:./ubuntu-24.04-lts/github.sh"
  "docker:./ubuntu-24.04-lts/docker.sh"
  "kubernetes:./ubuntu-24.04-lts/kubernetes.sh"
  "ide:./ubuntu-24.04-lts/development-ide.sh"
  "terraform:./ubuntu-24.04-lts/terraform.sh"
  "misc-tools:./ubuntu-24.04-lts/misc-tools.sh"
)

# Load last completed step
last_completed=""
if [[ -f "$STATE_FILE" ]]; then
  last_completed=$(<"$STATE_FILE")
fi

resumed=false
for entry in "${steps[@]}"; do
  name=${entry%%:*}
  script=${entry#*:}
  if [[ "$resumed" == false ]]; then
    if [[ "$name" == "$last_completed" ]]; then
      # resume after this step
      resumed=true
      continue
    fi
    if [[ -n "$last_completed" ]]; then
      # skip until resume
      continue
    fi
    # no last completed, start from beginning
    resumed=true
  fi

  echo "--> Running step: $name"
  bash "$script"
  echo "$name" > "$STATE_FILE"
done

# Cleanup state on successful run
rm -f "$STATE_FILE"

echo

echo "✅ All bootstrap steps completed!"
