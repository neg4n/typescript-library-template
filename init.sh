#!/bin/bash

# TypeScript Library Template Initialization Script
# Configures repository settings, branch protection, and GitHub features

set -uo pipefail

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

# Graceful error handling for non-critical operations
handle_error() {
    local operation="$1"
    local error_msg="$2"
    echo -e " ${YELLOW}!${NC} ${operation} failed: ${error_msg}"
    echo -e " ${GRAY}→ Continuing with remaining setup steps...${NC}"
    echo
}

# Log detailed errors with beautiful formatting
log_error() {
    local operation="$1"
    local error_file="$2"
    if [[ -f "$error_file" && -s "$error_file" ]]; then
        echo -e " ${YELLOW}!${NC} ${operation} failed with details:"
        
        # Get terminal width and calculate box width
        local term_width=$(tput cols 2>/dev/null || echo 80)
        local box_width=$((term_width - 4))  # Account for padding
        
        # Create top border
        local border=$(printf '─%.0s' $(seq 1 $box_width))
        echo -e " ${GRAY}┌${border}┐${NC}"
        # Process each line with text balancing
        while IFS= read -r line; do
            # Break long lines into balanced chunks
            if [[ ${#line} -le $((box_width - 2)) ]]; then
                # Single line fits
                printf " ${GRAY}│${NC} %-*s ${GRAY}│${NC}\n" $((box_width - 2)) "$line"
            else
                # Multi-line text balancing
                local words=($line)
                local current_line=""
                local lines=()
                
                for word in "${words[@]}"; do
                    if [[ ${#current_line} -eq 0 ]]; then
                        current_line="$word"
                    elif [[ $((${#current_line} + ${#word} + 1)) -le $((box_width - 2)) ]]; then
                        current_line="$current_line $word"
                    else
                        lines+=("$current_line")
                        current_line="$word"
                    fi
                done
                [[ -n "$current_line" ]] && lines+=("$current_line")
                
                # Balance the lines by redistributing words if needed
                if [[ ${#lines[@]} -gt 1 ]]; then
                    local total_chars=0
                    for balanced_line in "${lines[@]}"; do
                        total_chars=$((total_chars + ${#balanced_line}))
                    done
                    local avg_chars=$((total_chars / ${#lines[@]}))
                    
                    # Simple balancing: if last line is much shorter, redistribute
                    local last_idx=$((${#lines[@]} - 1))
                    local last_line="${lines[$last_idx]}"
                    if [[ ${#last_line} -lt $((avg_chars / 2)) && ${#lines[@]} -gt 1 ]]; then
                        local prev_idx=$((${#lines[@]} - 2))
                        local prev_line="${lines[$prev_idx]}"
                        local prev_words=($prev_line)
                        local last_words=($last_line)
                        
                        if [[ ${#prev_words[@]} -gt 2 ]]; then
                            local prev_word_idx=$((${#prev_words[@]} - 1))
                            local move_word="${prev_words[$prev_word_idx]}"
                            unset prev_words[$prev_word_idx]
                            lines[$prev_idx]="${prev_words[*]}"
                            lines[$last_idx]="$move_word ${last_words[*]}"
                        fi
                    fi
                fi
                
                # Print balanced lines
                for balanced_line in "${lines[@]}"; do
                    printf " ${GRAY}│${NC} %-*s ${GRAY}│${NC}\n" $((box_width - 2)) "$balanced_line"
                done
            fi
        done < "$error_file"
        
        # Create bottom border
        echo -e " ${GRAY}└${border}┘${NC}"
        echo -e " ${GRAY}→ Continuing with remaining setup steps...${NC}"
        echo
    else
        handle_error "$operation" "Unknown error occurred"
    fi
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
        echo " Merge methods: rebase only (repository level)"
        echo " Auto-delete branches: enabled"
    else
        log_error "Repository settings" "$repo_settings_file"
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
            handle_error "GitHub Actions verification" "Unable to determine status"
            ;;
    esac
    
    # Cleanup temp files
    rm -f "$repo_settings_file" "${repo_settings_file}.exit" "$actions_file" "${actions_file}.exit"
}

# Create repository ruleset
create_ruleset() {
    # Check if ruleset already exists
    if gh api repos/${OWNER}/${REPO_NAME}/rulesets --jq '.[].name' 2>/dev/null | grep -q "Main Branch Protection" 2>/dev/null; then
        success "Branch protection ruleset already exists"
        echo " Target branch: main"
        echo " Pull requests: required (1 approval)"
        echo " Merge methods: rebase only (ruleset level)"
        echo " Linear history: enforced"
        echo " Force pushes: blocked"
        echo " Stale reviews: auto-dismissed"
        echo " Bypass: repository admins allowed"
        return
    fi
    
    # Create temporary JSON file
    local ruleset_file=$(mktemp)
    
    # Get current user ID for bypass configuration
    local current_user_id=$(gh api user --jq '.id' 2>/dev/null || echo "")
    local current_user=$(gh api user --jq '.login' 2>/dev/null || echo "")
    
    cat > "$ruleset_file" << EOF
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
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["rebase"]
      }
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "required_linear_history"
    }
  ],
  "bypass_actors": [
    {
      "actor_type": "RepositoryRole",
      "bypass_mode": "always",
      "actor_id": 5
    }
  ]
}
EOF
    
    # Apply ruleset
    local ruleset_error_file=$(mktemp)
    {
        gh api -X POST repos/${OWNER}/${REPO_NAME}/rulesets \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            --input "$ruleset_file" \
            > /dev/null 2>"$ruleset_error_file"
        echo $? > "${ruleset_error_file}.exit"
    } &
    local pid=$!
    spinner $pid "Creating branch protection ruleset..."
    wait $pid
    local exit_code=$(cat "${ruleset_error_file}.exit" 2>/dev/null || echo "1")
    
    if [[ $exit_code -eq 0 ]]; then
        success "Branch protection ruleset created"
        echo " Target branch: main"
        echo " Pull requests: required (1 approval)"
        echo " Merge methods: rebase only (ruleset level)"
        echo " Linear history: enforced"
        echo " Force pushes: blocked"
        echo " Stale reviews: auto-dismissed"
        echo " Bypass: repository admins allowed"
    else
        log_error "Branch protection ruleset" "$ruleset_error_file"
    fi
    
    rm -f "$ruleset_file" "$ruleset_error_file" "${ruleset_error_file}.exit"
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
        echo -e " ${BLUE}Setup Instructions:${NC}"
        for secret in "${missing_secrets[@]}"; do
            case $secret in
                "NPM_TOKEN")
                    echo -e "   ${GRAY}# Generate NPM token with OTP${NC}"
                    echo -e "   ${WHITE}pnpm token create --otp=<YOUR_OTP> --registry=https://registry.npmjs.org/${NC}"
                    echo -e "   ${WHITE}gh secret set $secret${NC}"
                    echo
                    ;;
                "ACTIONS_BRANCH_PROTECTION_BYPASS")
                    echo -e "   ${GRAY}# Create Personal Access Token${NC}"
                    echo -e "   ${GRAY}# see README.md for more details${NC}"
                    echo -e "   ${WHITE}gh secret set $secret${NC}"
                    echo
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
