# Development Tools Management Scripts

This repository contains a collection of Bash scripts to manage development tools and SDK versions on macOS and Ubuntu 24.04 LTS Desktop. Each script shares common utilities via **env\_utils.sh** and focuses on automating installation, configuration, and version switching of various SDKs and tools.

## Scripts

| Script          | Description                                                                                                       |
| --------------- | ----------------------------------------------------------------------------------------------------------------- |
| `env_utils.sh`  | Core library: structured logging, shell detection, directory setup, colored output, command tracing, and cleanup. |
| `jdk-gradle.sh` | Installs and manages OpenJDK & Gradle via SDKMAN!.                                                                |
| `python.sh`     | Installs and manages Python versions via pyenv.                                                                   |
| `golang.sh`     | Installs and manages Go versions via ASDF.                                                                        |
| `bootstrap-ubuntu-24.04-lts.sh` | Bootstraps an Ubuntu 24.04 LTS desktop with KDE, development tools, containers, communication apps, and more. |

## env\_utils.sh

A shared Bash library providing:

* **Structured logging**: Redirects `stdout` & `stderr` through `tee` into `/tmp/<script>.log` by default, with error trapping and optional cleanup via `finalize_logging`.
* **Shell detection**: `detect_source_file` sets `$SOURCE_FILE` to the correct profile (`~/.bash_profile` or `~/.zprofile`), with interactive fallback.
* **Environment directory setup**: `ensure_env_dir` prepares `${ENVIRONMENT_DIR}` (defaulting to `~/.environments`) for per-tool env files.
* **Colored output helpers**:

  * `log`: light gray messages
  * `info`: blue important messages
  * `prompt`: bold black user prompts
  * `err`: red italic error messages
* **Command tracing**: `enable_command_tracing` logs each executed command with timestamps and locations.
* **Cleanup**: `finalize_logging` removes or preserves the log based on success or errors.

### Usage Example

At the top of any managed script:

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env_utils.sh"
init_logging
detect_source_file
enable_command_tracing  # optional
ensure_env_dir
```

After your main logic, finalize:

```bash
# ... your script tasks ...
finalize_logging
```

## Compatibility

All scripts in this repository run unmodified on both:

* **macOS** (Bash 3.2+ via `/usr/bin/env bash`)
* **Ubuntu 24.04 LTS Desktop** (Bash 5.x and GNU coreutils)

Each script invokes only POSIX and Bash‐specific features, along with standard utilities (`tee`, `date`, `grep`, etc.). Package managers (Homebrew on macOS, `apt` on Ubuntu) may need to be installed manually or by external bootstrap scripts.


## License

MIT License. See [LICENSE](LICENSE) for details.
