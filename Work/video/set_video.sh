#!/bin/bash

# Video Audio Language Setter and Organizer
# Version: 0.6.3
# Script to check video files for missing audio language metadata
# and set it interactively

# Removed items folder
REMOVED_FOLDER="Aa.removed"

# Configuration file for storing default movie folder
CONFIG_FILE="$HOME/.video_language_setter.conf"

# INI configuration file - store in same directory as script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INI_CONFIG_FILE="$SCRIPT_DIR/set_audio.ini"

# Default settings in INI format
declare -A INI_SETTINGS=(
    [enable_sample_removal]="true"
    [enable_rename]="true"
    [default_audio_language]="hun"
    [default_player]="smplayer"
    [auto_organize]="true"
    [default_folder]=""
    [small_folder_size_mb]="5"
    [large_file_size_gb]="1"
    [removable_files]="www.yts.mx|sample.*|*.sfv"
    [subtitle_extensions]="srt|sub|ass|ssa|vtt|smi"
    [removed_folder_name]="Aa.removed"
)

# Function to load INI configuration
load_ini_config() {
    if [ -f "$INI_CONFIG_FILE" ]; then
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Trim whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Update settings array
            INI_SETTINGS["$key"]="$value"
        done < "$INI_CONFIG_FILE"
        echo "✓ Loaded settings from $INI_CONFIG_FILE" >&2
        return 0
    fi
    return 1
}

# Function to save INI configuration
save_ini_config() {
    local temp_file="${INI_CONFIG_FILE}.tmp"
    
    # Write to temp file first
    {
        echo "# Video Audio Language Setter - Configuration"
        echo "# Generated: $(date)"
        echo ""
        for key in "${!INI_SETTINGS[@]}"; do
            echo "$key=${INI_SETTINGS[$key]}"
        done
    } > "$temp_file" 2>/dev/null
    
    # If temp file created successfully, move it to final location
    if [ -f "$temp_file" ]; then
        mv "$temp_file" "$INI_CONFIG_FILE" 2>/dev/null
        if [ -f "$INI_CONFIG_FILE" ]; then
            echo "✓ Settings saved to $INI_CONFIG_FILE" >&2
            return 0
        fi
    fi
    
    echo "✗ Failed to save settings to $INI_CONFIG_FILE" >&2
    return 1
}

# Function to get INI setting
get_ini_setting() {
    local key="$1"
    echo "${INI_SETTINGS[$key]}"
}

# Function to set INI setting
set_ini_setting() {
    local key="$1"
    local value="$2"
    INI_SETTINGS["$key"]="$value"
    # Immediately save to disk to persist changes
    save_ini_config
}

# Function to display current settings
# Function to display INI file contents
display_ini_file() {
    if [ -f "$INI_CONFIG_FILE" ]; then
        echo -e "${BLUE}════════ INI File: $INI_CONFIG_FILE ════════${NC}"
        cat "$INI_CONFIG_FILE" | sed 's/^/  /'
        echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    else
        echo -e "${YELLOW}⚠ INI file not found at: $INI_CONFIG_FILE${NC}"
    fi
}

# Command-line options (default: enabled)
ENABLE_RENAME=true
ENABLE_SAMPLE_REMOVAL=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables for batch processing
BATCH_MODE=""  # Can be: "yes_all", "no_all", or ""

# Function to print section headers with visual style
print_section() {
    local title="$1"
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}$title${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Function to print completion status
print_status() {
    local message="$1"
    local status="$2"  # "done", "info", "warn", "error"
    
    case "$status" in
        done)
            echo -e "${GREEN}✓${NC} $message"
            ;;
        info)
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
        warn)
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        error)
            echo -e "${RED}✗${NC} $message"
            ;;
        *)
            echo -e "• $message"
            ;;
    esac
}

# Function to handle user input with batch options
get_user_choice() {
    local prompt="$1"
    local default="$2"  # "y" or "n"
    local show_all="${3:-true}"  # Show "all" options by default
    
    # If we're in batch mode, return the batch choice
    if [ "$BATCH_MODE" = "yes_all" ]; then
        echo "y"
        return 0
    elif [ "$BATCH_MODE" = "no_all" ]; then
        echo "n"
        return 0
    fi
    
    local choice
    while true; do
        # Show prompt with selectable options
        if [ "$show_all" = "true" ]; then
            if [ "$default" = "y" ]; then
                echo -n "$prompt [Y/n/a(yes to all)/x(no to all)/e(exit)]: " >&2
            else
                echo -n "$prompt [y/N/a(yes to all)/x(no to all)/e(exit)]: " >&2
            fi
        else
            if [ "$default" = "y" ]; then
                echo -n "$prompt [Y/n/e(exit)]: " >&2
            else
                echo -n "$prompt [y/N/e(exit)]: " >&2
            fi
        fi
        
        # Try to read from TTY if available, otherwise use stdin with timeout
        if [ -t 0 ]; then
            read -r choice </dev/tty
        else
            if read -r -t 1 choice; then
                :
            else
                # No input, use default
                choice=""
            fi
        fi
        
        case "$choice" in
            [Aa]|[Aa][Ll][Ll])
                if [ "$show_all" = "true" ]; then
                    BATCH_MODE="yes_all"
                    echo -e "${GREEN}✓ Selected 'Yes to All' - will apply to all remaining prompts${NC}" >&2
                    echo "y"
                    return 0
                else
                    echo -e "${YELLOW}⚠ Invalid option 'a'. Please choose: y/n/e${NC}" >&2
                    continue
                fi
                ;;
            [Xx]|[Xx][Aa][Ll][Ll])
                if [ "$show_all" = "true" ]; then
                    BATCH_MODE="no_all"
                    echo -e "${YELLOW}✓ Selected 'No to All' - will skip all remaining prompts${NC}" >&2
                    echo "n"
                    return 0
                else
                    echo -e "${YELLOW}⚠ Invalid option 'x'. Please choose: y/n/e${NC}" >&2
                    continue
                fi
                ;;
            [Ee]|[Ee][Xx][Ii][Tt])
                echo -e "${BLUE}User requested exit${NC}" >&2
                exit 0
                ;;
            [Yy]|[Yy][Ee][Ss])
                echo "y"
                return 0
                ;;
            [Nn]|[Nn][Oo])
                echo "n"
                return 0
                ;;
            "")
                echo "$default"
                return 0
                ;;
            *)
                if [ "$show_all" = "true" ]; then
                    echo -e "${YELLOW}⚠ Invalid choice '$choice'. Please choose: y/n/a/x/e${NC}" >&2
                else
                    echo -e "${YELLOW}⚠ Invalid choice '$choice'. Please choose: y/n/e${NC}" >&2
                fi
                continue
                ;;
        esac
    done
}

install_dependencies() {
    echo "checking dependencies..."
    local missing_tools=("$@")
    local install_cmd=""
    
    echo -e "${YELLOW}Missing dependencies detected: ${missing_tools[*]}${NC}"
    echo
    
    # Detect package manager
    if command -v apt-get &> /dev/null; then
        install_cmd="sudo apt-get update && sudo apt-get install -y"
    elif command -v yum &> /dev/null; then
        install_cmd="sudo yum install -y"
    elif command -v dnf &> /dev/null; then
        install_cmd="sudo dnf install -y"
    elif command -v pacman &> /dev/null; then
        install_cmd="sudo pacman -S --noconfirm"
    elif command -v brew &> /dev/null; then
        install_cmd="brew install"
    else
        echo -e "${RED}Error: Could not detect package manager${NC}"
        echo "Please install manually: ${missing_tools[*]}"
        return 1
    fi
    
    echo "Do you want to install missing dependencies?"
    install_choice=$(get_user_choice)
    
    if [ "$install_choice" = "y" ]; then
        echo -e "${BLUE}Installing dependencies...${NC}"
        for tool in "${missing_tools[@]}"; do
            # Map tool names to package names
            local package="$tool"
            if [ "$tool" = "video player (smplayer, mpv, vlc, or mplayer)" ]; then
                package="smplayer"  # Install smplayer as default
            elif [ "$tool" = "mkvpropedit (from mkvtoolnix)" ]; then
                package="mkvtoolnix"
            fi
            
            echo -e "${BLUE}Installing $package...${NC}"
            if eval "$install_cmd $package"; then
                echo -e "${GREEN}✓ Successfully installed $package${NC}"
            else
                echo -e "${RED}✗ Failed to install $package${NC}"
                echo "Please install manually."
            fi
        done
        echo
        echo -e "${GREEN}Dependency installation complete!${NC}"
        echo "Please re-run the script."
        exit 0
    else
        echo "Please install dependencies manually and try again."
        exit 1
    fi
}

# Function to ensure removed folder exists
# Function to move file or directory to removed folder
move_to_removed() {
    local item="$1"
    local movie_folder="$2"  # The movie folder (Title_(Year)) where Aa.removed should be created
    local removed_path
    local item_name
    local target_path
    local counter=1
    
    # Validate inputs
    if [ -z "$item" ] || [ -z "$movie_folder" ]; then
        echo -e "${RED}✗ Error: move_to_removed - Invalid arguments${NC}"
        return 1
    fi
    
    # Check if item exists
    if [ ! -e "$item" ]; then
        echo -e "${RED}✗ Error: Item does not exist: $item${NC}"
        return 1
    fi
    
    # Check if we have permission to move the item
    local item_dir=$(dirname "$item")
    if [ ! -w "$item_dir" ]; then
        echo -e "${RED}✗ No write permission to: $item_dir${NC}"
        echo -e "${YELLOW}You may need to run the script with elevated privileges (sudo)${NC}"
        return 1
    fi
    
    # Create Aa.removed in the movie folder
    removed_path="${movie_folder}/${REMOVED_FOLDER}"
    
    # Ensure movie folder exists and is writable
    if [ ! -d "$movie_folder" ]; then
        echo -e "${RED}✗ Movie folder does not exist: $movie_folder${NC}"
        return 1
    fi
    
    if [ ! -w "$movie_folder" ]; then
        echo -e "${RED}✗ No write permission to movie folder: $movie_folder${NC}"
        echo -e "${YELLOW}You may need to run the script with elevated privileges (sudo)${NC}"
        return 1
    fi
    
    # Create Aa.removed folder if it doesn't exist
    if [ ! -d "$removed_path" ]; then
        if mkdir -p "$removed_path" 2>/dev/null; then
            echo -e "${BLUE}Created removed items folder: ${removed_path}${NC}"
        else
            echo -e "${RED}✗ Failed to create removed folder: ${removed_path}${NC}"
            echo -e "${YELLOW}You may need to run the script with elevated privileges (sudo)${NC}"
            return 1
        fi
    fi
    
    # Check if we can write to removed folder
    if [ ! -w "$removed_path" ]; then
        echo -e "${RED}✗ No write permission to removed folder: $removed_path${NC}"
        return 1
    fi
    
    item_name=$(basename "$item")
    target_path="${removed_path}/${item_name}"
    
    # If item with same name exists, add number suffix
    while [ -e "$target_path" ]; do
        target_path="${removed_path}/${item_name}.${counter}"
        ((counter++))
    done
    
    # Check available disk space
    local available_space=$(df "$removed_path" 2>/dev/null | awk 'NR==2 {print $4}')
    if [ -n "$available_space" ] && [ "$available_space" -lt 1024 ]; then
        echo -e "${RED}✗ Insufficient disk space in removed folder (< 1MB available)${NC}"
        return 1
    fi
    
    # Move the item with error checking
    if mv "$item" "$target_path" 2>/dev/null; then
        if [ -e "$target_path" ]; then
            echo -e "${GREEN}✓ Moved to removed folder: $(basename "$target_path")${NC}"
            return 0
        else
            echo -e "${RED}✗ File move completed but target not found - verification failed${NC}"
            return 1
        fi
    else
        local mv_error=$?
        case $mv_error in
            1)
                echo -e "${RED}✗ Failed to move item (permission denied or source/dest issue)${NC}"
                ;;
            2)
                echo -e "${RED}✗ Failed to move item (invalid path or file system error)${NC}"
                ;;
            *)
                echo -e "${RED}✗ Failed to move item (error code: $mv_error)${NC}"
                ;;
        esac
        echo -e "${YELLOW}You may need to run the script with elevated privileges (sudo)${NC}"
        return 1
    fi
}

# Function to remove small folders (< 5MB) to Aa.removed
remove_small_folders() {
    local search_dir="$1"
    local size_limit_mb=$(get_ini_setting "small_folder_size_mb")
    local size_limit=$((size_limit_mb * 1048576))  # Convert MB to bytes
    local removed_count=0
    
    echo -e "${BLUE}Scanning for small folders (< ${size_limit_mb}MB)...${NC}"
    
    # Find all directories directly in search_dir (not nested)
    while IFS= read -r -d '' folder; do
        # Skip if it's the Aa.removed folder itself
        if [ "$(basename "$folder")" = "$REMOVED_FOLDER" ]; then
            continue
        fi
        
        # Calculate folder size
        local folder_size=$(du -sb "$folder" 2>/dev/null | awk '{print $1}')
        
        if [ -z "$folder_size" ]; then
            continue
        fi
        
        # Check if folder is smaller than 5MB
        if [ "$folder_size" -lt "$size_limit" ]; then
            local folder_name=$(basename "$folder")
            local size_mb=$((folder_size / 1048576))
            
            echo -e "${YELLOW}Small folder detected: $folder_name (${size_mb}MB)${NC}"
            
            # Move to Aa.removed in search_dir
            if move_to_removed "$folder" "$search_dir"; then
                ((removed_count++))
            else
                echo -e "${YELLOW}⚠ Could not remove small folder: $folder_name${NC}"
            fi
        fi
    done < <(find "$search_dir" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
    
    if [ "$removed_count" -gt 0 ]; then
        echo -e "${GREEN}✓ Removed $removed_count small folder(s)${NC}"
    fi
}

# Function to ensure single-level directory structure
ensure_single_level_structure() {
    local search_dir="$1"
    
    echo -e "${BLUE}Checking directory structure...${NC}"
    
    # Find video files that are more than 1 level deep from search_dir
    local moved_count=0
    while IFS= read -r -d '' file; do
        # Get relative path from search_dir
        local rel_path="${file#$search_dir/}"
        
        # Count directory levels (count forward slashes)
        local level_count=$(echo "$rel_path" | tr -cd '/' | wc -c)
        
        # If more than 1 level deep, move to search_dir
        if [ "$level_count" -gt 1 ]; then
            local filename=$(basename "$file")
            local target_path="${search_dir}/${filename}"
            
            # Handle duplicate names
            local counter=1
            while [ -e "$target_path" ]; do
                local name_without_ext="${filename%.*}"
                local extension="${filename##*.}"
                target_path="${search_dir}/${name_without_ext}_${counter}.${extension}"
                ((counter++))
            done
            
            echo -e "${YELLOW}Moving deeply nested file: $(basename "$file")${NC}"
            echo -e "  From: $file"
            echo -e "  To:   $target_path"
            
            # Verify source is readable
            if [ ! -r "$file" ]; then
                echo -e "${RED}✗ Cannot read source file (permission denied)${NC}"
                continue
            fi
            
            # Verify destination directory is writable
            if [ ! -w "$search_dir" ]; then
                echo -e "${RED}✗ Cannot write to destination directory (permission denied)${NC}"
                continue
            fi
            
            if mv "$file" "$target_path" 2>/dev/null; then
                # Verify the move was successful
                if [ -f "$target_path" ] && [ ! -f "$file" ]; then
                    echo -e "${GREEN}✓ Moved successfully${NC}"
                    ((moved_count++))
                    
                    # Remove empty parent directories
                    local parent_dir=$(dirname "$file")
                    if [ -d "$parent_dir" ] && [ "$parent_dir" != "$search_dir" ]; then
                        # Check if directory is empty
                        if [ -z "$(ls -A "$parent_dir" 2>/dev/null)" ]; then
                            echo -e "${BLUE}Removing empty directory: $(basename "$parent_dir")${NC}"
                            move_to_removed "$parent_dir" "$search_dir" || echo -e "${YELLOW}Could not remove empty directory${NC}"
                        fi
                    fi
                else
                    echo -e "${RED}✗ File move verification failed${NC}"
                fi
            else
                echo -e "${RED}✗ Failed to move file (permission or filesystem error)${NC}"
            fi
            echo
        fi
    done < <(find "$search_dir" -mindepth 2 -type f -iregex ".*\.\(avi\|mkv\|mp4\|mov\|wmv\|flv\|webm\|m4v\|mpg\|mpeg\|3gp\|ogv\)$" -print0 2>/dev/null)
    
    if [ "$moved_count" -gt 0 ]; then
        echo -e "${GREEN}✓ Moved $moved_count deeply nested video file(s) to main directory${NC}"
    else
        echo -e "${GREEN}✓ Directory structure is already single-level${NC}"
    fi
    echo
}


# Function to check if running with elevated privileges
check_elevated_privileges() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "${YELLOW}⚠ NOTICE: Running with elevated privileges (root/sudo)${NC}"
        echo -e "${BLUE}This is necessary if video files are owned by other users or in protected directories.${NC}"
        echo -e "${YELLOW}Be careful when removing files - they will be moved to the Aa.removed folder.${NC}"
        echo
        local choice=$(get_user_choice "Continue running as root?" "n" "false")
        if [[ "$choice" != "y" ]]; then
            echo "Exiting. Consider running without sudo if you own the files."
            exit 1
        fi
        echo
    fi
}

# Function to check file permissions and ownership
check_file_permissions() {
    local search_dir="$1"
    local current_user=$(whoami)
    local issues_found=false
    
    # First count files
    local file_count=0
    while IFS= read -r -d '' file; do
        ((file_count++))
    done < <(find "$search_dir" -type f -iregex ".*\.\(avi\|mkv\|mp4\|mov\|wmv\|flv\|webm\|m4v\|mpg\|mpeg\|3gp\|ogv\)$" -print0 2>/dev/null)
    
    echo -e "${BLUE}Checking permissions ($file_count files)...${NC}"
    
    # Check if search directory is writable
    if [ ! -w "$search_dir" ]; then
        echo -e "${RED}⚠ WARNING: No write permission to directory: $search_dir${NC}"
        echo -e "${YELLOW}You may need to run the script with elevated privileges (sudo) or change to a directory you own.${NC}"
        issues_found=true
    fi
    
    # Check for files owned by root or other users
    local non_owned_files=()
    local files_checked=0
    while IFS= read -r -d '' file; do
        ((files_checked++))
        
        # Show progress every 20 files
        if [ $((files_checked % 20)) -eq 0 ]; then
            echo -ne "\r  Checked: $files_checked/$file_count"
        fi
        
        local file_owner=$(stat -c '%U' "$file" 2>/dev/null)
        if [ "$file_owner" != "$current_user" ]; then
            non_owned_files+=("$file (owner: $file_owner)")
            issues_found=true
        fi
        
        # Check if file is writable
        if [ ! -w "$file" ]; then
            echo -ne "\r\033[K"  # Clear the progress line
            echo -e "${YELLOW}⚠ WARNING: No write permission to file: $file${NC}"
            issues_found=true
        fi
    done < <(find "$search_dir" -type f -iregex ".*\.\(avi\|mkv\|mp4\|mov\|wmv\|flv\|webm\|m4v\|mpg\|mpeg\|3gp\|ogv\)$" -print0 2>/dev/null)
    
    echo -ne "\r\033[K"  # Clear the progress line
    
    if [ ${#non_owned_files[@]} -gt 0 ]; then
        echo -e "${RED}⚠ WARNING: Found video files owned by other users:${NC}"
        for file_info in "${non_owned_files[@]}"; do
            echo -e "${YELLOW}  $file_info${NC}"
        done
        echo -e "${YELLOW}You may need to run the script with elevated privileges (sudo) to modify these files.${NC}"
    fi
    
    # Check if we can create the removed folder
    local removed_test_dir="${search_dir}/${REMOVED_FOLDER}_test"
    if ! mkdir -p "$removed_test_dir" 2>/dev/null; then
        echo -e "${RED}⚠ WARNING: Cannot create directories in: $search_dir${NC}"
        echo -e "${YELLOW}The safe removal feature may not work properly.${NC}"
        issues_found=true
    else
        rmdir "$removed_test_dir" 2>/dev/null
    fi
    
    if [ "$issues_found" = true ]; then
        echo
        echo -e "${YELLOW}═══ PERMISSION RECOMMENDATIONS ═══${NC}"
        echo -e "${BLUE}Option 1 (Recommended):${NC} Change to a directory you own and have write access to"
        echo -e "${BLUE}Option 2:${NC} Run with sudo if you need to modify files owned by other users:"
        echo -e "  ${GREEN}sudo $0 $search_dir${NC}"
        echo -e "${BLUE}Option 3:${NC} Change ownership of the files first:"
        echo -e "  ${GREEN}sudo chown -R $current_user:$current_user $search_dir${NC}"
        echo
        local choice=$(get_user_choice "Do you want to continue anyway?" "n" "false")
        if [[ "$choice" != "y" ]]; then
            echo "Exiting due to permission issues."
            exit 1
        fi
        echo
    else
        echo -e "${GREEN}✓ File permissions look good${NC}"
    fi
}

# Function to save default movie folder
save_default_folder() {
    local folder="$1"
    # Convert to absolute path
    local abs_folder=$(realpath "$folder" 2>/dev/null || echo "$folder")
    echo "DEFAULT_MOVIE_FOLDER=\"$abs_folder\"" > "$CONFIG_FILE"
    echo -e "${GREEN}✓ Saved '$abs_folder' as default movie folder${NC}"
    
    # Also save to INI file
    set_ini_setting "default_folder" "$abs_folder"
}

# Function to load default movie folder
load_default_folder() {
    # Try to load from INI first
    local ini_folder=$(get_ini_setting "default_folder")
    if [ -n "$ini_folder" ] && [ -d "$ini_folder" ]; then
        echo "$ini_folder"
        return 0
    fi
    
    # Fall back to old config file
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        if [ -n "$DEFAULT_MOVIE_FOLDER" ] && [ -d "$DEFAULT_MOVIE_FOLDER" ]; then
            echo "$DEFAULT_MOVIE_FOLDER"
            return 0
        fi
    fi
    
    echo ""
    return 1
}

# Function to pick folder using GUI file browser (if available)
pick_folder_gui() {
    local default_path="${1:-.}"
    
    # Try zenity first (most common and reliable)
    if command -v zenity &> /dev/null; then
        local selected_folder=$(zenity --file-selection --directory \
            --title="Select Movie Folder" \
            --filename="$default_path/" \
            2>/dev/null)
        
        if [ -n "$selected_folder" ] && [ -d "$selected_folder" ]; then
            echo "$selected_folder"
            return 0
        else
            return 1
        fi
    fi
    
    # Try kdialog (KDE alternative)
    if command -v kdialog &> /dev/null; then
        local selected_folder=$(kdialog --getexistingdirectory "$default_path" \
            --title "Select Movie Folder" 2>/dev/null)
        
        if [ -n "$selected_folder" ] && [ -d "$selected_folder" ]; then
            echo "$selected_folder"
            return 0
        else
            return 1
        fi
    fi
    
    # Try macOS open dialog
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local selected_folder=$(/usr/bin/osascript -e \
            "tell application \"System Events\" to activate
            set myPath to \"$default_path\"
            set folderPath to POSIX path of (choose folder with prompt \"Select Movie Folder\" default location POSIX file myPath)" 2>/dev/null)
        
        if [ -n "$selected_folder" ] && [ -d "$selected_folder" ]; then
            echo "$selected_folder"
            return 0
        else
            return 1
        fi
    fi
    
    # No GUI available
    return 1
}

# Function to prompt for movie folder
prompt_for_movie_folder() {
    local default_folder=$(load_default_folder)
    local current_dir=$(pwd)
    
    echo -e "${BLUE}--- Movie Folder Setup ---${NC}" >&2
    
    if [ -n "$default_folder" ] && [ -d "$default_folder" ]; then
        echo -e "${GREEN}Current default movie folder: $default_folder${NC}" >&2
        echo -n "Use this folder? [Y/n]: " >&2
        
        # Try to read from TTY if available, otherwise use stdin
        if [ -t 0 ]; then
            # Interactive mode - read from TTY
            read -r use_default </dev/tty
        else
            # Non-interactive mode - read from stdin with timeout
            if read -r -t 1 use_default; then
                :
            else
                # No input provided, default to yes
                echo "" >&2
                echo "$default_folder"
                return 0
            fi
        fi
        
        case "$use_default" in
            [Nn]|[Nn][Oo])
                # User said no, continue to folder selection
                ;;
            *)
                # Default to yes (empty response or 'y')
                echo "$default_folder"
                return 0
                ;;
        esac
    fi
    
    echo -e "${YELLOW}Please specify your movie folder:${NC}" >&2
    echo -e "Options:" >&2
    echo -e "  1. Current directory: $current_dir" >&2
    echo -e "  2. Enter custom path" >&2
    
    # Check if GUI tools are available (without actually calling them)
    local gui_available=false
    if command -v zenity &> /dev/null || command -v kdialog &> /dev/null || [[ "$OSTYPE" == "darwin"* ]]; then
        gui_available=true
        echo -e "  3. Browse with file picker (GUI)" >&2
    fi
    
    if [ -n "$default_folder" ]; then
        if [ "$gui_available" = true ]; then
            echo -e "  4. Previous default: $default_folder" >&2
        else
            echo -e "  3. Previous default: $default_folder" >&2
        fi
    fi
    echo >&2
    echo -n "Choice [1]: " >&2
    
    # Try to read from TTY if available, otherwise use stdin with timeout
    if [ -t 0 ]; then
        read -r choice </dev/tty
    else
        if read -r -t 1 choice; then
            :
        else
            # No input, default to option 1
            choice="1"
        fi
    fi
    
    # Validate choice - must be 1-4 depending on available options
    local max_choice=2
    if [ "$gui_available" = true ]; then
        max_choice=3
        if [ -n "$default_folder" ]; then
            max_choice=4
        fi
    else
        if [ -n "$default_folder" ]; then
            max_choice=3
        fi
    fi
    
    while ! [[ "$choice" =~ ^[1-$max_choice]$ ]] && [ -n "$choice" ]; do
        echo -e "${YELLOW}⚠ Invalid choice '$choice'. Please enter 1-$max_choice${NC}" >&2
        echo -n "Choice [1]: " >&2
        if [ -t 0 ]; then
            read -r choice </dev/tty
        else
            if read -r -t 1 choice; then
                :
            else
                choice="1"
            fi
        fi
    done
    
    # Use default if empty
    [ -z "$choice" ] && choice="1"
    
    case "$choice" in
        2)
            echo -n "Enter movie folder path: " >&2
            if [ -t 0 ]; then
                read -r custom_path </dev/tty
            else
                if read -r -t 2 custom_path; then
                    :
                else
                    # No input, use current directory
                    echo "$current_dir"
                    return 0
                fi
            fi
            if [ -d "$custom_path" ]; then
                save_default_folder "$custom_path"
                echo "$custom_path"
            else
                echo -e "${RED}Error: Directory '$custom_path' does not exist${NC}"
                echo "Create it?"
                create_choice=$(get_user_choice)
                if [ "$create_choice" = "y" ]; then
                    if mkdir -p "$custom_path" 2>/dev/null; then
                        echo -e "${GREEN}✓ Created directory: $custom_path${NC}"
                        save_default_folder "$custom_path"
                        echo "$custom_path"
                    else
                        echo -e "${RED}✗ Failed to create directory${NC}"
                        echo "$current_dir"
                    fi
                else
                    echo "$current_dir"
                fi
            fi
            ;;
        3)
            # Check if this is GUI option or default folder option
            if [ "$gui_available" = true ]; then
                echo -e "${BLUE}Opening file picker...${NC}"
                selected_folder=$(pick_folder_gui "$current_dir")
                if [ -n "$selected_folder" ] && [ -d "$selected_folder" ]; then
                    save_default_folder "$selected_folder"
                    echo "$selected_folder"
                else
                    echo -e "${YELLOW}No folder selected, using current directory${NC}"
                    save_default_folder "$current_dir"
                    echo "$current_dir"
                fi
            else
                # No GUI, so this is the default folder option
                if [ -n "$default_folder" ] && [ -d "$default_folder" ]; then
                    echo "$default_folder"
                else
                    echo "$current_dir"
                fi
            fi
            ;;
        4)
            # This is only available if GUI is enabled and default folder exists
            if [ "$gui_available" = true ] && [ -n "$default_folder" ] && [ -d "$default_folder" ]; then
                echo "$default_folder"
            else
                echo "$current_dir"
            fi
            ;;
        *)
            save_default_folder "$current_dir"
            echo "$current_dir"
            ;;
    esac
}

# Function to check if required tools are installed
check_dependencies() {
    local missing_tools=()
    
    if ! command -v ffprobe &> /dev/null; then
        missing_tools+=("ffprobe")
    fi
    
    if ! command -v ffmpeg &> /dev/null; then
        missing_tools+=("ffmpeg")
    fi
    
    # mkvpropedit is optional - only warn if not present
    if ! command -v mkvpropedit &> /dev/null; then
        echo -e "${YELLOW}Note: mkvpropedit (mkvtoolnix) not found - MKV files will use slower ffmpeg method${NC}"
    fi
    
    if ! command -v mpv &> /dev/null && ! command -v vlc &> /dev/null && ! command -v mplayer &> /dev/null && ! command -v smplayer &> /dev/null; then
        missing_tools+=("video player (smplayer, mpv, vlc, or mplayer)")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools:${NC}"
        printf '%s\n' "${missing_tools[@]}"
        echo
        # Offer to install dependencies
        install_dependencies "${missing_tools[@]}"
    fi
}

# Function to get preferred video player
get_video_player() {
    if command -v smplayer &> /dev/null; then
        echo "smplayer"
    elif command -v mpv &> /dev/null; then
        echo "mpv"
    elif command -v vlc &> /dev/null; then
        echo "vlc"
    elif command -v mplayer &> /dev/null; then
        echo "mplayer"
    else
        echo ""
    fi
}

# Function to check if file has audio language metadata
check_audio_language() {
    local file="$1"
    local lang_info
    
    # Get audio stream language information
    lang_info=$(ffprobe -v quiet -select_streams a:0 -show_entries stream_tags=language -of csv=p=0 "$file" 2>/dev/null)
    
    if [ -z "$lang_info" ] || [ "$lang_info" = "N/A" ]; then
        echo -e "${YELLOW}ℹ Checking audio metadata: No language metadata found${NC}" >&2
        return 1  # No language set
    else
        echo -e "${GREEN}✓ Checking audio metadata: Language found ($lang_info)${NC}" >&2
        return 0  # Language is set
    fi
}

# Function to check if file is a sample file (less than 400MB and has "sample" in name)
is_sample_file() {
    local file="$1"
    local filename=$(basename "$file")
    local filesize_mb
    local large_file_size_gb=$(get_ini_setting "large_file_size_gb")
    local removable_patterns=$(get_ini_setting "removable_files")
    
    # Check against removable patterns from INI
    IFS='|' read -ra patterns <<< "$removable_patterns"
    for pattern in "${patterns[@]}"; do
        # Support glob patterns like "sample.*" and "www.yts.mx"
        if [[ "$filename" == $pattern ]]; then
            echo -e "${YELLOW}ℹ Sample file detected: $filename (matches: $pattern)${NC}" >&2
            return 0  # Match found, is a removable file
        fi
    done
    
    # If no pattern matched, not a removable file
    return 1
}

# Function to get file size in human readable format
get_file_size() {
    local file="$1"
    local size
    if command -v du &> /dev/null; then
        size=$(du -h "$file" 2>/dev/null | cut -f1)
    else
        size=$(ls -lh "$file" 2>/dev/null | awk '{print $5}')
    fi
    
    if [ -n "$size" ]; then
        echo -e "${BLUE}ℹ File size: $size${NC}" >&2
        echo "$size"
    else
        echo -e "${YELLOW}⚠ Could not determine file size${NC}" >&2
    fi
}

# Function to get all audio languages from a video file
# Function to clean movie name from quality indicators and release tags
clean_movie_name() {
    local name="$1"
    
    # Convert to lowercase for pattern matching, but preserve original case for final result
    local lower_name="${name,,}"
    
    # Define patterns to remove (case insensitive)
    local patterns=(
        # Video quality indicators
        "720p?" "1080p?" "2160p?" "4k" "hd" "fhd" "uhd"
        # Video formats and codecs
        "x264" "x265" "h264" "h265" "hevc" "avc" "xvid" "divx"
        # Audio codecs
        "aac" "ac3" "dts" "dd5\.?1" "truehd" "atmos"
        # Release types
        "webrip" "web-rip" "webdl" "web-dl" "brrip" "br-rip" "bluray" "blu-ray"
        "dvdrip" "dvd-rip" "hdtv" "pdtv" "cam" "ts" "tc" "scr" "r5" "dvdscr"
        # Release groups and sources
        "amzn" "nf" "netflix" "hulu" "hbo" "max" "apple" "disney" "paramount"
        "yify" "rarbg" "ettv" "eztv" "torrentgalaxy" "1337x"
        # Other indicators
        "repack" "proper" "uncut" "extended" "directors?\.?cut" "theatrical"
        "internal" "limited" "festival" "screener" "workprint"
        # Years ONLY when NOT in parentheses or brackets (will be handled separately)
        # This pattern removes standalone years not in () or []
    )
    
    # Remove patterns from the name
    local cleaned_name="$name"
    for pattern in "${patterns[@]}"; do
        # Remove the pattern and any surrounding dots, dashes, or spaces
        cleaned_name=$(echo "$cleaned_name" | sed -E "s/[._-]*${pattern}[._-]*//gi")
    done
    
    # Remove standalone years (not in parentheses or brackets) - preserve years in () or []
    # This removes years like "Movie 2025 Quality" but keeps "Movie (2025)" or "Movie [2025]"
    cleaned_name=$(echo "$cleaned_name" | sed -E 's/[._-]+(19|20)[0-9]{2}[._-]+/ /gi')
    
    # Clean up multiple separators and trim
    cleaned_name=$(echo "$cleaned_name" | sed -E 's/[._-]+/./g' | sed -E 's/^[._-]+|[._-]+$//g')
    
    # Convert dots to spaces for final output
    cleaned_name=$(echo "$cleaned_name" | sed 's/[._-]/ /g')
    
    # Remove extra spaces and trim
    cleaned_name=$(echo "$cleaned_name" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
    
    echo "$cleaned_name"
}

# Function to extract movie name and year from filename
extract_movie_info() {
    local filename="$1"
    local movie_name=""
    local year=""
    
    # First clean the filename from quality indicators
    local cleaned_filename=$(clean_movie_name "$filename")
    
    # Try to extract year in format (YYYY) or [YYYY]
    if [[ "$cleaned_filename" =~ \(([0-9]{4})\) ]]; then
        year="${BASH_REMATCH[1]}"
        # Get everything before (YEAR)
        movie_name=$(echo "$cleaned_filename" | sed -E 's/\([0-9]{4}\).*//' | sed 's/ *$//')
    elif [[ "$cleaned_filename" =~ \[([0-9]{4})\] ]]; then
        year="${BASH_REMATCH[1]}"
        # Get everything before [YEAR]
        movie_name=$(echo "$cleaned_filename" | sed -E 's/\[[0-9]{4}\].*//' | sed 's/ *$//')
    elif [[ "$cleaned_filename" =~ ([0-9]{4}) ]]; then
        # Any 4-digit year found in the filename
        year="${BASH_REMATCH[1]}"
        movie_name=$(echo "$cleaned_filename" | sed -E "s/ *${year}.*$//" | sed 's/ *$//')
    else
        # No year found, use cleaned filename as is
        movie_name="$cleaned_filename"
        year=""
    fi
    
    # Final cleanup of movie name
    movie_name=$(echo "$movie_name" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
    
    # Show extraction result with visual feedback
    if [ -n "$year" ]; then
        echo -e "${GREEN}✓ Extracted: $movie_name ($year)${NC}" >&2
    else
        echo -e "${BLUE}ℹ Extracted: $movie_name (no year found)${NC}" >&2
    fi
    
    # Return in format: MovieName|Year
    echo "${movie_name}|${year}"
}

# Function to generate new directory name based on movie info only
generate_directory_name() {
    local file="$1"
    local dir_path=$(dirname "$file")
    local filename=$(basename "$file")
    local base_name="${filename%.*}"
    
    # Extract movie info
    local movie_info=$(extract_movie_info "$base_name")
    local movie_name=$(echo "$movie_info" | cut -d'|' -f1)
    local year=$(echo "$movie_info" | cut -d'|' -f2)
    
    # Build new directory name: Title_(Year) format
    local new_dir_name=""
    if [ -n "$year" ]; then
        # Convert movie name spaces to underscores and add year
        local movie_name_clean=$(echo "$movie_name" | sed 's/ /_/g')
        new_dir_name="${movie_name_clean}_(${year})"
        echo -e "${GREEN}✓ Generated directory: $new_dir_name${NC}" >&2
    else
        # No year found, just use movie name
        local movie_name_clean=$(echo "$movie_name" | sed 's/ /_/g')
        new_dir_name="${movie_name_clean}"
        echo -e "${BLUE}ℹ Generated directory (no year): $new_dir_name${NC}" >&2
    fi
    
    echo "$new_dir_name"
}

# Function to handle subtitle files - searches original folder recursively and copies to new folder
move_subtitles_with_movie() {
    local movie_file="$1"
    local movie_dir=$(dirname "$movie_file")
    local movie_name="${movie_file%.*}"
    local movie_basename=$(basename "$movie_name")
    
    # Get subtitle extensions from INI
    local subtitle_exts_str=$(get_ini_setting "subtitle_extensions")
    IFS='|' read -ra subtitle_extensions <<< "$subtitle_exts_str"
    local subs_found=0
    local subs_copied=0
    
    echo -e "${BLUE}═══ Subtitle Handling ═══${NC}"
    
    # Search for subtitle files recursively in the original parent directory
    local original_parent=$(dirname "$movie_dir")
    if [ ! -d "$original_parent" ]; then
        echo -e "${YELLOW}ℹ Original parent folder not accessible${NC}"
        return 0
    fi
    
    # Search for subtitle files recursively
    for ext in "${subtitle_extensions[@]}"; do
        while IFS= read -r -d '' sub_file; do
            if [ -f "$sub_file" ]; then
                local sub_basename=$(basename "$sub_file")
                local sub_name="${sub_basename%.*}"
                local sub_ext="${sub_basename##*.}"
                
                # Skip if it's the movie file itself
                if [ "$sub_file" = "$movie_file" ]; then
                    continue
                fi
                
                # Try to extract language code (2-3 lowercase letters)
                local language=""
                if [[ "$sub_name" =~ ([a-z]{2,3})$ ]]; then
                    language="${BASH_REMATCH[1]}"
                    # Rename with detected language: moviename.language.ext
                    local new_sub_name="${movie_basename}.${language}.${sub_ext}"
                else
                    # No language detected, use original name: moviename.filename.ext
                    local new_sub_name="${movie_basename}.${sub_name}.${sub_ext}"
                fi
                
                local new_sub_path="${movie_dir}/${new_sub_name}"
                
                # Copy subtitle file to new movie folder
                if cp "$sub_file" "$new_sub_path" 2>/dev/null; then
                    if [ -n "$language" ]; then
                        echo -e "${GREEN}✓ Copied subtitle: $sub_basename → $new_sub_name (lang: $language)${NC}"
                    else
                        echo -e "${GREEN}✓ Copied subtitle: $sub_basename → $new_sub_name${NC}"
                    fi
                    subs_copied=$((subs_copied + 1))
                    subs_found=$((subs_found + 1))
                else
                    echo -e "${YELLOW}⚠ Failed to copy subtitle: $sub_basename${NC}"
                    subs_found=$((subs_found + 1))
                fi
            fi
        done < <(find "$original_parent" -type f -name "*.$ext" -print0 2>/dev/null)
    done
    
    if [ $subs_found -gt 0 ]; then
        echo -e "${GREEN}✓ Subtitle handling complete ($subs_copied copied)${NC}"
    else
        echo -e "${YELLOW}ℹ No subtitle files found${NC}"
    fi
    
    return 0
}

# Function to rename/move file into its own directory
rename_with_languages() {
    local file="$1"
    local parent_dir=$(dirname "$file")
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    
    # Generate new directory name (Title_(Year) format)
    local new_dir_name=$(generate_directory_name "$file")
    local new_dir_path="${parent_dir}/${new_dir_name}"
    local new_file_path="${new_dir_path}/${new_dir_name}.${extension}"
    
    # Verify parent directory exists and is valid
    if [ ! -d "$parent_dir" ]; then
        echo -e "${RED}✗ Parent directory does not exist: $parent_dir${NC}"
        return 1
    fi
    
    # Check if file is already in its own directory with correct name
    local current_dir_name=$(basename "$parent_dir")
    if [ "$current_dir_name" = "$new_dir_name" ] && [ "$(basename "$file" ".$extension")" = "$new_dir_name" ]; then
        echo -e "${GREEN}✓ File already organized correctly${NC}"
        return 0
    fi
    
    echo -e "${BLUE}═══ File Organization ═══${NC}"
    echo -e "${BLUE}Current location: $parent_dir${NC}"
    echo -e "${BLUE}New subfolder: $new_dir_name${NC}"
    echo -e "${BLUE}Proposed organization:${NC}"
    echo -e "  From: $file"
    echo -e "  To:   $new_file_path"
    echo
    
    # In non-interactive mode, automatically organize with batch "yes to all"
    if [ ! -t 0 ] && [ "$BATCH_MODE" != "yes_all" ] && [ "$BATCH_MODE" != "no_all" ]; then
        BATCH_MODE="yes_all"
        echo -e "${GREEN}✓ Non-interactive mode: auto-organizing all files${NC}" >&2
    fi
    
    local choice=$(get_user_choice "Do you want to organize this file into its own directory?" "y")
    
    if [[ "$choice" = "y" ]]; then
        # Create new directory if it doesn't exist
        if [ ! -d "$new_dir_path" ]; then
            if mkdir -p "$new_dir_path" 2>/dev/null; then
                echo -e "${GREEN}✓ Created directory in: $parent_dir${NC}"
                echo -e "${GREEN}  New folder: $new_dir_name${NC}"
            else
                echo -e "${RED}✗ Failed to create directory: $new_dir_path${NC}"
                echo -e "${YELLOW}Possible causes: Permission denied, invalid path, or disk full${NC}"
                echo -e "${YELLOW}Target location was: $parent_dir${NC}"
                return 1
            fi
        fi
        
        # Verify new directory is writable
        if [ ! -w "$new_dir_path" ]; then
            echo -e "${RED}✗ No write permission to new directory: $new_dir_path${NC}"
            return 1
        fi
        
        # Verify source file is readable
        if [ ! -r "$file" ]; then
            echo -e "${RED}✗ No read permission to source file: $file${NC}"
            return 1
        fi
        
        # Move/rename the file with validation
        if mv "$file" "$new_file_path" 2>/dev/null; then
            # Verify file was actually moved
            if [ -f "$new_file_path" ] && [ ! -f "$file" ]; then
                echo -e "${GREEN}✓ Successfully organized file${NC}"
                echo -e "${GREEN}  Location: $new_dir_path${NC}"
                
                # Handle subtitle files
                move_subtitles_with_movie "$new_file_path"
                
                # Check old directory and move it to Aa.removed if empty
                local old_dir=$(dirname "$file")
                
                if [ "$old_dir" != "$new_dir_path" ] && [ -d "$old_dir" ]; then
                    local file_count=$(find "$old_dir" -mindepth 1 -maxdepth 1 -type f 2>/dev/null | wc -l)
                    local dir_count=$(find "$old_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
                    
                    # If directory is empty (no files or subdirs), move to removed folder
                    if [ "$file_count" -eq 0 ] && [ "$dir_count" -eq 0 ]; then
                        echo -e "${BLUE}Old directory is empty, moving to removed folder...${NC}"
                        if move_to_removed "$old_dir" "$new_dir_path"; then
                            echo -e "${GREEN}✓ Old directory moved to: ${REMOVED_FOLDER}${NC}"
                        else
                            echo -e "${YELLOW}⚠ Could not move old directory${NC}"
                        fi
                    elif [ "$file_count" -eq 0 ] && [ "$dir_count" -gt 0 ]; then
                        # Only empty subdirectories exist
                        local all_empty=true
                        while IFS= read -r -d '' subdir; do
                            if [ "$(find "$subdir" -type f 2>/dev/null | wc -l)" -gt 0 ]; then
                                all_empty=false
                                break
                            fi
                        done < <(find "$old_dir" -mindepth 1 -maxdepth 1 -type d -print0)
                        
                        if [ "$all_empty" = true ]; then
                            echo -e "${BLUE}Old directory (with empty subdirs) moving to removed folder...${NC}"
                            if move_to_removed "$old_dir" "$new_dir_path"; then
                                echo -e "${GREEN}✓ Old directory moved to: ${REMOVED_FOLDER}${NC}"
                            else
                                echo -e "${YELLOW}⚠ Could not move old directory${NC}"
                            fi
                        else
                            echo -e "${YELLOW}⚠ Old directory contains files in subdirectories - not removing${NC}"
                        fi
                    else
                        echo -e "${YELLOW}⚠ Old directory still contains files - not removing${NC}"
                    fi
                fi
                return 0
            else
                echo -e "${RED}✗ File move verification failed - file not found at destination${NC}"
                echo -e "${YELLOW}Source: $file${NC}"
                echo -e "${YELLOW}Destination: $new_file_path${NC}"
                return 1
            fi
        else
            local mv_error=$?
            echo -e "${RED}✗ Failed to organize file (error code: $mv_error)${NC}"
            
            # Provide helpful error messages
            if [ ! -e "$file" ]; then
                echo -e "${YELLOW}Source file no longer exists: $file${NC}"
            elif [ -e "$new_file_path" ]; then
                echo -e "${YELLOW}Destination already exists: $new_file_path${NC}"
            else
                echo -e "${YELLOW}Possible causes: Permission denied, disk full, or invalid path${NC}"
            fi
            return 1
        fi
    else
        echo "Skipping organization..."
        return 1
    fi
}

# Function to print detailed summary
print_detailed_summary() {
    local -n names=$1
    local -n sizes=$2
    local -n statuses=$3
    local -n languages=$4
    
    echo
    echo "==============================="
    echo -e "${GREEN}DETAILED FILE SUMMARY${NC}"
    echo "==============================="
    
    if [ ${#names[@]} -eq 0 ]; then
        echo "No files processed."
        return
    fi
    
    # Print header
    printf "%-40s %-10s %-15s %-10s\n" "FILENAME" "SIZE" "STATUS" "LANGUAGE"
    echo "--------------------------------------------------------------------------------"
    
    # Print each file's details
    for i in "${!names[@]}"; do
        local filename="${names[$i]}"
        local size="${sizes[$i]}"
        local status="${statuses[$i]}"
        local language="${languages[$i]}"
        
        # Truncate filename if too long
        if [ ${#filename} -gt 37 ]; then
            filename="${filename:0:34}..."
        fi
        
        # Color code the status
        local colored_status=""
        case "$status" in
            "deleted_sample")
                colored_status="${RED}deleted_sample${NC}"
                ;;
            "sample_kept")
                colored_status="${YELLOW}sample${NC}"
                ;;
            "has_language")
                colored_status="${GREEN}has_language${NC}"
                ;;
            "has_und_language")
                colored_status="${YELLOW}und_language${NC}"
                ;;
            "language_set")
                colored_status="${BLUE}language_set${NC}"
                ;;
            "language_updated")
                colored_status="${BLUE}updated${NC}"
                ;;
            *"_organized")
                colored_status="${GREEN}${status}${NC}"
                ;;
            "no_language")
                colored_status="${YELLOW}no_language${NC}"
                ;;
            *)
                colored_status="$status"
                ;;
        esac
        
        printf "%-40s %-10s %-15s %-10s\n" "$filename" "$size" "$colored_status" "$language"
    done
    
    echo
}

# Function to prompt for sample file removal (auto-remove without asking)
prompt_sample_removal() {
    local file="$1"
    local movie_folder="$2"  # The target movie folder (or search_dir if not yet organized)
    local filesize=$(get_file_size "$file")
    
    echo -e "\n${YELLOW}🎬 SAMPLE FILE DETECTED:${NC}"
    echo -e "File: $(basename "$file")"
    echo -e "Size: ${filesize}"
    echo -e "Path: $file"
    echo -e "${BLUE}Auto-removing sample file...${NC}"
    
    if move_to_removed "$file" "$movie_folder"; then
        return 0
    else
        return 1
    fi
}

# Function to get current audio language
get_audio_language() {
    local file="$1"
    ffprobe -v quiet -select_streams a:0 -show_entries stream_tags=language -of csv=p=0 "$file" 2>/dev/null
}

# Function to detect if file is MKV and supports mkvpropedit
is_mkv_file() {
    local file="$1"
    [[ "${file,,}" == *.mkv ]]
}

# Function to set audio language with failproof mechanisms
set_audio_language() {
    local input_file="$1"
    local language="$2"
    local file_dir=$(dirname "$input_file")
    local file_name=$(basename "$input_file")
    local file_ext="${input_file##*.}"
    local base_name="${file_name%.*}"
    
    # Generate unique temporary file names
    local temp_file="${file_dir}/.${base_name}_temp_$$_$(date +%s).${file_ext}"
    local backup_file="${file_dir}/.${base_name}_backup_$$_$(date +%s).${file_ext}"
    
    # Cleanup function for safe exit - ensures temp/backup files are always removed
    cleanup_temp_files() {
        if [ -f "$temp_file" ]; then
            rm -f "$temp_file" 2>/dev/null && echo -e "${BLUE}[Cleanup] Removed temp file${NC}" >&2
        fi
        if [ -f "$backup_file" ]; then
            rm -f "$backup_file" 2>/dev/null && echo -e "${BLUE}[Cleanup] Removed backup file${NC}" >&2
        fi
    }
    
    # Set trap to cleanup on function exit/interrupt
    trap 'cleanup_temp_files' EXIT INT TERM
    
    echo -e "${BLUE}Setting audio language to '${language}' for: ${input_file}${NC}"
    
    # Pre-flight checks
    if [ ! -f "$input_file" ]; then
        echo -e "${RED}✗ File does not exist: $input_file${NC}"
        cleanup_temp_files
        return 1
    fi
    
    if [ ! -r "$input_file" ]; then
        echo -e "${RED}✗ No read permission to file: $input_file${NC}"
        cleanup_temp_files
        return 1
    fi
    
    if [ ! -w "$input_file" ]; then
        echo -e "${RED}✗ No write permission to file: $input_file${NC}"
        echo -e "${YELLOW}You may need to run the script with elevated privileges (sudo)${NC}"
        cleanup_temp_files
        return 1
    fi
    
    if [ ! -w "$file_dir" ]; then
        echo -e "${RED}✗ No write permission to directory: $file_dir${NC}"
        echo -e "${YELLOW}You may need to run the script with elevated privileges (sudo)${NC}"
        cleanup_temp_files
        return 1
    fi
    
    # Check available disk space (need at least file size + 10MB buffer)
    local file_size=$(stat -c%s "$input_file" 2>/dev/null || echo "0")
    local required_space=$((file_size + 10485760))  # file size + 10MB
    local available_space=$(df "$file_dir" | awk 'NR==2 {print $4*1024}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        echo -e "${RED}✗ Insufficient disk space. Need $(($required_space/1048576))MB, have $(($available_space/1048576))MB${NC}"
        return 1
    fi
    
    # Validate language code format
    if [[ ! "$language" =~ ^[a-z]{2,3}$ ]]; then
        echo -e "${YELLOW}⚠ Warning: '$language' doesn't match standard language code format${NC}"
    fi
    
    # Choose method based on file type
    local use_mkvpropedit=false
    if is_mkv_file "$input_file" && command -v mkvpropedit &> /dev/null; then
        use_mkvpropedit=true
        echo -e "${BLUE}Using mkvpropedit for MKV file (faster, no re-encoding)${NC}"
    else
        echo -e "${BLUE}Using ffmpeg for metadata setting${NC}"
    fi
    
    # For MKV files with mkvpropedit - much simpler and safer
    if [ "$use_mkvpropedit" = true ]; then
        echo -e "${BLUE}Setting language with mkvpropedit...${NC}"
        
        if mkvpropedit "$input_file" --edit track:a1 --set language="$language" &>/dev/null; then
            echo -e "${GREEN}✓ Successfully set audio language to '${language}'${NC}"
            
            # Verify the change
            local final_lang=$(ffprobe -v quiet -select_streams a:0 -show_entries stream_tags=language -of csv=p=0 "$input_file" 2>/dev/null)
            if [ "$final_lang" = "$language" ]; then
                echo -e "${GREEN}✓ Verification successful${NC}"
            else
                echo -e "${YELLOW}⚠ Verification shows: '$final_lang' (may be normal)${NC}"
            fi
            cleanup_temp_files
            return 0
        else
            echo -e "${YELLOW}⚠ mkvpropedit failed, falling back to ffmpeg method${NC}"
            use_mkvpropedit=false
        fi
    fi
    
    # Skip ffmpeg method if mkvpropedit was successful
    if [ "$use_mkvpropedit" = true ]; then
        cleanup_temp_files
        return 0
    fi
    
    # Continue with ffmpeg method for non-MKV files or if mkvpropedit failed
    echo -e "${BLUE}Using ffmpeg method - creating backup and processing...${NC}"
    
    # Step 1: Create backup of original file
    echo -e "${BLUE}Creating backup...${NC}"
    if ! cp "$input_file" "$backup_file" 2>/dev/null; then
        echo -e "${RED}✗ Failed to create backup file${NC}"
        cleanup_temp_files
        return 1
    fi
    
    # Verify backup integrity
    local orig_checksum=$(md5sum "$input_file" 2>/dev/null | cut -d' ' -f1)
    local backup_checksum=$(md5sum "$backup_file" 2>/dev/null | cut -d' ' -f1)
    
    if [ "$orig_checksum" != "$backup_checksum" ]; then
        echo -e "${RED}✗ Backup verification failed (checksum mismatch)${NC}"
        cleanup_temp_files
        return 1
    fi
    
    echo -e "${GREEN}✓ Backup created and verified${NC}"
    
    # Step 2: Process with ffmpeg using multiple attempts
    local max_attempts=3
    local attempt=1
    local ffmpeg_success=false
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "${BLUE}Processing attempt $attempt/$max_attempts...${NC}"
        
        # Remove any existing temp file from previous attempts
        rm -f "$temp_file" 2>/dev/null
        
        # Run ffmpeg with timeout and detailed error capture
        local ffmpeg_error_log=$(mktemp)
        if timeout 120 ffmpeg -i "$input_file" -c copy -metadata:s:a:0 language="$language" "$temp_file" -y 2>"$ffmpeg_error_log"; then
            # Verify temp file was created and has reasonable size
            if [ -f "$temp_file" ] && [ -s "$temp_file" ]; then
                local temp_size=$(stat -c%s "$temp_file" 2>/dev/null || echo "0")
                local orig_size=$(stat -c%s "$input_file" 2>/dev/null || echo "0")
                
                # Check if temp file size is reasonable (within 10% of original)
                local size_diff=$((orig_size - temp_size))
                local max_diff=$((orig_size / 10))
                
                if [ ${size_diff#-} -le $max_diff ]; then  # absolute value comparison
                    ffmpeg_success=true
                    rm -f "$ffmpeg_error_log"
                    break
                else
                    echo -e "${YELLOW}⚠ Attempt $attempt: Output file size suspicious (orig: ${orig_size}, new: ${temp_size})${NC}"
                fi
            else
                echo -e "${YELLOW}⚠ Attempt $attempt: No output file created${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ Attempt $attempt: ffmpeg failed${NC}"
            if [ -s "$ffmpeg_error_log" ]; then
                echo -e "${YELLOW}Error details: $(tail -2 "$ffmpeg_error_log" | head -1)${NC}"
            fi
        fi
        
        rm -f "$ffmpeg_error_log"
        rm -f "$temp_file" 2>/dev/null
        ((attempt++))
        
        if [ $attempt -le $max_attempts ]; then
            echo -e "${BLUE}Waiting 2 seconds before retry...${NC}"
            sleep 2
        fi
    done
    
    if [ "$ffmpeg_success" != true ]; then
        echo -e "${RED}✗ Failed to process file after $max_attempts attempts${NC}"
        cleanup_temp_files
        return 1
    fi
    
    echo -e "${GREEN}✓ Processing completed successfully${NC}"
    
    # Step 3: Verify the temp file contains expected metadata
    echo -e "${BLUE}Verifying metadata...${NC}"
    local new_lang=$(ffprobe -v quiet -select_streams a:0 -show_entries stream_tags=language -of csv=p=0 "$temp_file" 2>/dev/null)
    
    if [ "$new_lang" != "$language" ]; then
        echo -e "${YELLOW}⚠ Warning: Metadata verification failed. Expected: '$language', Got: '$new_lang'${NC}"
        local choice=$(get_user_choice "Continue anyway?" "n" "false")
        if [[ "$choice" != "y" ]]; then
            echo -e "${RED}✗ Operation cancelled by user${NC}"
            cleanup_temp_files
            return 1
        fi
    else
        echo -e "${GREEN}✓ Metadata verified: language set to '$language'${NC}"
    fi
    
    # Step 4: Atomic replacement using move operation
    echo -e "${BLUE}Applying changes...${NC}"
    
    # Verify temp file exists and is readable
    if [ ! -f "$temp_file" ]; then
        echo -e "${RED}✗ Error: Temporary file not found: $temp_file${NC}"
        cleanup_temp_files
        return 1
    fi
    
    if [ ! -r "$temp_file" ]; then
        echo -e "${RED}✗ Error: Cannot read temporary file (permission denied)${NC}"
        cleanup_temp_files
        return 1
    fi
    
    # Verify we can write to the destination
    if [ ! -w "$(dirname "$input_file")" ]; then
        echo -e "${RED}✗ Error: No write permission to: $(dirname "$input_file")${NC}"
        cleanup_temp_files
        return 1
    fi
    
    # First, ensure temp file permissions match original
    chmod --reference="$input_file" "$temp_file" 2>/dev/null || true
    chown --reference="$input_file" "$temp_file" 2>/dev/null || true
    
    # Atomic move operation with verification
    if mv "$temp_file" "$input_file" 2>/dev/null; then
        # Verify the replacement was successful
        if [ -f "$input_file" ]; then
            echo -e "${GREEN}✓ Successfully set audio language to '${language}'${NC}"
            
            # Final verification
            local final_lang=$(ffprobe -v quiet -select_streams a:0 -show_entries stream_tags=language -of csv=p=0 "$input_file" 2>/dev/null)
            if [ "$final_lang" = "$language" ]; then
                echo -e "${GREEN}✓ Final verification successful${NC}"
            else
                echo -e "${YELLOW}⚠ Final verification failed, but file was modified${NC}"
            fi
            cleanup_temp_files
            return 0
        else
            echo -e "${RED}✗ File move verification failed - destination file not found${NC}"
            cleanup_temp_files
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to apply changes (move operation failed)${NC}"
        
        # Attempt recovery from backup
        echo -e "${BLUE}Attempting to restore from backup...${NC}"
        
        if [ ! -f "$backup_file" ]; then
            echo -e "${RED}✗ CRITICAL: Backup file not found: $backup_file${NC}"
            cleanup_temp_files
            return 1
        fi
        
        if [ ! -r "$backup_file" ]; then
            echo -e "${RED}✗ CRITICAL: Cannot read backup file (permission denied)${NC}"
            cleanup_temp_files
            return 1
        fi
        
        # Attempt restoration with error checking
        if mv "$backup_file" "$input_file" 2>/dev/null; then
            if [ -f "$input_file" ] && [ ! -f "$backup_file" ]; then
                echo -e "${GREEN}✓ Successfully restored original file from backup${NC}"
                cleanup_temp_files
                return 1
            else
                echo -e "${RED}✗ CRITICAL: Backup restoration verification failed${NC}"
                echo -e "${YELLOW}Backup location: $backup_file${NC}"
                cleanup_temp_files
                return 1
            fi
        else
            echo -e "${RED}✗ CRITICAL: Failed to restore backup! Original file may be corrupted${NC}"
            echo -e "${YELLOW}Backup location: $backup_file${NC}"
            echo -e "${YELLOW}Please restore manually and run script again${NC}"
            cleanup_temp_files
            return 1
        fi
    fi
}

# Function to play video file
play_video() {
    local file="$1"
    local player="$2"
    
    echo -e "${YELLOW}Playing video: $(basename "$file")${NC}"
    echo "Close video player to return to script..."
    
    case "$player" in
        "mpv")
            mpv "$file" &>/dev/null
            ;;
        "vlc")
            vlc "$file" &>/dev/null
            ;;
        "smplayer")
            smplayer "$file" &>/dev/null
            ;;
        "mplayer")
            mplayer "$file" &>/dev/null
            ;;
    esac
}

# Function to process a single video file
process_video_file() {
    local file="$1"
    local player="$2"
    local current_lang
    
    echo -e "\n${BLUE}Processing: $file${NC}"
    
    # Check if audio language is set
    if check_audio_language "$file"; then
        current_lang=$(get_audio_language "$file")
        
        # Check if language is undefined (und)
        if [ "$current_lang" = "und" ]; then
            echo -e "${YELLOW}⚠ Audio language is set to 'und' (undefined)${NC}"
            local choice=$(get_user_choice "Do you want to set the correct language for this file?" "y")
            
            if [[ "$choice" = "y" ]]; then
                # Play the video file
                play_video "$file" "$player"
                
                # Prompt for language
                echo -n "Enter audio language code (default: eng): "
                read -r language </dev/tty
                
                # Use default if empty
                if [ -z "$language" ]; then
                    language="eng"
                fi
                
                # Validate language code (basic check for 2-3 character codes)
                if [[ ! "$language" =~ ^[a-z]{2,3}$ ]]; then
                    echo -e "${RED}Warning: '$language' doesn't look like a standard language code${NC}"
                    local choice=$(get_user_choice "Continue anyway?" "n" "false")
                    if [[ "$choice" != "y" ]]; then
                        echo "Skipping file..."
                        return 0
                    fi
                fi
                
                # Set the language
                set_audio_language "$file" "$language"
                return 0
            else
                echo -e "${GREEN}✓ Audio language set to: ${current_lang} (kept as is)${NC}"
                return 0
            fi
        else
            echo -e "${GREEN}✓ Audio language already set: ${current_lang}${NC}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}⚠ No audio language metadata found${NC}"
    
    # Ask user if they want to process this file
    local choice=$(get_user_choice "Do you want to set audio language for this file?" "y")
    
    if [[ "$choice" != "y" ]]; then
        echo "Skipping file..."
        return 0
    fi
    
    # Play the video file
    play_video "$file" "$player"
    
    # Prompt for language
    echo -n "Enter audio language code (default: eng): "
    read -r language </dev/tty
    
    # Use default if empty
    if [ -z "$language" ]; then
        language="eng"
    fi
    
    # Validate language code (basic check for 2-3 character codes)
    if [[ ! "$language" =~ ^[a-z]{2,3}$ ]]; then
        echo -e "${RED}Warning: '$language' doesn't look like a standard language code${NC}"
        local choice=$(get_user_choice "Continue anyway?" "n" "false")
        if [[ "$choice" != "y" ]]; then
            echo "Skipping file..."
            return 0
        fi
    fi
    
    # Set the language
    set_audio_language "$file" "$language"
}

# Main function
main() {
    local search_dir="$1"
    local video_extensions="avi|mkv|mp4|mov|wmv|flv|webm|m4v|mpg|mpeg|3gp|ogv"
    local player
    local file_count=0
    local processed_count=0
    local removed_count=0
    local renamed_count=0
    
    # Arrays to track detailed information for summary
    declare -a file_details_name=()
    declare -a file_details_size=()
    declare -a file_details_status=()
    declare -a file_details_language=()
    
    # Folder was already selected in the main script initialization
    # (moved before main() call for immediate visual feedback)
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Video Audio Language Setter v${SCRIPT_VERSION}${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    print_status "Working with: $search_dir" "info"
    echo
    
    # Ensure INI file exists, create if necessary
    if [ ! -f "$INI_CONFIG_FILE" ]; then
        save_ini_config
    fi
    
    # Display INI file contents
    display_ini_file
    echo
    
    print_section "INITIALIZATION"
    
    # Check if running with elevated privileges
    check_elevated_privileges
    
    # Check dependencies
    check_dependencies
    
    print_status "Checking file permissions..." "info"
    
    # Check file permissions and ownership
    check_file_permissions "$search_dir"
    
    print_section "FILE ORGANIZATION"
    print_status "Organizing file structure..." "info"
    
    # Remove small folders (< 5MB)
    remove_small_folders "$search_dir"
    
    # Ensure single-level directory structure
    ensure_single_level_structure "$search_dir"
    
    print_section "PROCESSING"
    
    # Get video player
    player=$(get_video_player)
    print_status "Video player: $player" "done"
    
    # Check if search directory exists
    if [ ! -d "$search_dir" ]; then
        echo -e "${RED}Error: Directory '$search_dir' does not exist${NC}"
        exit 1
    fi
    
    print_status "Searching for video files in: $search_dir" "info"
    echo
    
    # Find and process video files
    while IFS= read -r -d '' file; do
        ((file_count++))
        filename=$(basename "$file")
        filesize=$(get_file_size "$file")
        current_lang=""
        status=""
        
        # Show progress
        echo -e "${BLUE}[${file_count}]${NC} Processing: $filename"
        
        # Check if this is a sample file that should be removed
        if [ "$ENABLE_SAMPLE_REMOVAL" = true ] && is_sample_file "$file"; then
            if prompt_sample_removal "$file" "$search_dir"; then
                ((removed_count++))
                # Add to tracking arrays
                file_details_name+=("$filename")
                file_details_size+=("$filesize")
                file_details_status+=("deleted_sample")
                file_details_language+=("N/A")
                print_status "Removed as sample" "done"
                continue  # Skip further processing if file was removed
            else
                # Sample file kept
                status="sample_kept"
                print_status "Sample file kept" "warn"
            fi
        fi
        
        # Get current language if file exists
        if [ -f "$file" ]; then
            if check_audio_language "$file"; then
                current_lang=$(get_audio_language "$file")
                if [ -z "$status" ]; then
                    # Check if it's undefined language
                    if [ "$current_lang" = "und" ]; then
                        status="has_und_language"
                        print_status "Audio language: UNDEFINED" "warn"
                    else
                        status="has_language"
                        print_status "Audio language: $current_lang" "done"
                    fi
                fi
            else
                current_lang="none"
                if [ -z "$status" ]; then
                    status="no_language"
                    print_status "No audio language metadata" "warn"
                fi
            fi
        fi
        
        # Process the file for language setting
        if process_video_file "$file" "$player"; then
            ((processed_count++))
            # Check if language was updated from undefined or none
            if [ -f "$file" ]; then
                new_lang=$(get_audio_language "$file" 2>/dev/null)
                if [ -n "$new_lang" ] && [ "$new_lang" != "N/A" ]; then
                    # Check if language changed from und or none
                    if [ "$current_lang" = "und" ] && [ "$new_lang" != "und" ]; then
                        current_lang="$new_lang"
                        status="language_updated"
                    elif [ "$current_lang" = "none" ] && [ "$new_lang" != "" ]; then
                        current_lang="$new_lang"
                        status="language_set"
                    fi
                fi
            fi
        fi
        
        # Offer to rename/move file into its own directory (for all video files)
        if [ "$ENABLE_RENAME" = true ] && [ -f "$file" ]; then
            echo
            if rename_with_languages "$file"; then
                ((renamed_count++))
                status="${status}_organized"
                # Update file reference for tracking
                local new_dir_name=$(generate_directory_name "$file")
                local parent_dir=$(dirname "$file")
                local extension="${filename##*.}"
                file="${parent_dir}/${new_dir_name}/${new_dir_name}.${extension}"
                filename="${new_dir_name}.${extension}"
            fi
        fi
        
        # Add to tracking arrays (if file still exists)
        if [ -f "$file" ]; then
            file_details_name+=("$filename")
            file_details_size+=("$filesize")
            file_details_status+=("$status")
            file_details_language+=("$current_lang")
        fi
        
    done < <(find "$search_dir" -type f -iregex ".*\.\(avi\|mkv\|mp4\|mov\|wmv\|flv\|webm\|m4v\|mpg\|mpeg\|3gp\|ogv\)$" -print0)
    
    # Summary
    echo
    print_section "SUMMARY"
    print_status "Processing complete!" "done"
    echo
    echo -e "  Total files found:     ${BLUE}$file_count${NC}"
    echo -e "  Files processed:       ${GREEN}$processed_count${NC}"
    if [ "$ENABLE_SAMPLE_REMOVAL" = true ] && [ $removed_count -gt 0 ]; then
        echo -e "  Sample files removed:  ${YELLOW}$removed_count${NC}"
    fi
    if [ "$ENABLE_RENAME" = true ] && [ $renamed_count -gt 0 ]; then
        echo -e "  Organized in folders:  ${BLUE}$renamed_count${NC}"
    fi
    
    # Show which features were disabled
    if [ "$ENABLE_RENAME" = false ] || [ "$ENABLE_SAMPLE_REMOVAL" = false ]; then
        echo
        echo -e "${YELLOW}Disabled features:${NC}"
        [ "$ENABLE_RENAME" = false ] && echo "  - File organization/renaming (--norename)"
        [ "$ENABLE_SAMPLE_REMOVAL" = false ] && echo "  - Sample file removal (--nosample)"
    fi
    
    # Print detailed summary
    print_detailed_summary file_details_name file_details_size file_details_status file_details_language
    
    if [ $file_count -eq 0 ]; then
        echo -e "${YELLOW}No video files found in the specified directory.${NC}"
    fi
    
    # Save settings to INI file
    save_ini_config
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS] [directory]"
    echo
    echo "Check video files for missing audio language metadata and set it interactively."
    echo "Also detects and offers to remove sample files (files with 'sample' in name and < 400MB)."
    echo "Automatically identifies files with 'und' (undefined) language and prompts for correction."
    echo "Offers to organize files into directories with format: Title_(Year)"
    echo "All removed files/directories are moved to 'Aa.removed' folder for safety."
    echo
    echo "Arguments:"
    echo "  directory       Directory to search for video files (optional - will prompt if not provided)"
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  --norename      Skip file organization/renaming (only set language metadata)"
    echo "  --nosample      Skip sample file detection and removal"
    echo
    echo "Examples:"
    echo "  $0                           # Will prompt for movie folder, then process with all features"
    echo "  $0 /movies                   # Process /movies with all features"
    echo "  $0 --norename /movies        # Only set languages, no organization"
    echo "  $0 --nosample /movies        # Skip sample file removal"
    echo "  $0 --norename --nosample /movies  # Only set language metadata"
    echo
    echo "Features:"
    echo "  - Recursive search through all subdirectories"
    echo "  - Audio language metadata detection and setting"
    echo "  - Fast MKV processing with mkvpropedit (no re-encoding)"
    echo "  - Undefined (und) language detection and correction"
    echo "  - Sample file detection and auto-removal (< 400MB with 'sample' in filename) [can disable]"
    echo "  - Interactive video playback for language identification"
    echo "  - Auto-organize ALL files: Each video gets its own Title_(Year) directory [can disable]"
    echo "  - Single-level directory structure enforcement (moves nested files up)"
    echo "  - Safe removal: All deleted items moved to 'Aa.removed' folder"
    echo
    echo "Organization Examples:"
    echo "  Hot_Milk_(2025).mp4 → Hot_Milk_(2025)/Hot_Milk_(2025).mp4"
    echo "  Old_Movie.mkv → Old_Movie/Old_Movie.mkv"
    echo
    echo "Removed Items:"
    echo "  All removed files/directories are moved to 'Aa.removed' folder in the search directory."
    echo "  You can recover them manually if needed."
    echo
    echo "Supported video formats: AVI, MKV, MP4, MOV, WMV, FLV, WebM, M4V, MPG, MPEG, 3GP, OGV"
    echo
    echo "Requirements:"
    echo "  - ffprobe and ffmpeg (for metadata manipulation)"
    echo "  - Video player: smplayer, mpv, vlc, or mplayer"
    echo "  - Write permissions to video files and directories"
    echo
    echo "Optional:"
    echo "  - mkvpropedit from mkvtoolnix (for faster MKV processing)"
    echo
    echo "Permissions:"
    echo "  The script needs write access to:"
    echo "  - Video files (to set metadata)"
    echo "  - Directory containing video files (to create temp files and Aa.removed folder)"
    echo "  - If files are owned by other users, you may need to run with sudo"
    echo
    echo "Permission Examples:"
    echo "  ./set_audio_language.sh /home/user/videos     # Normal user permissions"
    echo "  sudo ./set_audio_language.sh /media/videos    # Elevated permissions"
    echo "  sudo chown -R user:user /media/videos         # Change ownership first"
}

# Parse command-line arguments
SEARCH_DIR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --norename)
            ENABLE_RENAME=false
            echo -e "${YELLOW}Note: File organization/renaming is DISABLED${NC}"
            shift
            ;;
        --nosample)
            ENABLE_SAMPLE_REMOVAL=false
            echo -e "${YELLOW}Note: Sample file removal is DISABLED${NC}"
            shift
            ;;
        *)
            if [ -z "$SEARCH_DIR" ]; then
                SEARCH_DIR="$1"
            else
                echo -e "${RED}Error: Unknown argument '$1'${NC}"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Function to check if a newer version is available on GitHub
check_for_updates() {
    local current_version="$1"
    local github_repo="Gyurus/Vid-organ"
    local github_branch="main"
    local script_filename="Work/video/set_video.sh"
    local temp_remote_script="/tmp/set_video_remote.sh.$$"
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        echo -e "${BLUE}ℹ Version: $current_version (curl not available)${NC}"
        return 0
    fi
    
    local download_success=false
    
    # Try to download from GitHub raw content
    local github_raw_url="https://raw.githubusercontent.com/${github_repo}/${github_branch}/${script_filename}"
    
    if timeout 15 curl -L -f -s -m 12 \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
        --compressed \
        "$github_raw_url" \
        -o "$temp_remote_script" 2>/dev/null; then
        
        # Validate file size (should be non-empty bash script)
        if [ -s "$temp_remote_script" ] && head -1 "$temp_remote_script" 2>/dev/null | grep -q "^#!/bin/bash"; then
            download_success=true
        fi
    fi
    
    if [ "$download_success" = true ]; then
        # Extract version from remote script
        local remote_version=$(grep "^# Version:" "$temp_remote_script" 2>/dev/null | head -1 | sed 's/.*Version: //')
        
        if [ -n "$remote_version" ]; then
            # Compare versions using version comparison
            if [ "$remote_version" != "$current_version" ]; then
                # Simple version comparison: split by dots and compare numerically
                local remote_major=$(echo "$remote_version" | cut -d. -f1)
                local remote_minor=$(echo "$remote_version" | cut -d. -f2)
                local remote_patch=$(echo "$remote_version" | cut -d. -f3)
                
                local current_major=$(echo "$current_version" | cut -d. -f1)
                local current_minor=$(echo "$current_version" | cut -d. -f2)
                local current_patch=$(echo "$current_version" | cut -d. -f3)
                
                # Check if remote is newer
                local is_newer=false
                if [ "$remote_major" -gt "$current_major" ]; then
                    is_newer=true
                elif [ "$remote_major" -eq "$current_major" ] && [ "$remote_minor" -gt "$current_minor" ]; then
                    is_newer=true
                elif [ "$remote_major" -eq "$current_major" ] && [ "$remote_minor" -eq "$current_minor" ] && [ "$remote_patch" -gt "$current_patch" ]; then
                    is_newer=true
                fi
                
                if [ "$is_newer" = true ]; then
                    echo -e "${YELLOW}⚠ Update available! Remote: v$remote_version (current: v$current_version)${NC}"
                    echo -e "${BLUE}  GitHub: https://github.com/${github_repo}${NC}"
                else
                    echo -e "${GREEN}✓ Version is current (v${current_version})${NC}"
                fi
            else
                echo -e "${GREEN}✓ Version is current (v${current_version})${NC}"
            fi
        else
            echo -e "${BLUE}ℹ Version: $current_version (remote version info not found)${NC}"
        fi
    else
        # Download failed - provide helpful message
        echo -e "${BLUE}ℹ Version: $current_version (remote check unavailable)${NC}"
    fi
    
    # Cleanup
    rm -f "$temp_remote_script" 2>/dev/null
}

# Display version and startup message
SCRIPT_VERSION="0.6.2"
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  Video Audio Language Setter - v${SCRIPT_VERSION}${NC}${GREEN}         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo

# Check for updates on startup
check_for_updates "$SCRIPT_VERSION"
echo

# Load INI configuration at startup
echo -e "${BLUE}Loading configuration...${NC}"
if ! load_ini_config; then
    echo -e "${YELLOW}No $INI_CONFIG_FILE found, using defaults${NC}"
fi

# Apply INI settings to variables
ENABLE_SAMPLE_REMOVAL=$(get_ini_setting "enable_sample_removal")
ENABLE_RENAME=$(get_ini_setting "enable_rename")

# Apply removed folder name from INI
REMOVED_FOLDER=$(get_ini_setting "removed_folder_name")

# Get the movie folder BEFORE running main (show options immediately)
if [ -z "$SEARCH_DIR" ]; then
    # Try to use default folder from INI
    default_folder=$(get_ini_setting "default_folder")
    if [ -n "$default_folder" ] && [ -d "$default_folder" ]; then
        # Ask if user wants to use the saved default folder
        echo -e "${BLUE}Found saved default folder: $default_folder${NC}"
        use_default=$(get_user_choice "Use this folder?" "y" false)
        if [[ "$use_default" = "y" ]]; then
            SEARCH_DIR="$default_folder"
        else
            SEARCH_DIR=$(prompt_for_movie_folder)
        fi
    else
        SEARCH_DIR=$(prompt_for_movie_folder)
    fi
    echo
else
    # If directory was specified via command line, save it as default
    save_default_folder "$SEARCH_DIR"
fi

# Run main function with the selected folder
main "$SEARCH_DIR"