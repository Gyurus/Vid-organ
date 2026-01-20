#!/bin/bash

# Video Organizer - Online Installer
# Downloads and installs the Video Organizer script from GitHub
# This is a standalone installer script

# Configuration
GITHUB_REPO="Gyurus/Vid-organ"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Gyurus/Vid-organ/main/Work/video"
SCRIPT_NAME="set_v.sh"
CONFIG_NAME="set_v.ini"

# Install locations
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/video-organizer"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Function to check requirements
check_requirements() {
    print_info "Checking requirements..."
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        echo "Install curl and try again:"
        echo "  Ubuntu/Debian: sudo apt install curl"
        echo "  Fedora: sudo dnf install curl"
        echo "  macOS: brew install curl"
        return 1
    fi
    
    print_status "curl is installed"
    
    if ! command -v bash &> /dev/null; then
        print_error "bash is required but not installed"
        return 1
    fi
    
    print_status "bash is available"
    return 0
}

# Function to create directories
create_directories() {
    print_info "Creating installation directories..."
    
    # Create install directory
    if mkdir -p "$INSTALL_DIR" 2>/dev/null; then
        print_status "Install directory ready: $INSTALL_DIR"
    else
        print_error "Failed to create install directory: $INSTALL_DIR"
        return 1
    fi
    
    # Create config directory
    if mkdir -p "$CONFIG_DIR" 2>/dev/null; then
        print_status "Config directory ready: $CONFIG_DIR"
    else
        print_warning "Could not create config directory: $CONFIG_DIR"
    fi
    
    return 0
}

# Function to download file
download_file() {
    local url="$1"
    local output="$2"
    local filename=$(basename "$output")
    
    print_info "Downloading $filename..."
    
    if curl -sL -o "$output" "$url" 2>/dev/null; then
        print_status "$filename downloaded"
        return 0
    else
        print_error "Failed to download $filename"
        return 1
    fi
}

# Function to install script
install_script() {
    local script_url="${GITHUB_RAW_URL}/${SCRIPT_NAME}"
    local install_path="${INSTALL_DIR}/${SCRIPT_NAME}"
    local temp_file="${INSTALL_DIR}/.${SCRIPT_NAME}.tmp"
    
    print_info "Installing $SCRIPT_NAME..."
    
    # Download script
    if ! download_file "$script_url" "$temp_file"; then
        rm -f "$temp_file"
        return 1
    fi
    
    # Verify script is valid
    if ! grep -q "SCRIPT_VERSION" "$temp_file"; then
        print_error "Downloaded file is not a valid script"
        rm -f "$temp_file"
        return 1
    fi
    
    # Make executable and install
    if chmod +x "$temp_file" && mv "$temp_file" "$install_path"; then
        print_status "$SCRIPT_NAME installed to: $install_path"
        return 0
    else
        print_error "Failed to install $SCRIPT_NAME"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to install config
install_config() {
    local config_url="${GITHUB_RAW_URL}/${CONFIG_NAME}"
    local config_path="${CONFIG_DIR}/${CONFIG_NAME}"
    local temp_file="${CONFIG_DIR}/.${CONFIG_NAME}.tmp"
    
    print_info "Installing $CONFIG_NAME..."
    
    # Download config
    if ! download_file "$config_url" "$temp_file"; then
        rm -f "$temp_file"
        print_warning "Config file not installed (optional)"
        return 0
    fi
    
    # Install config
    if chmod 600 "$temp_file" && mv "$temp_file" "$config_path"; then
        print_status "$CONFIG_NAME installed to: $config_path"
        return 0
    else
        print_error "Failed to install $CONFIG_NAME"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to setup PATH
setup_path() {
    print_info "Checking PATH configuration..."
    
    if echo "$PATH" | grep -q "$INSTALL_DIR"; then
        print_status "$INSTALL_DIR is already in PATH"
        return 0
    fi
    
    # Try to automatically add to ~/.bashrc if it exists
    local bashrc="${HOME}/.bashrc"
    local path_line="export PATH=\"${INSTALL_DIR}:\$PATH\""
    
    if [ -f "$bashrc" ]; then
        if ! grep -q "$INSTALL_DIR" "$bashrc"; then
            print_info "Adding $INSTALL_DIR to PATH in ~/.bashrc..."
            echo "" >> "$bashrc"
            echo "# Added by Video Organizer installer" >> "$bashrc"
            echo "$path_line" >> "$bashrc"
            print_status "PATH updated in ~/.bashrc"
            print_info "Run 'source ~/.bashrc' or restart your shell to use set_v.sh"
            return 0
        else
            print_status "$INSTALL_DIR already configured in ~/.bashrc"
            return 0
        fi
    fi
    
    # Fallback: manual instructions
    print_warning "Add $INSTALL_DIR to your PATH to use 'set_v.sh' from anywhere"
    echo ""
    echo "Add one of the following to your shell configuration file:"
    echo ""
    echo "For ~/.bashrc (Bash):"
    echo "  echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> ~/.bashrc"
    echo ""
    echo "For ~/.zshrc (Zsh):"
    echo "  echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> ~/.zshrc"
    echo ""
    echo "For ~/.config/fish/config.fish (Fish):"
    echo "  echo 'set -gx PATH ${INSTALL_DIR} \$PATH' >> ~/.config/fish/config.fish"
    echo ""
    echo "Then reload your shell: source ~/.bashrc (or equivalent)"
    echo ""
    
    return 0
}

# Function to show post-install info
show_post_install() {
    echo ""
    echo "=========================================="
    print_status "Installation Complete!"
    echo "=========================================="
    echo ""
    
    local script_path="${INSTALL_DIR}/${SCRIPT_NAME}"
    
    echo "Script installed at:"
    echo "  $script_path"
    echo ""
    
    if [ -f "${CONFIG_DIR}/${CONFIG_NAME}" ]; then
        echo "Config installed at:"
        echo "  ${CONFIG_DIR}/${CONFIG_NAME}"
        echo ""
    fi
    
    echo "Next steps:"
    echo "  1. Check if $INSTALL_DIR is in your PATH"
    echo "  2. Run: set_v.sh --help"
    echo "  3. Start using: set_v.sh"
    echo ""
    
    echo "Useful commands:"
    echo "  set_v.sh --help       Show help"
    echo "  set_v.sh --version    Show version"
    echo "  set_v.sh              Start interactive mode"
    echo ""
}

# Main installation function
main() {
    echo ""
    echo "=========================================="
    echo "Video Organizer - Online Installer"
    echo "=========================================="
    echo ""
    
    # Check requirements
    if ! check_requirements; then
        return 1
    fi
    
    echo ""
    
    # Create directories
    if ! create_directories; then
        return 1
    fi
    
    echo ""
    
    # Install script
    if ! install_script; then
        return 1
    fi
    
    echo ""
    
    # Install config
    install_config
    
    echo ""
    
    # Setup PATH
    setup_path
    
    echo ""
    
    # Show post-install info
    show_post_install
    
    return 0
}

# Run main function
main
exit $?
