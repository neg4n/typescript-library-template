# Contributing

## Development Workflow

1. Create a feature branch from `main`
2. Make your changes with conventional commits
3. Push and create a Pull Request
4. CI runs tests, linting, and type checking
5. After approval, rebase and merge to `main`
6. Semantic Release automatically creates a new version

## Commit Convention

Use conventional commits for automatic versioning:

- `feat:` - New feature (minor version)
- `fix:` - Bug fix (patch version)
- `feat!:` or `BREAKING CHANGE:` - Breaking change (major version)
- `docs:`, `chore:`, `test:` - No version bump

## Code Quality

All code must pass:
- TypeScript type checking
- Biome linting and formatting
- Test coverage requirements
- Pre-commit hooks

## Pull Request Guidelines

- Use descriptive titles and descriptions
- Keep changes focused and atomic
- Ensure all CI checks pass
- Request review from maintainers
- Rebase before merging to maintain linear history