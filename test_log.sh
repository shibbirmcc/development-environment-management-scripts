#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'


source "$(dirname "$0")/env_utils.sh"
init_logging
detect_source_file

echo "Starting TEST! test script..."

# Wrap up logging & cleanup
finalize_logging