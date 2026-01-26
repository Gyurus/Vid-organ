#!/bin/bash
# Video Organizer - Online Installer
# Minimal output installer with update/restore support

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly GITHUB_REPO="Gyurus/Vid-organ"
readonly GITHUB_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/Work/video"
readonly SCRIPT_NAME="set_v.sh"
readonly CONFIG_NAME="set_v.ini"

readonly INSTALL_DIR="${HOME}/.local/bin"
readonly CONFIG_DIR="${HOME}/.config/video-organizer"

# =============================================================================
# OUTPUT HELPERS (MINIMAL)
# =============================================================================

print_info() { echo "[i] $1"; }
print_warn() { echo "[!] $1"; }
print_err()  { echo "[x] $1" >&2; }

# =============================================================================
# HELPERS
# =============================================================================

download_file() {
    local url="$1"
    local output="$2"

    if curl -fsSL -o "$output" "$url"; then
        return 0
    else
        return 1
    fi
}

check_command() {
    local cmd="$1"
    command -v "$cmd" &> /dev/null
}

create_directory() {
    local dir="$1"
    mkdir -p "$dir" 2>/dev/null
}

# =============================================================================
# INSTALLATION STEPS
# =============================================================================

check_requirements() {
    if ! check_command "curl"; then
        print_err "curl is required but not installed"
        return 1
    fi

    if ! check_command "bash"; then
        print_err "bash is required but not installed"
        return 1
    fi
}

create_directories() {
    create_directory "$INSTALL_DIR" || { print_err "Failed to create $INSTALL_DIR"; return 1; }
    create_directory "$CONFIG_DIR" || true
}

install_script() {
    local url="${GITHUB_RAW_URL}/${SCRIPT_NAME}"
    local dest="${INSTALL_DIR}/${SCRIPT_NAME}"
    local temp="${dest}.tmp"

    if ! download_file "$url" "$temp"; then
        rm -f "$temp"
        print_err "Failed to download $SCRIPT_NAME"
        return 1
    fi

    if ! grep -q "SCRIPT_VERSION" "$temp"; then
        rm -f "$temp"
        print_err "Downloaded file is not a valid script"
        return 1
    fi

    chmod +x "$temp" && mv "$temp" "$dest" || {
        rm -f "$temp"
        print_err "Failed to install $SCRIPT_NAME"
        return 1
    }
}

install_config() {
    local url="${GITHUB_RAW_URL}/${CONFIG_NAME}"
    local dest="${CONFIG_DIR}/${CONFIG_NAME}"
    local temp="${dest}.tmp"

    if ! download_file "$url" "$temp"; then
        rm -f "$temp"
        return 0
    fi

    chmod 600 "$temp" && mv "$temp" "$dest" || {
        rm -f "$temp"
        print_err "Failed to install $CONFIG_NAME"
        return 1
    }
}

setup_path() {
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        return 0
    fi

    local bashrc="${HOME}/.bashrc"
    local path_export="export PATH=\"${INSTALL_DIR}:\$PATH\""

    if [[ -f "$bashrc" ]] && ! grep -q "$INSTALL_DIR" "$bashrc"; then
        {
            echo ""
            echo "# Added by Video Organizer installer"
            echo "$path_export"
        } >> "$bashrc"
        print_info "Added $INSTALL_DIR to PATH in ~/.bashrc"
        print_info "Run 'source ~/.bashrc' or restart your shell"
        return 0
    fi

    print_warn "Add $INSTALL_DIR to your PATH manually"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local restore_config=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--restore)
                restore_config=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--restore|-r]"
                echo "  --restore, -r  Force reinstall config file"
                return 0
                ;;
            *)
                print_err "Unknown option: $1"
                echo "Use --help for usage"
                return 1
                ;;
        esac
    done

    check_requirements || return 1
    create_directories || return 1

    install_script || return 1

    if [[ "$restore_config" == "true" ]] || [[ ! -f "${CONFIG_DIR}/${CONFIG_NAME}" ]]; then
        install_config || return 1
    fi

    setup_path

    print_info "Install complete. Run: set_v.sh --help"
}

main "$@"