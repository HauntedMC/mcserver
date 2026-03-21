#!/usr/bin/env bash
set -euo pipefail

# Local validation entrypoint used by contributors and CI.
# It checks:
# 1) shell syntax for POSIX/Bash scripts
# 2) shellcheck linting when available
# 3) optional Docker image build smoke test

usage() {
  cat <<'EOF'
Usage: ./scripts/validate.sh [options]

Options:
  --require-shellcheck   Fail if shellcheck is not installed
  --with-docker-build    Run a docker build validation step
  -h, --help             Show this help text
EOF
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_shellcheck="false"
with_docker_build="false"

# Parse options before running checks so callers can control strictness.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --require-shellcheck)
      require_shellcheck="true"
      shift
      ;;
    --with-docker-build)
      with_docker_build="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

posix_scripts=(
  scripts/lib.sh
  scripts/download_jar.sh
  scripts/start_server.sh
)

bash_scripts=(
  build.sh
  update_version.sh
  scripts/validate.sh
  examples/run-minecraft-server.sh
  examples/run-proxy-server.sh
)

# Basic parser checks catch syntax regressions before lint/build steps.
echo "Validating POSIX shell script syntax..."
for file in "${posix_scripts[@]}"; do
  sh -n "$file"
done

echo "Validating Bash script syntax..."
for file in "${bash_scripts[@]}"; do
  bash -n "$file"
done

# Static linting adds semantic checks beyond parser-only validation.
if command -v shellcheck >/dev/null 2>&1; then
  echo "Running shellcheck..."
  shellcheck "${posix_scripts[@]}" "${bash_scripts[@]}"
elif [[ "$require_shellcheck" == "true" ]]; then
  echo "shellcheck is required but not installed." >&2
  exit 1
else
  echo "shellcheck not found; skipping lint step."
fi

# Optional image build smoke test to validate Dockerfile and copied scripts.
if [[ "$with_docker_build" == "true" ]]; then
  echo "Building Docker image for validation..."
  docker build --pull --build-arg UID=10001 --build-arg GID=10001 -t mcserver:test .
fi

echo "Validation completed successfully."
