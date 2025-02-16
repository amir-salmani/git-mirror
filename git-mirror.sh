#!/usr/bin/env bash

set -euo pipefail

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

TEMP_DIR="/tmp/git-mirror-$$"
MIRROR_BRANCH_PREFIX="mirror"
LOG_FILE="git_mirror_$(date +%Y%m%d_%H%M%S).log"
SUMMARY_FILE="git_mirror_summary_$(date +%Y%m%d_%H%M%S).txt"

# Logging functions
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" >&2
}

log_summary() {
    echo "$1" >> "$SUMMARY_FILE"
}

# UI Functions
print_header() {
    clear
    echo -e "${BLUE}${BOLD}Git Repository Mirror Tool${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    log_message "Starting new mirror operation"
}

print_step() {
    echo -e "\n${BOLD}[${1}/4] ${2}${NC}\n"
    log_message "Step ${1}: ${2}"
}

print_error() { 
    log_error "$1"
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

print_success() { 
    echo -e "${GREEN}✓ $1${NC}"
    log_message "Success: $1"
}

print_warning() { 
    echo -e "${YELLOW}! $1${NC}"
    log_message "Warning: $1"
}

cleanup() {
    log_message "Cleaning up temporary files"
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    [ -f "/tmp/git-credentials-$$" ] && rm -f "/tmp/git-credentials-$$"
}

trap cleanup EXIT

get_hostname() {
    local url=$1
    if [[ $url =~ ^https?:// ]]; then
        echo "$url" | sed -E 's|^https?://([^/]+).*|\1|'
    elif [[ $url =~ ^git@ ]]; then
        echo "$url" | sed -E 's|^git@([^:]+):.*|\1|'
    elif [[ $url =~ ^ssh:// ]]; then
        echo "$url" | sed -E 's|^ssh://[^@]+@([^:/]+)(:[0-9]+)?/.*|\1|'
    else
        print_error "Invalid Git URL format"
    fi
}

validate_git_url() {
    local url=$1
    [[ $url =~ ^(https?://|git@|ssh://).+ ]] || print_error "Invalid Git URL: $url"
}

get_auth_details() {
    local host=$1
    local auth_type

    while true; do
        echo -e "Select authentication method for ${BOLD}$host${NC}:"
        echo "1) Username/Password"
        echo "2) Access Token"
        read -r -p "> " auth_type

        case "$auth_type" in
            "1")
                read -r -p "Username: " username
                read -r -s -p "Password: " password
                echo
                log_message "Authentication set up for $host using username/password"
                echo "https://$username:$password@$host" > "/tmp/git-credentials-$$"
                break
                ;;
            "2")
                read -r -p "Username: " username
                read -r -s -p "Token: " token
                echo
                log_message "Authentication set up for $host using access token"
                echo "https://$username:$token@$host" > "/tmp/git-credentials-$$"
                break
                ;;
            *)
                print_warning "Please enter 1 or 2"
                ;;
        esac
    done

    export GIT_ASKPASS="/bin/true"
    export GIT_CREDENTIAL_HELPER="store --file=/tmp/git-credentials-$$"
}

check_repository() {
    log_message "Checking repository access: $1"
    git ls-remote "$1" &>/dev/null || print_error "Cannot access repository: $1"
}

main() {
    command -v git >/dev/null 2>&1 || print_error "Git is not installed"

    print_header

    # Step 1: Source Repository
    print_step "1" "Source Repository Configuration"
    read -r -p "Enter source repository URL: " source_repo
    validate_git_url "$source_repo"
    source_host=$(get_hostname "$source_repo")
    [[ $source_repo =~ ^https:// ]] && get_auth_details "$source_host"
    check_repository "$source_repo"
    print_success "Source repository validated"
    log_summary "Source Repository: $source_repo"

    # Step 2: Destination Repository
    print_step "2" "Destination Repository Configuration"
    read -r -p "Enter destination repository URL: " dest_repo
    validate_git_url "$dest_repo"
    dest_host=$(get_hostname "$dest_repo")
    [[ $dest_repo =~ ^https:// ]] && get_auth_details "$dest_host"
    check_repository "$dest_repo"
    print_success "Destination repository validated"
    log_summary "Destination Repository: $dest_repo"

    # Step 3: Cloning
    print_step "3" "Cloning Source Repository"
    mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"
    git clone --mirror "$source_repo" repo.git
    cd repo.git
    print_success "Repository cloned successfully"

    # Step 4: Mirroring
    print_step "4" "Mirroring to Destination"
    
    date_suffix=$(date +%Y%m%d_%H%M%S)
    default_branch=$(git symbolic-ref --short HEAD || echo "master")
    mirror_branch="${MIRROR_BRANCH_PREFIX}_${default_branch}_${date_suffix}"
    
    log_summary "\nMirror Operation Summary:"
    log_summary "========================="
    log_summary "Timestamp: $(date +'%Y-%m-%d %H:%M:%S')"
    log_summary "Default Branch: $default_branch"
    log_summary "Mirror Branch: $mirror_branch"
    
    if git push "$dest_repo" "$default_branch:$mirror_branch"; then
        print_success "Default branch mirrored to: $mirror_branch"
        log_summary "Default Branch Status: Successfully mirrored"
    else
        print_warning "Failed to push default branch"
        log_summary "Default Branch Status: Failed to mirror"
    fi

    if git push --all "$dest_repo"; then
        print_success "All branches mirrored"
        log_summary "All Branches Status: Successfully mirrored"
    else
        print_warning "Some branches were not pushed (possibly protected)"
        log_summary "All Branches Status: Partial success (some branches protected)"
    fi

    if git push --tags "$dest_repo"; then
        print_success "All tags mirrored"
        log_summary "Tags Status: Successfully mirrored"
    else
        print_warning "Some tags were not pushed"
        log_summary "Tags Status: Failed to mirror some tags"
    fi

    echo -e "\n${GREEN}${BOLD}Mirroring Complete!${NC}"
    echo -e "Protected branches were mirrored with prefix: ${BOLD}${mirror_branch}${NC}"
    echo -e "Please verify the mirrored repositories and update branch protection rules as needed."
    echo -e "\nLog file: $LOG_FILE"
    echo -e "Summary file: $SUMMARY_FILE"
    
    log_summary "\nOperation completed successfully"
}

main