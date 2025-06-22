# TypeScript Library Template

An opinionated production-ready TypeScript library template with automated builds, testing, and releases.

## Tech Stack

- **TypeScript** - Strict configuration for type safety
- **Rollup** - Builds both CommonJS and ESM formats
- **Biome** - Fast linting and formatting
- **Vitest** - Testing with coverage reports
- **Husky** - Pre-commit hooks for code quality
- **Semantic Release** - Automated versioning and releases
- **pnpm** - Fast package management with Corepack
- **GitHub Actions** - CI/CD pipeline

## Features

- **Dual Package Support** - Outputs CommonJS and ESM builds
- **Type Safety** - Extremely strict TypeScript configuration
- **Build Validation** - Uses `@arethetypeswrong/cli` to check package exports
- **Automated Testing** - Vitest with coverage reporting
- **Code Quality** - Biome linting and formatting with pre-commit hooks
- **Automated Releases** - Semantic versioning with changelog generation
- **CI/CD Pipeline** - GitHub Actions for testing and publishing

## Setup

### 1. NPM Token

Create an NPM access token and add it to GitHub secrets:

```bash
# Create NPM token (granular access recommended)
npm token create --type=granular --scope=@your-scope

# Add to GitHub secrets using GitHub CLI
gh secret set NPM_TOKEN --body "your-npm-token-here"
```

### 2. Branch Protection Bypass Token

For automated releases to work with branch protection, create a Personal Access Token:

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Create a token with `repo` permissions
3. Add to GitHub secrets:

```bash
gh secret set ACTIONS_BRANCH_PROTECTION_BYPASS --body "your-pat-token-here"
```

### 3. Branch Protection Rules

Set up branch protection for the `main` branch:

```bash
# Enable branch protection with required checks
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":false}' \
  --field restrictions=null \
  --field required_linear_history=true \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```

#### Why Linear History?

Linear history provides several benefits for library releases:

- **Clean commit history** - Easy to track changes and debug issues
- **Simplified releases** - Semantic release works better with linear commits
- **Clear changelog** - Each commit represents a complete change
- **Better debugging** - `git bisect` works more effectively
- **Consistent workflow** - Forces proper PR review process

## Scripts

| Command | Description |
|---------|-------------|
| `pnpm dev` | Watch mode build |
| `pnpm build` | Production build |
| `pnpm build:check` | Build + package validation |
| `pnpm test` | Run tests |
| `pnpm test:watch` | Watch mode testing |
| `pnpm test:coverage` | Generate coverage report |
| `pnpm lint` | Check linting and formatting |
| `pnpm lint:fix` | Fix linting and formatting issues |
| `pnpm typecheck` | TypeScript type checking |
| `pnpm release` | Create release (CI only) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow, commit conventions, and contribution guidelines.