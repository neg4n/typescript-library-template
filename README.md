# TypeScript Library Template

An opinionated production-ready TypeScript library template with automated builds, testing, and releases.

<img width="380" src="https://github.com/user-attachments/assets/e3ecf54c-13c4-4baa-a253-d2861d4bf4e9" />

## Features

- 📦 **Dual Package Support** - Outputs CommonJS and ESM builds
- 🛡️ **Type Safety** - Extremely strict TypeScript configuration
- ✅ **Build Validation** - Uses `@arethetypeswrong/cli` to check package exports
- 🧪 **Automated Testing** - Vitest with coverage reporting
- 🎨 **Code Quality** - Biome linting and formatting with pre-commit hooks
- 🚀 **Automated Releases** - Semantic versioning with changelog generation
- ⚙️ **CI/CD Pipeline** - GitHub Actions for testing and publishing
- 🔧 **One-Click Setup** - Automated repository configuration with `init.sh` script
    - 🏛️ **Repository rulesets** - Branch protection with linear history and PR reviews
    - 🚷 **Feature cleanup** - Disable wikis, projects, squash/merge commits
    - 🔄 **Merge restrictions** - Rebase-only workflow at repository and ruleset levels
    - 👑 **Admin bypass** - Repository administrators can bypass protection rules
    - 🔍 **Actions verification** - Ensure GitHub Actions are enabled
    - 🗝️ **Secrets validation** - Check and guide setup of required secrets

## Tech Stack

- **TypeScript** - Strict configuration for type safety
- **Rollup** - Builds both CommonJS and ESM formats
- **Biome** - Fast linting and formatting
- **Vitest** - Testing with coverage reports
- **Husky** - Pre-commit hooks for code quality
- **Semantic Release** - Automated versioning and releases
- **pnpm** - Fast package management with Corepack
- **GitHub Actions** - CI/CD pipeline

## Setup

### 1. Use the template

Run this in your terminal _[GitHub CLI](https://cli.github.com) required_

```bash
gh repo create my-typescript-library --clone --template neg4n/typescript-library-template --private && cd my-typescript-library
```

> [!NOTE]
> Replace `my-typescript-library` with your new library name, you can also change the visiblity of the newly created repo by passing `--public` instead of `--private`! Read more about possible options in [GitHub CLI documentation](https://cli.github.com/manual/gh_repo_create)

#### Setup via GitHub web interface

If for some reason you can't run the mentioned commands in your terminal, click the "Use this template ▾" button below (or in the top right corner of the repository page)

<a href="https://github.com/new?template_name=typescript-library-template&template_owner=neg4n">
<img src="https://github.com/user-attachments/assets/784be0dd-530f-4135-b042-ab59dc9124a6" width="200" />
</a>


### 2. Minimal Setup

Run the initialization script to automatically configure your repository:

```bash
# One-command setup
./init.sh
```

This script will:
- 🔒 **Create repository rulesets** for branch protection (linear history, PR reviews)
- 🚫 **Disable unnecessary features** (wikis, projects, squash/merge commits)
- ⚙️ **Configure merge settings** (rebase-only workflow at repository and ruleset levels)
- 👤 **Grant admin bypass** permissions for repository administrators
- 🔧 **Verify GitHub Actions** and validate repository configuration
- 🔑 **Check required secrets** and provide setup instructions

### 3. Required Secrets

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

## FAQ

#### How do I modify the merging methods?

`typescript-library-template` sets **rebase-only** at both repository and main branch levels. Here's how to modify this:

##### **Current Setup**
- **Repository**: Rebase merging only (squash/merge disabled)
- **Main branch ruleset**: Requires rebase merging

##### **To Change Merge Methods**

**For repository-wide changes:**
- **Settings > General > Pull Requests** - toggle merge methods

**For branch-specific changes:**
- **Settings > Rules** - edit the main branch ruleset's "Require merge type"

##### **Precedence Rules**
1. Repository settings define what's **available**
2. Rulesets add **restrictions** on top  
3. **Most restrictive wins** - if repository disallows a method but ruleset requires it, merging is **blocked**

##### **Common Modifications**
- **Allow all methods**: Enable squash/merge in repo settings + remove "Require merge type" from ruleset
- **Squash-only**: Change repo settings to squash-only OR keep current repo settings + change ruleset to require squash
- **Different rules per branch**: Create additional rulesets for other branch patterns

> [!TIP]
> Since `typescript-library-template` is rebase-only, you must enable other methods in repository settings before rulesets can use them.

#### How to solve pnpm lockfile error on my CI/CD?

If you're seeing this error in your CI/CD (GitHub Actions) pipeline:

```
[...]

ERR_PNPM_OUTDATED_LOCKFILE  Cannot install with "frozen-lockfile" because pnpm-lock.yaml is not up to date with <ROOT>/package.json

[...]
```

##### **Why This Happens**
This template uses `--frozen-lockfile` flag to ensure consistent installations in CI/CD. The error occurs when your `package.json` has been modified but the `pnpm-lock.yaml` hasn't been updated to match.

##### **Solution**
Run the following command locally:
```bash
pnpm install
```

This will:
1. Update your `pnpm-lock.yaml` to match your `package.json`
2. Install any new dependencies
3. Resolve version conflicts

Then commit the updated lockfile:
```bash
git add pnpm-lock.yaml
git commit -m "chore: update pnpm lockfile"
```

> [!TIP]
> This is expected behavior and ensures your CI/CD uses the exact same dependency versions as your local environment.

#### Why Linear History?

Linear history provides several benefits for library releases:

- **Clean commit history** - Easy to track changes and debug issues
- **Simplified releases** - Semantic release works better with linear commits
- **Clear changelog** - Each commit represents a complete change
- **Better debugging** - `git bisect` works more effectively
- **Consistent workflow** - Forces proper PR review process

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow, commit conventions, and contribution guidelines.

## License

The MIT License
