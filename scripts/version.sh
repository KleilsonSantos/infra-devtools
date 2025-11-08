#!/bin/bash
################################################################################
#
# 🔖 Semantic Version Manager
#
# 👨‍💻 Author: Kleilson Santos
# 📅 Created: 2025-11-06
# 🔄 Last Updated: 2025-11-06
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📖 Purpose:
#    Manages semantic versioning (SemVer) for the project.
#    Updates VERSION, package.json, and sonar-project.properties.
#    Creates git tags automatically.
#
# ⚡ Features:
#    ✅ Automatic version bumping (major, minor, patch)
#    ✅ Synchronizes across multiple files
#    ✅ Creates git tags
#    ✅ Updates CHANGELOG.md
#
# 📋 Usage:
#    ./version.sh patch    # 1.2.9 → 1.2.10
#    ./version.sh minor    # 1.2.9 → 1.3.0
#    ./version.sh major    # 1.2.9 → 2.0.0
#    ./version.sh show     # Display current version
#    ./version.sh check    # Check alignment
#
################################################################################

# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$PROJECT_ROOT/VERSION"
PACKAGE_FILE="$PROJECT_ROOT/package.json"
SONAR_FILE="$PROJECT_ROOT/sonar-project.properties"
CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 Version Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE" | tr -d '[:space:]'
    else
        echo "0.0.0"
    fi
}

parse_version() {
    local version="$1"
    IFS='.' read -r -a parts <<< "$version"
    echo "${parts[0]}" "${parts[1]}" "${parts[2]}"
}

bump_version() {
    local bump_type="$1"
    local current_version
    current_version=$(get_current_version)

    read -r major minor patch <<< "$(parse_version "$current_version")"

    case "$bump_type" in
        patch)
            ((patch++))
            ;;
        minor)
            ((minor++))
            patch=0
            ;;
        major)
            ((major++))
            minor=0
            patch=0
            ;;
        *)
            log_error "Invalid bump type: $bump_type"
            return 1
            ;;
    esac

    echo "${major}.${minor}.${patch}"
}

update_version_file() {
    local new_version="$1"

    log_info "Updating VERSION file..."
    echo "$new_version" > "$VERSION_FILE"
    validate_file "$VERSION_FILE" "VERSION" || return 1
    log_debug "VERSION: $new_version"
}

update_package_json() {
    local new_version="$1"

    log_info "Updating package.json..."
    if ! command -v jq &> /dev/null; then
        log_warning "jq not found - skipping package.json update"
        return 0
    fi

    jq ".version = \"$new_version\"" "$PACKAGE_FILE" > "$PACKAGE_FILE.tmp" || return 1
    mv "$PACKAGE_FILE.tmp" "$PACKAGE_FILE"
    log_debug "package.json version: $new_version"
}

update_sonar_properties() {
    local new_version="$1"

    log_info "Updating sonar-project.properties..."
    if grep -q "sonar.projectVersion=" "$SONAR_FILE"; then
        sed -i "s/sonar.projectVersion=.*/sonar.projectVersion=$new_version/" "$SONAR_FILE"
    else
        echo "sonar.projectVersion=$new_version" >> "$SONAR_FILE"
    fi
    log_debug "sonar-project.properties version: $new_version"
}

update_changelog() {
    local new_version="$1"
    local current_date
    current_date=$(date +%Y-%m-%d)

    log_info "Updating CHANGELOG.md..."

    # Create entry for new version
    local changelog_entry="## [$new_version] - $current_date\n\n### Added\n- (No changes documented yet)\n\n"

    # Add new entry after [Unreleased] section
    if grep -q "## \[Unreleased\]" "$CHANGELOG_FILE"; then
        sed -i "/## \[Unreleased\]/a\\\n$changelog_entry" "$CHANGELOG_FILE"
    else
        log_warning "Unreleased section not found in CHANGELOG.md"
    fi

    log_debug "CHANGELOG.md entry added"
}

create_git_tag() {
    local new_version="$1"

    log_info "Creating git tag: v$new_version"

    if ! git tag -a "v$new_version" -m "Release version $new_version" 2>/dev/null; then
        log_warning "Failed to create git tag (may already exist or not in git repo)"
        return 0
    fi

    log_success "Git tag created: v$new_version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Command Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_show() {
    local current_version
    current_version=$(get_current_version)

    log_header "Current Version"
    log_info "VERSION file:     $(cat "$VERSION_FILE")"

    if [[ -f "$PACKAGE_FILE" ]]; then
        local pkg_version
        pkg_version=$(jq -r '.version' "$PACKAGE_FILE" 2>/dev/null || echo "N/A")
        log_info "package.json:     $pkg_version"
    fi

    if [[ -f "$SONAR_FILE" ]]; then
        local sonar_version
        sonar_version=$(grep -E '^sonar.projectVersion=' "$SONAR_FILE" | cut -d'=' -f2 || echo "N/A")
        log_info "sonar-project:    $sonar_version"
    fi
}

cmd_check() {
    log_header "Version Alignment Check"

    local version_file_version
    local pkg_version
    local sonar_version

    version_file_version=$(cat "$VERSION_FILE" | tr -d '[:space:]')
    pkg_version=$(jq -r '.version' "$PACKAGE_FILE" 2>/dev/null)
    sonar_version=$(grep -E '^sonar.projectVersion=' "$SONAR_FILE" | cut -d'=' -f2 | tr -d '[:space:]')

    log_info "VERSION:             $version_file_version"
    log_info "package.json:        $pkg_version"
    log_info "sonar-project:       $sonar_version"

    if [[ "$version_file_version" == "$pkg_version" ]] && [[ "$version_file_version" == "$sonar_version" ]]; then
        log_success "✅ All versions aligned"
        return 0
    else
        log_error "❌ Version mismatch detected"
        return 1
    fi
}

cmd_bump() {
    local bump_type="$1"
    local current_version
    local new_version

    current_version=$(get_current_version)
    new_version=$(bump_version "$bump_type")

    log_header "🔖 Version Bump: $bump_type"
    log_info "Current:  $current_version"
    log_info "New:      $new_version"
    echo ""

    # Update all files
    update_version_file "$new_version" || die $EXIT_FAILURE "Failed to update VERSION"
    update_package_json "$new_version" || log_warning "Failed to update package.json"
    update_sonar_properties "$new_version" || log_warning "Failed to update sonar-project.properties"
    update_changelog "$new_version" || log_warning "Failed to update CHANGELOG.md"

    echo ""
    log_header "Next Steps"
    log_info "1. Review changes: git diff"
    log_info "2. Commit: git add . && git commit -m 'chore(release): bump to $new_version'"
    log_info "3. Tag: git push && git push --tags"

    log_success "✅ Version bumped to $new_version"
}

cmd_help() {
    cat << 'EOF'
🔖 Semantic Version Manager

USAGE:
    ./version.sh <command>

COMMANDS:
    patch       Bump patch version (1.2.9 → 1.2.10)
    minor       Bump minor version (1.2.9 → 1.3.0)
    major       Bump major version (1.2.9 → 2.0.0)
    show        Display current version
    check       Check version alignment
    help        Show this help message

EXAMPLES:
    # Show current version
    ./version.sh show

    # Bump patch version
    ./version.sh patch

    # Check version alignment
    ./version.sh check

MANAGED FILES:
    - VERSION (primary source)
    - package.json
    - sonar-project.properties
    - CHANGELOG.md (entry added)
    - Git tags (created automatically)

SEMVER FORMAT:
    MAJOR.MINOR.PATCH
    │      │      └─ Bug fixes (1.2.X)
    │      └─────── New features (1.X.0)
    └──────────── Breaking changes (X.0.0)
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 Main Execution
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    local command="${1:-help}"

    # Validate files exist
    validate_file "$VERSION_FILE" "VERSION" || \
        die $EXIT_NOT_FOUND "VERSION file not found - run from project root"
    validate_file "$PACKAGE_FILE" "package.json" || \
        die $EXIT_NOT_FOUND "package.json not found"

    case "$command" in
        patch|minor|major)
            cmd_bump "$command"
            ;;
        show)
            cmd_show
            ;;
        check)
            cmd_check
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            return $EXIT_INVALID_ARGS
            ;;
    esac
}

main "$@"
