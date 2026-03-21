# Contributing to mcserver

Thanks for helping improve `mcserver`.

## Getting started

1. Fork the repository and create a topic branch from the default branch.
2. Make focused changes with clear commit messages.
3. Run the relevant local checks before opening a pull request.
4. Open a pull request using the provided template.

## Development workflow

### Prerequisites

- Docker
- Bash
- A POSIX shell (`sh`)

### Useful commands

```bash
./scripts/validate.sh --with-docker-build
./build.sh --tag mcserver:local
```

## Pull request expectations

- Keep changes scoped and reviewable.
- Update documentation when behavior changes.
- Prefer extending existing docs under `docs/` rather than adding ad-hoc notes.
- Add or update workflows/templates/docs when repository process changes.
- Confirm shell scripts remain POSIX-compatible where applicable.

## Commit style

Human-readable commits are preferred. Conventional Commits are welcome but not required.

## Reporting security issues

Please do not open public issues for vulnerabilities. Follow [SECURITY.md](./SECURITY.md) instead.

## License

By contributing, you agree that your contributions will be licensed under the GNU Affero General Public License v3.0 or later.
