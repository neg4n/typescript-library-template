#!/bin/bash

# TypeScript Library Template Initialization Script
# Configures repository settings, branch protection, and GitHub features

set -euo pipefail

# Colors and formatting
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m' # No Color
readonly BOLD='\033[1m'

# Unicode symbols
readonly CHECK="✓"
readonly CROSS="✗"
readonly DIAMOND="✦"
readonly SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# Global variables
OWNER=""
REPO_NAME=""
REPO_URL=""

# Simple logging
success() {
    echo -e " ${GREEN}${CHECK}${NC} $1"
}

warning() {
    echo -e " ${YELLOW}!${NC} $1"
}

error() {
    echo -e " ${YELLOW}${CROSS}${NC} $1"
    echo
    echo " For help: https://cli.github.com/manual"
    exit 1
}

# Minimal separator
separator() {
    echo -e " ${PURPLE}${DIAMOND}─────────────────────────${DIAMOND}${NC}"
}

# Spinner with minimal output
spinner() {
    local pid=$1
    local message=$2
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        local spinner_char="${SPINNER_CHARS:$i:1}"
        printf "\r ${PURPLE}${spinner_char}${NC} %s" "$message"
        i=$(( (i+1) % ${#SPINNER_CHARS} ))
        sleep 0.08
    done
    # Clear the entire line properly
    printf "\r%*s\r" $((${#message} + 10)) ""
}

# Check prerequisites
check_prerequisites() {
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI not found. Install from: https://cli.github.com/"
    fi
    
    # Check if user is authenticated
    if ! gh auth status &> /dev/null; then
        error "Not authenticated. Run: gh auth login"
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir &> /dev/null; then
        error "Not in a git repository"
    fi
    
    # Get repository info
    REPO_INFO=$(gh repo view --json owner,name,url 2>/dev/null || echo "")
    if [[ -z "$REPO_INFO" ]]; then
        error "Unable to determine repository information"
    fi
    
    OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
    REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name')
    REPO_URL=$(echo "$REPO_INFO" | jq -r '.url')
    
    echo " Repository: ${OWNER}/${REPO_NAME}"
}

# Configure repository settings with parallel execution
configure_repository() {
    # Create temp files for parallel execution
    local repo_settings_file=$(mktemp)
    local actions_file=$(mktemp)
    
    # Start parallel tasks
    {
        gh api -X PATCH repos/${OWNER}/${REPO_NAME} \
            -f has_wiki=false \
            -f has_projects=false \
            -f allow_squash_merge=false \
            -f allow_merge_commit=false \
            -f allow_rebase_merge=true \
            -f delete_branch_on_merge=true \
            > "$repo_settings_file" 2>&1
        echo $? > "${repo_settings_file}.exit"
    } &
    local repo_pid=$!
    
    {
        gh api repos/${OWNER}/${REPO_NAME}/actions/permissions --jq '.enabled' \
            > "$actions_file" 2>&1
        echo $? > "${actions_file}.exit"
    } &
    local actions_pid=$!
    
    # Show spinner for the longer operation
    spinner $repo_pid "Configuring repository settings..."
    wait $repo_pid
    
    # Check repository settings result
    local repo_exit_code=$(cat "${repo_settings_file}.exit" 2>/dev/null || echo "1")
    if [[ $repo_exit_code -eq 0 ]]; then
        success "Repository settings configured"
        echo " Wikis: disabled, Projects: disabled"
        echo " Merge methods: rebase only"
        echo " Auto-delete branches: enabled"
    else
        warning "Repository settings failed (admin permissions required)"
    fi
    
    # Wait for actions check and process result
    wait $actions_pid
    local actions_status=$(cat "$actions_file" 2>/dev/null || echo "unknown")
    
    case $actions_status in
        "true")
            success "GitHub Actions enabled"
            ;;
        "false")
            warning "GitHub Actions disabled"
            ;;
        *)
            warning "Unable to verify Actions status"
            ;;
    esac
    
    # Cleanup temp files
    rm -f "$repo_settings_file" "${repo_settings_file}.exit" "$actions_file" "${actions_file}.exit"
}

# Create repository ruleset
create_ruleset() {
    # Check if ruleset already exists
    local existing_rulesets=$(gh api repos/${OWNER}/${REPO_NAME}/rulesets --jq '.[].name' 2>/dev/null | grep -c "Main Branch Protection" || echo "0")
    
    if [[ "$existing_rulesets" -gt 0 ]]; then
        success "Branch protection ruleset already exists"
        echo " Target branch: main"
        echo " Pull requests: required (1 approval)"
        echo " Status checks: test pipeline required"
        echo " Linear history: enforced"
        echo " Force pushes: blocked"
        echo " Stale reviews: auto-dismissed"
        return
    fi
    
    # Create temporary JSON file
    local ruleset_file=$(mktemp)
    
    cat > "$ruleset_file" << 'EOF'
{
  "name": "Main Branch Protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "dismiss_stale_reviews_on_push": true,
        "required_approving_review_count": 1,
        "required_review_thread_resolution": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [
          {
            "context": "test"
          }
        ],
        "strict_required_status_checks_policy": true
      }
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "required_linear_history"
    }
  ],
  "bypass_actors": []
}
EOF
    
    # Apply ruleset
    {
        gh api -X POST repos/${OWNER}/${REPO_NAME}/rulesets \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            --input "$ruleset_file" \
            &> /dev/null
    } &
    local pid=$!
    spinner $pid "Creating branch protection ruleset..."
    wait $pid
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        success "Branch protection ruleset created"
        echo " Target branch: main"
        echo " Pull requests: required (1 approval)"
        echo " Status checks: test pipeline required"
        echo " Linear history: enforced"
        echo " Force pushes: blocked"
        echo " Stale reviews: auto-dismissed"
    else
        warning "Branch protection failed (may already exist)"
    fi
    
    rm -f "$ruleset_file"
}

# Check secrets
check_secrets() {
    local secrets_needed=("NPM_TOKEN" "ACTIONS_BRANCH_PROTECTION_BYPASS")
    local missing_secrets=()
    local secrets_output
    
    # Get secrets list once
    secrets_output=$(gh secret list 2>/dev/null || echo "")
    
    for secret in "${secrets_needed[@]}"; do
        if echo "$secrets_output" | grep -q "^$secret"; then
            success "Secret $secret configured"
        else
            missing_secrets+=("$secret")
            warning "Secret $secret missing"
        fi
    done
    
    if [[ ${#missing_secrets[@]} -gt 0 ]]; then
        echo
        echo " To add missing secrets:"
        for secret in "${missing_secrets[@]}"; do
            case $secret in
                "NPM_TOKEN")
                    echo "   npm token create --type=granular"
                    echo "   gh secret set $secret"
                    ;;
                "ACTIONS_BRANCH_PROTECTION_BYPASS")
                    echo "   Create PAT with 'repo' scope"
                    echo "   gh secret set $secret"
                    ;;
            esac
        done
    fi
}

# Main execution
main() {
    echo -e "${CYAN}${BOLD}TypeScript Library Template Setup${NC}"
    echo
    separator
    echo
    
    # Execute setup steps
    check_prerequisites
    echo
    configure_repository
    echo
    create_ruleset
    echo
    check_secrets
    
    # Final summary
    echo
    success "Installation successful!"
    echo " Repository configured for TypeScript library development"
    echo
    echo " You can now use:"
    echo "   pnpm dev              # Start development"
    echo "   pnpm test             # Run tests"
    echo "   pnpm build            # Build library"
    echo
    echo " Repository: ${REPO_URL}"
    echo
    separator
}

# Run main function
main "$@"