#!/usr/bin/env bash
#===============================================================================
# env_utils.sh
#-------------------------------------------------------------------------------
# A reusable Bash library for:
#   1. Structured logging (stdout+stderr capture, error trapping, cleanup)
#   2. Shell detection and profile file selection (Bash vs Zsh)
#   3. Interactive confirmation before modifying user dot-files
#-------------------------------------------------------------------------------
# Usage:
#   In your script, before any commands you want logged:
#     source "/path/to/env_utils.sh"
#     init_logging
#     detect_source_file
#     # ... your script logic ...
#     finalize_logging
#-------------------------------------------------------------------------------
# Guard against double-sourcing
if [[ "${ENV_UTILS_LOADED:-}" == "1" ]]; then
  return
fi
ENV_UTILS_LOADED=1

#-------------------------------------------------------------------------------
# VARIABLES
#-------------------------------------------------------------------------------
# LOGFILE: Path where stdout and stderr will be captured. Can be overridden before sourcing.
: ${LOGFILE:="/tmp/$(basename "$0").log"}
# error_occurred: Flag (0|1) indicating if any command failed during execution.
error_occurred=0
# SOURCE_FILE: Shell profile file to update (set by detect_source_file()).
SOURCE_FILE=""
# ENVIRONMENT_DIR: Directory to store per-tool environment scripts. Exported so that
# other scripts sourcing this library can reference it.
: ${ENVIRONMENT_DIR:="${HOME}/.environments"}


#-------------------------------------------------------------------------------
# COLOR CODES & HELPERS
#-------------------------------------------------------------------------------
# ANSI color codes: prompt (bold black), logs (light gray), reset
: ${COLOR_RESET:=$'\e[0m'}
: ${COLOR_LOG:=$'\e[90m'}
: ${COLOR_PROMPT:=$'\e[1;30m'}
: ${COLOR_INFO:=$'\e[34m'}   # blue for important info
: ${COLOR_ERR:=$'\e[3;31m'}  # 3 = italic, 31 = red
# Helper to print logs in light gray
log() {
    printf "%b%s%b\n" "$COLOR_LOG" "$*" "$COLOR_RESET"
}
# Helper to print prompts in bold black without newline
prompt() {
    printf "%b%s%b\n" "$COLOR_PROMPT" "$*" "$COLOR_RESET"
}
# Helper to print important info in blue without newline
info() {
  printf "%b%s%b\n" "$COLOR_INFO" "$*" "$COLOR_RESET"
}
# Helper to print errors in red italic without newline
err() {
  printf "%b%s%b\n" "$COLOR_ERR" "$*" "$COLOR_RESET"
}


#-------------------------------------------------------------------------------
# FUNCTION: init_logging
#-------------------------------------------------------------------------------
# Sets up:
#   - Redirection of all stdout & stderr through tee to LOGFILE
#   - ERR trap to mark failures and record timestamp, script, line
#   - Startup banner with script name, timestamp, and log location
#-------------------------------------------------------------------------------
init_logging() {
  # Redirect future stdout & stderr into log and console
  exec > >(tee -a "${LOGFILE}") 2>&1

  # Trap on any error to record details
  trap '
    errcode=$?
    error_occurred=1
    echo "$(date +"%Y-%m-%d %H:%M:%S") ERROR in ${BASH_SOURCE[0]} at line ${LINENO}: exit status ${errcode}. See log at ${LOGFILE}" >&2
  ' ERR

  # Print startup banner
  log "=== Starting $(basename "$0") at $(date +"%Y-%m-%d %H:%M:%S") ==="
  log "All output (stdout & stderr) is being logged to: ${LOGFILE}"
}


#-------------------------------------------------------------------------------
# FUNCTION: ensure_env_dir
#-------------------------------------------------------------------------------
# Ensures that a directory for environment scripts exists.
# Uses ENVIRONMENT_DIR variable (defaulting to ~/.environments).
# Call this before creating per-tool env files.
#-------------------------------------------------------------------------------
ensure_env_dir() {
  if [[ ! -d "${ENVIRONMENT_DIR}" ]]; then
    log "Creating environment directory ${ENVIRONMENT_DIR}"
    mkdir -p "${ENVIRONMENT_DIR}"
  fi
}




#-------------------------------------------------------------------------------
# FUNCTION: enable_command_tracing
#-------------------------------------------------------------------------------
# Enables logging of each command executed, with timestamp and location.
# Sets PS4 to include date/time, script name, and line number, then turns on xtrace.
# Use after init_logging to log commands in the logfile.
#-------------------------------------------------------------------------------
enable_command_tracing() {
  export PS4='+ $(date "+%Y-%m-%d %H:%M:%S") ${BASH_SOURCE[0]}:${LINENO}: '
  set -o xtrace
}

#-------------------------------------------------------------------------------
# FUNCTION: detect_source_file
#-------------------------------------------------------------------------------
# Detects the user's login shell via $SHELL, sets SOURCE_FILE accordingly:
#   - Bash => ~/.bash_profile
#   - Zsh  => ~/.zprofile
# If detection fails, prompts user for the desired profile file path.
# Then confirms with the user before modifying that file.
#-------------------------------------------------------------------------------
detect_source_file() {
  local user_shell response
  user_shell="$(basename "${SHELL:-}" )"

  case "${user_shell}" in
    zsh)  SOURCE_FILE="$HOME/.zshrc" ;;  # Zsh profile
    bash) SOURCE_FILE="$HOME/.bashrc" ;;  # Bash login profile
    *)
      log "⚠️  Could not auto-detect your shell; defaulting to ~/.profile"
      SOURCE_FILE="$HOME/.profile"
      ;;
  esac

  # Confirm before writing
  echo
  info "The script will append environment sourcing to: ${SOURCE_FILE}"
  prompt "Is that OK? \[y/N]: "
  read -r response
  if [[ ! "${response}" =~ ^[Yy] ]]; then
    log "Aborting — no changes made."
    exit 1
  fi
}

# detect_source_file() {
#   local real_user real_home user_shell
#   # If run under sudo, use SUDO_USER; else current USER
#   real_user="${SUDO_USER:-$USER}"
#   real_home="$(eval echo ~${real_user})"
#   user_shell="$(basename "$(eval echo \$SHELL)")"

#   case "${user_shell}" in
#     zsh)  SOURCE_FILE="${real_home}/.zshrc" ;;     # Zsh config
#     bash) SOURCE_FILE="${real_home}/.bashrc" ;;   # Bash config
#     *)     SOURCE_FILE="${real_home}/.profile" ;;  # Fallback
#   esac

#   # Confirm before writing
#   echo
#   info "The script will append environment sourcing to: ${SOURCE_FILE}"
#   prompt "Is that OK? \[y/N]: "
#   read -r response
#   if [[ ! "${response}" =~ ^[Yy] ]]; then
#     log "Aborting — no changes made."
#     exit 1
#   fi
# }


# Function to link root's shell config to the detected source file
link_root_source_file() {
  if [ "$(id -u)" -eq 0 ]; then
    local root_rc="/root/$(basename "$SOURCE_FILE")"
    echo "🔗 Linking $root_rc to $SOURCE_FILE"
    ln -sf "$SOURCE_FILE" "$root_rc"
  fi
}


#-------------------------------------------------------------------------------
# FUNCTION: finalize_logging
#-------------------------------------------------------------------------------
# Call at the end of your script. Based on the error flag:
#   - If no errors, deletes the log file and prints success message.
#   - If errors occurred, displays log location and prompts user to delete it.
#-------------------------------------------------------------------------------
finalize_logging() {
  if [[ ${error_occurred} -eq 0 ]]; then
    # Success: remove log to avoid clutter
    rm -f "${LOGFILE}"
    log "✅ No errors detected. Removed log file."
  else
    # Failure: preserve log for debugging, allow user to clean up
    echo
    log "⚠️  The script encountered errors. Detailed log is here: ${LOGFILE}"
    prompt "Would you like to delete the log file? \[y/N]: "
    read -r response
    if [[ "${response}" =~ ^[Yy] ]]; then
      rm -f "${LOGFILE}"
      log "🗑️  Log file deleted."
    else
      log "📝  Log file retained at: ${LOGFILE}"
    fi
  fi
}
