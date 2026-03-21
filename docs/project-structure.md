# Project structure

## Repository layout

- `Dockerfile`: Container image definition.
- `scripts/`: Runtime and developer scripts.
- `examples/`: Production-minded example run scripts.
- `docs/`: Focused operational and configuration docs.
- `.github/workflows/`: CI and release automation.

## Script naming conventions

- `scripts/start_server.sh`: Primary container entrypoint logic.
- `scripts/download_jar.sh`: Jar download and verification helper.
- `scripts/lib.sh`: Shared POSIX shell utilities for runtime scripts.
- `scripts/validate.sh`: Local CI-equivalent validation checks.
- `examples/run-*.sh`: User-facing launchers with editable config blocks.

## Why this structure

- Runtime logic is kept small and auditable.
- Developer/CI checks use one entrypoint (`scripts/validate.sh`).
- User-facing examples avoid duplicated helper code.
- Documentation is split by intent: configure, operate, extend.
- Runtime internals are documented in `docs/runtime-reference.md`.
