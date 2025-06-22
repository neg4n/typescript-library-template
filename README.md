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

- 📦 **Dual Package Support** - Outputs CommonJS and ESM builds
- 🛡️ **Type Safety** - Extremely strict TypeScript configuration
- ✅ **Build Validation** - Uses `@arethetypeswrong/cli` to check package exports
- 🧪 **Automated Testing** - Vitest with coverage reporting
- 🎨 **Code Quality** - Biome linting and formatting with pre-commit hooks
- 🚀 **Automated Releases** - Semantic versioning with changelog generation
- ⚙️ **CI/CD Pipeline** - GitHub Actions for testing and publishing
- 🔧 **One-Click Setup** - Automated repository configuration with `init.sh`

## Setup

### 1. Quick Start

Run the initialization script to automatically configure your repository:

```bash
# One-command setup
./init.sh
```

This script will:
- 🔒 **Create repository rulesets** for branch protection (linear history, PR reviews)
- 🚫 **Disable unnecessary features** (wikis, projects, squash/merge commits)
- ⚙️ **Configure merge settings** (rebase-only workflow)
- ✅ **Verify GitHub Actions** are enabled
- 🔑 **Check required secrets** and provide setup instructions

### 2. Required Secrets

The script will guide you to set up these secrets if missing:

**NPM_TOKEN** (for publishing):
```bash
# Generate NPM token with OTP for enhanced security
pnpm token create --otp=<YOUR_OTP> --registry=https://registry.npmjs.org/

# Set the token as repository secret
gh secret set NPM_TOKEN --body "your-npm-token-here"
```

**ACTIONS_BRANCH_PROTECTION_BYPASS** (for automated releases):
```bash
# Create Personal Access Token with 'repo' permissions
# Visit: https://github.com/settings/personal-access-tokens/new

# Set the PAT as repository secret
gh secret set ACTIONS_BRANCH_PROTECTION_BYPASS --body "your-pat-token-here"
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