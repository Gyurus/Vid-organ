#!/bin/bash

# Simple Video Organizer and Language Setter
# Version: 1.0.1
# Interactive script to organize video files and set audio language metadata

# Color codes for output
RED=''
GREEN=''
YELLOW=''
BLUE=''
NC=''

# Configuration file
CONFIG_FILE="$(dirname "$0")/set_v.ini"

# Function to load settings from ini file
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file not found: $CONFIG_FILE"
        echo "Using default settings"
        return
    fi

    # Read settings from ini file
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # Remove whitespace
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        case "$key" in
            min_file_size_mb) MIN_FILE_SIZE_MB="$value" ;;
            default_player) DEFAULT_PLAYER="$value" ;;
            default_output_dir) DEFAULT_OUTPUT_DIR="$value" ;;
            video_extensions) VIDEO_EXTENSIONS="$value" ;;
            subtitle_extensions) SUBTITLE_EXTENSIONS="$value" ;;
            default_audio_language) DEFAULT_AUDIO_LANGUAGE="$value" ;;
        esac
    done < "$CONFIG_FILE"
}

# Load configuration
echo "Loading configuration..."
load_config
echo "Configuration loaded"

# Default settings (fallback if not in config)
MIN_FILE_SIZE_MB=${MIN_FILE_SIZE_MB:-600}
VIDEO_EXTENSIONS=${VIDEO_EXTENSIONS:-"avi|mkv|mp4|mov|wmv|flv|webm|m4v|mpg|mpeg|3gp|ogv|ts|m2ts|mts"}
SUBTITLE_EXTENSIONS=${SUBTITLE_EXTENSIONS:-"srt|sub|ass|ssa|vtt|smi"}
DEFAULT_PLAYER=${DEFAULT_PLAYER:-"smplayer"}
DEFAULT_OUTPUT_DIR=${DEFAULT_OUTPUT_DIR:-"Movies.org"}
DEFAULT_AUDIO_LANGUAGE=${DEFAULT_AUDIO_LANGUAGE:-"eng"}

# Function to get user choice
get_user_choice() {
    local prompt="$1"
    local default="$2"
    echo "$prompt" >&2
    read -r choice < /dev/tty
    echo "DEBUG: Raw choice read: '$choice'" >&2
    # Trim leading and trailing whitespace
    choice="${choice#"${choice%%[![:space:]]*}"}"
    choice="${choice%"${choice##*[![:space:]]}"}"
    echo "DEBUG: Trimmed choice: '$choice'" >&2
    if [ -z "$choice" ] && [ -n "$default" ]; then
        choice="$default"
    fi
    echo "DEBUG: Final choice: '$choice'" >&2
    echo "$choice"
}

# Function to get language choice from menu
get_language_choice() {
    local track_num="$1"
    while true; do
        echo "Select language for Track $track_num:" >&2
        echo "1. eng (English)" >&2
        echo "2. hun (Hungarian)" >&2
        echo "3. ger (German)" >&2
        echo "4. kor (Korean)" >&2
        echo "5. fre (French)" >&2
        echo "6. spa (Spanish)" >&2
        echo "7. ita (Italian)" >&2
        echo "8. por (Portuguese)" >&2
        echo "9. rus (Russian)" >&2
        echo "10. jpn (Japanese)" >&2
        echo >&2
        
        local choice
        choice=$(get_user_choice "Enter your choice (1-10)" "")
        
        case "$choice" in
            1) echo "eng"; return ;;
            2) echo "hun"; return ;;
            3) echo "ger"; return ;;
            4) echo "kor"; return ;;
            5) echo "fre"; return ;;
            6) echo "spa"; return ;;
            7) echo "ita"; return ;;
            8) echo "por"; return ;;
            9) echo "rus"; return ;;
            10) echo "jpn"; return ;;
            *) 
                echo "Invalid choice. Please enter 1-10." >&2
                ;;
        esac
    done
}

# Function to pick folder using GUI dialog
pick_folder() {
    local default_path="${1:-$HOME}"

    # Try zenity first (GNOME)
    if command -v zenity &> /dev/null; then
        zenity --file-selection --directory --title="Select Video Folder" --filename="$default_path" 2>/dev/null
        return $?
    fi

    # Try kdialog (KDE)
    if command -v kdialog &> /dev/null; then
        kdialog --getexistingdirectory "$default_path" 2>/dev/null
        return $?
    fi

    # Fallback to terminal input
    echo "GUI folder picker not available. Please enter path manually."
    echo -n "Enter video folder path: "
    read -r folder_path
    echo "$folder_path"
}

# Function to get output directory
get_output_directory() {
    local input_dir="$1"
    
    # Create output directory in the chosen directory
    local output_dir="${input_dir}/${DEFAULT_OUTPUT_DIR}"

    # Return the output directory path
    echo "$output_dir"
}

# Function to extract movie info from filename
extract_movie_info() {
    local filename="$1"
    local movie_name=""
    local year=""

    # Remove extension
    local base_name="${filename%.*}"
    
    # First, try to extract year before cleaning tags
    local extracted_year=""
    if [[ "$base_name" =~ [._-]([0-9]{4})[._-] ]] || [[ "$base_name" =~ [._-]([0-9]{4})$ ]]; then
        extracted_year="${BASH_REMATCH[1]}"
    elif [[ "$base_name" =~ \(([0-9]{4})\) ]]; then
        extracted_year="${BASH_REMATCH[1]}"
    fi

    # Remove common quality/format tags (case insensitive)
    base_name=$(echo "$base_name" | sed -E 's/[._-]*(BluRay|BRRip|BDRip|HDRip|WEBRip|WEB-DL|DVDRip|HDTV|SDTV)[._-]*//gi')
    base_name=$(echo "$base_name" | sed -E 's/[._-]*(1080p|720p|480p|2160p|4K|UHD)[._-]*//gi')
    base_name=$(echo "$base_name" | sed -E 's/[._-]*(x264|x265|h264|h265|HEVC|AVC)[._-]*//gi')
    base_name=$(echo "$base_name" | sed -E 's/[._-]*(AAC|AC3|DTS|DTS-HD|TrueHD|FLAC|MP3|Atmos)[._-]*//gi')
    base_name=$(echo "$base_name" | sed -E 's/[._-]*(5\.1|7\.1|2\.0)[._-]*//gi')
    base_name=$(echo "$base_name" | sed -E 's/[._-]*(EXTENDED|UNRATED|REMASTERED|DIRECTORS[._-]*CUT|DC)[._-]*//gi')
    base_name=$(echo "$base_name" | sed -E 's/[._-]*(PROPER|REPACK|INTERNAL|LIMITED)[._-]*//gi')
    base_name=$(echo "$base_name" | sed -E 's/[._-]*[A-Z0-9]{3,}[._-]*$//g')  # Remove group tags at the end
    
    # Remove empty or punctuation-only brackets like "()", "[]", "{}"
    base_name=$(echo "$base_name" | sed -E 's/\(([[:space:][:punct:]]*)\)//g; s/\[([[:space:][:punct:]]*)\]//g; s/\{([[:space:][:punct:]]*)\}//g')
    
    # Remove year from base name FIRST if found (so we can properly detect language codes)
    if [ -n "$extracted_year" ]; then
        base_name=$(echo "$base_name" | sed -E "s/[._-]*${extracted_year}[._-]*//g")
        year="$extracted_year"
    fi
    
    # Remove trailing runs of concatenated 3-letter language codes without separators (e.g., 'korkorkor', 'engengeng')
    # Supported codes: eng hun ger kor fre spa ita por rus jpn
    # This handles: _eng, engeng, engengeng, etc.
    while [[ "$base_name" =~ [._-]?(eng|hun|ger|kor|fre|spa|ita|por|rus|jpn)$ ]]; do
        base_name="${base_name%???}"  # Remove last 3 characters (the language code)
        base_name="${base_name%[._-]}"  # Remove separator if present before it
    done
    # Also remove trailing sequences like _eng_hun or -eng-hun at the end
    base_name=$(echo "$base_name" | sed -E 's/([._-](eng|hun|ger|kor|fre|spa|ita|por|rus|jpn))+[._-]*$//I')

    # Clean up movie name: replace dots/underscores with spaces, collapse multiple spaces
    movie_name=$(echo "$base_name" | sed 's/[._-]/ /g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
    
    # Final trim: remove any stray empty parentheses left after spacing
    movie_name=$(echo "$movie_name" | sed -E 's/\(([[:space:][:punct:]]*)\)//g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

    echo "${movie_name}|${year}"
}

    # URL-encode a string (RFC 3986-ish for our needs)
    url_encode() {
        local s="$1"
        local out=""
        local c
        local i
        LC_ALL=C
        for (( i=0; i<${#s}; i++ )); do
            c=${s:i:1}
            case "$c" in
                [a-zA-Z0-9.~_-]) out+="$c" ;;
                ' ') out+="%20" ;;
                *) printf -v hex '%%%02X' "'${c}'"; out+="$hex" ;;
            esac
        done
        echo "$out"
    }

    # Normalize strings for comparison (lowercase, alnum only, collapse spaces)
    normalize_string() {
        echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//'
    }

    # Verify title and year via OMDb (if OMDB_API_KEY set) or IMDb suggestion API
    verify_title_year_with_imdb() {
        local title="$1"
        local year="$2"

        # If no year, skip verification
        if [ -z "$year" ]; then
            return 0
        fi

        if ! command -v curl >/dev/null 2>&1; then
            echo "WARNING: curl not installed; skipping IMDb verification" >&2
            return 2
        fi

        # Prefer OMDb if API key is provided
        if [ -n "$OMDB_API_KEY" ]; then
            local url="https://www.omdbapi.com/?t=$(url_encode "$title")&y=$year&type=movie&apikey=$OMDB_API_KEY"
            local json
            json=$(curl -sL "$url")
            if echo "$json" | grep -q '"Response":"True"'; then
                local y
                y=$(echo "$json" | grep -o '"Year":"[0-9]\{4\}"' | head -1 | sed -E 's/.*"Year":"([0-9]{4})".*/\1/')
                local tt
                tt=$(echo "$json" | grep -o '"Title":"[^"]*"' | head -1 | sed -E 's/.*"Title":"([^"]*)".*/\1/')
                if [ "$y" = "$year" ]; then
                    return 0
                else
                    echo "WARNING: IMDb/OMDb year mismatch: got '$tt' ($y), expected '$title' ($year)" >&2
                    return 1
                fi
            else
                echo "WARNING: OMDb found no match for '$title' ($year)" >&2
                return 1
            fi
        fi

        # Fallback to IMDb suggestion API (unofficial)
        local encoded
        encoded=$(url_encode "$title")
        local first
        first=$(printf '%s' "$encoded" | cut -c1 | tr '[:upper:]' '[:lower:]')
        local imdb_url="https://v2.sg.media-imdb.com/suggestion/${first}/${encoded}.json"
        local json
        json=$(curl -sL "$imdb_url")
        if [ -z "$json" ]; then
            echo "WARNING: IMDb lookup failed for '$title' ($year)" >&2
            return 1
        fi
        # Extract top result title and year
        local tt
        tt=$(echo "$json" | grep -o '"l":"[^"]*"' | head -1 | sed -E 's/.*"l":"([^"]*)".*/\1/')
        local y
        y=$(echo "$json" | grep -o '"y":[0-9]\{4\}' | head -1 | sed -E 's/.*"y":([0-9]{4}).*/\1/')
        local nt1 nt2
        nt1=$(normalize_string "$title")
        nt2=$(normalize_string "$tt")
        if [ "$y" = "$year" ] && [ "$nt1" = "$nt2" ]; then
            return 0
        else
            echo "WARNING: IMDb top result '$tt' ($y) doesn't match '$title' ($year)" >&2
            return 1
        fi
    }

# Function to get audio languages from file (returns detailed track info)
get_audio_languages() {
    local file="$1"
    local result
    if result=$(ffprobe -v quiet -select_streams a -show_entries stream_tags=language -of csv=p=0 "$file" 2>/dev/null) && [ -n "$result" ]; then
        # ffprobe succeeded and returned languages, format as "language,value" per line
        result=$(echo "$result" | sed 's/^/language,/')
    else
        # ffprobe failed or returned empty, get stream count and create undefined entries
        local stream_count
        stream_count=$(ffprobe -v quiet -show_streams -select_streams a "$file" 2>/dev/null | grep -c "codec_type=audio" || echo "0")
        result=""
        for ((i=0; i<stream_count; i++)); do
            if [ -z "$result" ]; then
                result="language,und"
            else
                result="${result}"$'\n'"language,und"
            fi
        done
    fi
    echo -e "$result"
}

# Function to play video file
play_video() {
    local file="$1"
    local player="$2"

    echo "Playing video: $(basename "$file")"
    echo "Close video player to return to script..."

    # Save terminal settings
    local saved_stty
    saved_stty=$(stty -g 2>/dev/null || echo "")

    case "$player" in
        "smplayer")
            smplayer "$file" 2>/dev/null
            ;;
        "vlc")
            vlc "$file" 2>/dev/null
            ;;
        "mpv")
            mpv "$file" 2>/dev/null
            ;;
        *)
            echo "Player '$player' not supported, trying xdg-open"
            xdg-open "$file" 2>/dev/null
            ;;
    esac

    # Reset terminal to sane state
    tput reset 2>/dev/null || true
    sleep 0.5
    stty sane 2>/dev/null || true
}

# Function to set audio language for a specific track
set_audio_language() {
    local file="$1"
    local track_index="$2"   # 0-based audio stream index
    local language="$3"      # ISO-639-2 (eng, hun, ...)

    echo "Setting audio language for track $((track_index + 1)) to '${language}'..."

    # Normalize extension
    local ext
    ext=$(echo "${file##*.}" | tr '[:upper:]' '[:lower:]')

    # Prefer mkvpropedit for MKV
    if [[ "$ext" == "mkv" ]] && command -v mkvpropedit &> /dev/null; then
        if mkvpropedit "$file" --edit track:a$((track_index + 1)) --set language="$language" &>/dev/null; then
            echo "Language set successfully (mkvpropedit)"
            return 0
        else
            echo "mkvpropedit failed, will try ffmpeg..."
        fi
    fi

    # Containers that commonly support language tags via ffmpeg
    local use_movflags=false
    case "$ext" in
        mp4|m4v|mov)
            use_movflags=true
            ;;
        mkv|webm)
            # supported without movflags
            ;;
        avi|ts|m2ts|mts|mpg|mpeg)
            echo "WARNING: Container '.$ext' may not support audio language tags reliably. Attempting ffmpeg, but it may not persist." >&2
            ;;
        *)
            # Unknown container; attempt anyway
            ;;
    esac

    # Fallback to ffmpeg for (most) formats
    # Use a safe temp filename in the same directory
    local dir
    dir=$(dirname "$file")
    local base
    base=$(basename "$file")
    local temp_file="${dir}/.tmp_${RANDOM}_${base}"
    
    # Determine output format explicitly
    local format_opt=""
    case "$ext" in
        mp4|m4v) format_opt="-f mp4" ;;
        mov) format_opt="-f mov" ;;
        mkv) format_opt="-f matroska" ;;
        webm) format_opt="-f webm" ;;
        avi) format_opt="-f avi" ;;
        ts|m2ts|mts) format_opt="-f mpegts" ;;
        mpg|mpeg) format_opt="-f mpeg" ;;
    esac
    
    if [ "$use_movflags" = true ]; then
        if ffmpeg -hide_banner -loglevel error -y -i "$file" -map 0 -c copy $format_opt -movflags use_metadata_tags \
            -metadata:s:a:$track_index language="$language" "$temp_file"; then
            mv "$temp_file" "$file" 2>/dev/null
            echo "Language set successfully (ffmpeg)"
            return 0
        else
            echo "Failed to set language with ffmpeg (mp4/mov)." >&2
            rm -f "$temp_file"
            return 1
        fi
    else
        if ffmpeg -hide_banner -loglevel error -y -i "$file" -map 0 -c copy $format_opt \
            -metadata:s:a:$track_index language="$language" "$temp_file"; then
            mv "$temp_file" "$file" 2>/dev/null
            echo "Language set successfully (ffmpeg)"
            return 0
        else
            echo "Failed to set language with ffmpeg." >&2
            rm -f "$temp_file"
            return 1
        fi
    fi
}

# Function to find matching subtitle files
find_subtitle_files() {
    local source_dir="$1"
    local movie_title="$2"

    # Clean title for matching
    local clean_title
    clean_title=$(echo "$movie_title" | sed 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')

    # Find subtitle files recursively in source directory
    find "$source_dir" -type f \( -iname "*.srt" -o -iname "*.sub" -o -iname "*.ass" -o -iname "*.ssa" -o -iname "*.vtt" -o -iname "*.smi" \) -print0 2>/dev/null | while IFS= read -r -d '' file; do
        local filename
        filename=$(basename "$file")
        local base_name="${filename%.*}"
        local clean_base
        clean_base=$(echo "$base_name" | sed 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')

        # Check if subtitle filename contains the movie title
        if [[ "$clean_base" == *"$clean_title"* ]]; then
            echo "$file"
        fi
    done
}

# Function to clean language tags from before year in filename
# Fixes names like: Title_eng_2020.mkv -> Title.2020_eng.mkv
# and: Title_kor_hun_2019.mp4 -> Title.2019_kor_hun.mp4
clean_language_tags_before_year() {
    local filename="$1"
    local base_name="${filename%.*}"
    local extension="${filename##*.}"
    local langs_part
    
    # Pattern: Find the year (rightmost 4 digits after underscore)
    if [[ "$base_name" =~ ^(.+)_([0-9]{4})$ ]]; then
        local before_year="${BASH_REMATCH[1]}"
        local year="${BASH_REMATCH[2]}"
        
        # Now check if before_year ends with language codes
        # Pattern: check if it ends with (eng|hun|ger|kor|fre|spa|ita|por|rus|jpn)(_lang)*
        if [[ "$before_year" =~ _((eng|hun|ger|kor|fre|spa|ita|por|rus|jpn)(_[a-z]{3})*)$ ]]; then
            langs_part="${BASH_REMATCH[1]}"
            
            # Remove ALL trailing language codes from before_year to get clean title
            # Keep removing underscores + language codes from the end
            local title_part="$before_year"
            while [[ "$title_part" =~ _(eng|hun|ger|kor|fre|spa|ita|por|rus|jpn)$ ]]; do
                title_part="${title_part%_*}"
            done
            
            # Make sure title_part is not empty
            if [ -n "$title_part" ]; then
                echo "${title_part}.${year}_${langs_part}.${extension}"
                return 0
            fi
        fi
    fi
    
    # No language tags before year detected, return original
    echo "$filename"
}

# Function to generate unique filename if duplicate exists
get_unique_filepath() {
    local target_path="$1"
    local base_name="${target_path%.*}"
    local extension="${target_path##*.}"
    local counter=1
    local new_path="$target_path"
    
    # If file doesn't exist, return original path
    if [ ! -e "$target_path" ]; then
        echo "$target_path"
        return 0
    fi
    
    # File exists, generate unique name by appending _copy_N before extension
    # Safety limit to prevent infinite loops
    while [ -e "$new_path" ] && [ $counter -lt 10000 ]; do
        new_path="${base_name}_copy_${counter}.${extension}"
        ((counter++))
    done
    
    # If we hit the limit, use timestamp to ensure uniqueness
    if [ $counter -ge 10000 ]; then
        new_path="${base_name}_copy_$(date +%s).${extension}"
    fi
    
    echo "$new_path"
}

# Function to rename file with languages
rename_with_languages() {
    local file="$1"
    local languages="$2"

    local dir
    dir=$(dirname "$file")
    local filename
    filename=$(basename "$file")
    local extension="${filename##*.}"
    local base_name="${filename%.*}"

    # Check if filename already contains language metadata (ends with language codes)
    # Pattern: ends with _ followed by 3-letter language codes separated by underscores
    if [[ "$base_name" =~ _([a-z]{3}(_[a-z]{3})*)$ ]]; then
        # Filename already has language metadata, don't add more
        echo "$file"
        return
    fi

    # Create new filename
    local new_base_name="${base_name}_${languages}"
    local new_filename="${new_base_name}.${extension}"
    local new_path="${dir}/${new_filename}"

    if [ "$file" != "$new_path" ]; then
        mv "$file" "$new_path" 2>/dev/null
        echo "$new_path"
    else
        echo "$file"
    fi
}

# Function to get detailed video and audio information
get_video_details() {
    local file="$1"
    local info=""
    
    # Get video duration and resolution
    local duration=$(ffprobe -v error -select_streams v:0 -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | cut -d. -f1)
    local width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    local height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    local fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    local codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    
    # Get audio information
    local audio_tracks=$(ffprobe -v error -select_streams a -show_entries stream=codec_name,sample_rate,channels -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | wc -l)
    
    # Get file size
    local size_bytes=$(stat -c%s "$file" 2>/dev/null)
    local size_mb=$((size_bytes / 1024 / 1024))
    
    echo "Duration: ${duration}s | Resolution: ${width}x${height} | FPS: ${fps} | Codec: ${codec} | Audio tracks: ${audio_tracks} | Size: ${size_mb}MB"
}

# Function to handle multiple copies interactively
handle_duplicate_copies() {
    local base_path="$1"
    local base_name="${base_path%.*}"
    local extension="${base_path##*.}"
    
    # Find all copies (original + _copy_N versions)
    local copies=()
    if [ -e "$base_path" ]; then
        copies+=("$base_path")
    fi
    
    local counter=1
    while [ -e "${base_name}_copy_${counter}.${extension}" ]; do
        copies+=("${base_name}_copy_${counter}.${extension}")
        ((counter++))
    done
    
    # If no duplicates or only one file, return (nothing to ask)
    if [ ${#copies[@]} -le 1 ]; then
        return 0
    fi
    
    # Multiple copies found - show details and ask user
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠ MULTIPLE COPIES DETECTED: $(basename "$base_path")"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    # Display details for each copy
    for i in "${!copies[@]}"; do
        local idx=$((i + 1))
        local copy="${copies[$i]}"
        echo "[$idx] $(basename "$copy")"
        echo "     $(get_video_details "$copy")"
        echo
    done
    
    # Ask user which to keep
    echo "Which copies would you like to keep?" >&2
    echo "Enter numbers separated by commas (e.g.: 1,2,4 or 'all')" >&2
    echo "Or press Enter to keep all:" >&2
    read -r keep_choice < /dev/tty
    
    # Default to keeping all if empty
    if [ -z "$keep_choice" ]; then
        keep_choice="all"
    fi
    
    # Parse user choice
    local to_keep=()
    if [ "$keep_choice" = "all" ]; then
        # Keep all files, no deletion
        echo "Keeping all copies"
        return 0
    else
        # Parse comma-separated numbers
        IFS=',' read -ra choices <<< "$keep_choice"
        for choice in "${choices[@]}"; do
            choice=$(echo "$choice" | xargs)  # trim whitespace
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#copies[@]} ]; then
                to_keep+=($choice)
            fi
        done
    fi
    
    # Delete copies not selected
    for i in "${!copies[@]}"; do
        local idx=$((i + 1))
        local copy="${copies[$i]}"
        
        # Check if this index is in the keep list
        local should_keep=false
        for keep_idx in "${to_keep[@]}"; do
            if [ "$idx" = "$keep_idx" ]; then
                should_keep=true
                break
            fi
        done
        
        if [ "$should_keep" = false ]; then
            if rm "$copy" 2>/dev/null; then
                echo "  Deleted: $(basename "$copy")"
            else
                echo "  Failed to delete: $(basename "$copy")"
            fi
        else
            echo "  Keeping: $(basename "$copy")"
        fi
    done
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
}

# Function to check and install ffprobe/ffmpeg
check_and_install_ffprobe() {
    if command -v ffprobe &> /dev/null; then
        echo "FFprobe (ffmpeg) is already installed"
        return 0
    fi

    echo "FFprobe not found. Installing ffmpeg..."

    # Try to install ffmpeg
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        echo "Installing ffmpeg via apt-get..."
        sudo apt-get update && sudo apt-get install -y ffmpeg
    elif command -v dnf &> /dev/null; then
        # Fedora/RHEL
        echo "Installing ffmpeg via dnf..."
        sudo dnf install -y ffmpeg
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        echo "Installing ffmpeg via pacman..."
        sudo pacman -S --noconfirm ffmpeg
    elif command -v zypper &> /dev/null; then
        # openSUSE
        echo "Installing ffmpeg via zypper..."
        sudo zypper install -y ffmpeg
    else
        echo "Could not determine package manager. Please install ffmpeg manually."
        echo "FFmpeg is required for video metadata extraction. Install it and run the script again."
        exit 1
    fi

    # Verify installation
    if command -v ffprobe &> /dev/null; then
        echo "FFmpeg installed successfully"
    else
        echo "FFmpeg installation failed. Please install it manually."
        exit 1
    fi
}

# Function to check and install smplayer
check_and_install_smplayer() {
    if command -v smplayer &> /dev/null; then
        echo "SMPlayer is already installed"
        return 0
    fi

    echo "SMPlayer not found. Installing..."

    # Try to install smplayer
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        echo "Installing SMPlayer via apt-get..."
        sudo apt-get update && sudo apt-get install -y smplayer
    elif command -v dnf &> /dev/null; then
        # Fedora/RHEL
        echo "Installing SMPlayer via dnf..."
        sudo dnf install -y smplayer
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        echo "Installing SMPlayer via pacman..."
        sudo pacman -S --noconfirm smplayer
    elif command -v zypper &> /dev/null; then
        # openSUSE
        echo "Installing SMPlayer via zypper..."
        sudo zypper install -y smplayer
    else
        echo "Could not determine package manager. Please install SMPlayer manually."
        echo "SMPlayer is required for video playback. Install it and run the script again."
        exit 1
    fi

    # Verify installation
    if command -v smplayer &> /dev/null; then
        echo "SMPlayer installed successfully"
    else
        echo "SMPlayer installation failed. Please install it manually."
        exit 1
    fi
}

# Function to show progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    echo "Progress: [${bar}] ${current}/${total} (${percentage}%)"
}

# Function to calculate total size of files
calculate_total_size() {
    local total=0
    for file in "$@"; do
        local size
        size=$(stat -c%s "$file" 2>/dev/null || echo "0")
        total=$((total + size))
    done
    # Add 10% overhead
    total=$((total + total / 10))
    echo "$total"
}

# Main function
main() {
    echo "==============================="
    echo "Simple Video Organizer v1.0.0"
    echo "==============================="
    echo

    # Check and install FFprobe/ffmpeg if needed
    echo "Checking dependencies..."
    echo "Checking FFmpeg installation..."
    check_and_install_ffprobe
    echo "FFmpeg ready"

    echo "Checking SMPlayer installation..."
    check_and_install_smplayer
    echo "SMPlayer ready"
    echo "All dependencies satisfied"
    echo

    # Get video folder
    echo "SELECT SOURCE FOLDER"
    echo "Choose the folder containing your video files to organize"
    echo "The script will scan this folder and move all contents to a staging area"
    echo "Opening folder picker..."
    echo

    local video_folder="${1:-$(pick_folder)}"

    # If no argument provided and pick_folder fails, use a default for testing
    if [ -z "$video_folder" ] || [ ! -d "$video_folder" ]; then
        if [ -n "$1" ] && [ -d "$1" ]; then
            video_folder="$1"
        else
            echo "No valid folder selected. Exiting."
            exit 1
        fi
    fi

    echo "SOURCE FOLDER: $video_folder"
    echo "Press Enter to continue"
    read -r
    echo
    echo "Validating source folder..."

    # Check if source folder is writable
    if [ ! -w "$video_folder" ]; then
        echo "Source folder is not writable: $video_folder"
        echo "Check permissions and try again."
        exit 1
    fi
    echo "Source folder is writable"

    echo "Contents will be moved to: $video_folder/aA.removed"
    echo

    # Create aA.removed folder and move all contents there
    local removed_folder="${video_folder}/aA.removed"
    echo "Creating staging folder and moving contents..."

    if [ ! -d "$removed_folder" ]; then
        echo "Creating staging folder: aA.removed"
        if ! mkdir -p "$removed_folder" 2>/dev/null; then
            echo "Failed to create staging folder: $removed_folder"
            echo "Check permissions and available disk space."
            exit 1
        fi
        echo "Staging folder created"
    else
        echo "Using existing staging folder"
    fi

    echo "Moving contents to staging area..."
    # Move all files and directories (except aA.removed itself) to aA.removed
    local moved_count=0
    for item in "$video_folder"/* "$video_folder"/.[^.]*; do
        # Skip if item doesn't exist or is the removed folder itself
        [ -e "$item" ] || continue
        [[ "$item" == "$removed_folder" ]] && continue

        local item_name
        item_name=$(basename "$item")
        [[ "$item_name" == "." ]] || [[ "$item_name" == ".." ]] && continue

        echo "  Moving: $item_name"
        if mv "$item" "$removed_folder/" 2>/dev/null; then
            echo "  Moved: $item_name"
            ((moved_count++))
        else
            echo "  Failed to move: $item_name"
        fi
    done

    if [ "$moved_count" -gt 0 ]; then
        echo "Moved $moved_count items to aA.removed"
    else
        echo "No items to move (folder was already empty)"
    fi
    echo

    # Now search for video files in aA.removed
    local source_folder="$removed_folder"
    echo "Searching for video files > ${MIN_FILE_SIZE_MB}MB in aA.removed..."
    echo "Scanning directory recursively..."
    local video_files=()
    local file_count=0

    while IFS= read -r -d '' file; do
        local size_bytes
        size_bytes=$(stat -c%s "$file" 2>/dev/null || echo "0")
        local size_mb=$(( size_bytes / 1024 / 1024 ))
        if [ "$size_mb" -gt "$MIN_FILE_SIZE_MB" ]; then
            video_files+=("$file")
            ((file_count++))
            echo "  Found: $(basename "$file") (${size_mb}MB)"
        fi
    done < <(find "$source_folder" -type f \( -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.flv" -o -iname "*.webm" -o -iname "*.m4v" -o -iname "*.mpg" -o -iname "*.mpeg" -o -iname "*.3gp" -o -iname "*.ogv" -o -iname "*.ts" -o -iname "*.m2ts" -o -iname "*.mts" \) -print0 2>/dev/null)

    if [ "$file_count" -eq 0 ]; then
        echo "No video files > ${MIN_FILE_SIZE_MB}MB found in aA.removed."
        exit 0
    fi

    echo "Found $file_count video file(s) to organize"

    # Calculate total size needed
    echo "Calculating total space requirements..."
    local total_required_bytes
    total_required_bytes=$(calculate_total_size "${video_files[@]}")
    local total_required_mb=$(( total_required_bytes / 1024 / 1024 ))
    echo "Total space required: ${total_required_mb}MB (including 10% overhead)"
    echo

    # Get output directory (fixed to same drive and directory level)
    echo "Setting up output directory..."
    echo "Output will be created in the chosen directory"
    local output_dir
    output_dir=$(get_output_directory "$video_folder")
    echo "Output directory will be: $output_dir"
    echo

    echo "DESTINATION FOLDER: $output_dir"
    echo "Press Enter to continue"
    read -r
    echo

    # Now create the movies directory
    echo "Creating organized movies directory: $output_dir"
    if ! mkdir -p "$output_dir" 2>/dev/null; then
        echo "Failed to create movies directory: $output_dir"
        echo "Check permissions and available disk space."
        exit 1
    fi
    echo "Movies organization directory ready: $output_dir"
    echo "Starting video processing..."
    echo

    # Process each file
    local processed_count=0
    for file in "${video_files[@]}"; do
        ((processed_count++))
        echo "---------------------------------------"
        echo "Processing file $processed_count/$file_count: $(basename "$file")"
        show_progress "$processed_count" "$file_count"
        echo "---------------------------------------"

        # Extract movie info
        echo "Extracting movie information..."
        local filename
        filename=$(basename "$file")
        local movie_info
        movie_info=$(extract_movie_info "$filename")
        local movie_title
        movie_title=$(echo "$movie_info" | cut -d'|' -f1)
        local movie_year
        movie_year=$(echo "$movie_info" | cut -d'|' -f2)

        echo "Title: $movie_title"
        if [ -n "$movie_year" ]; then
            echo "Year: $movie_year"
        fi

        # Verify title and year against IMDb/OMDb (warning only)
        verify_title_year_with_imdb "$movie_title" "$movie_year" || true

        # Create subfolder name (sanitize for filesystem)
        local subfolder_name=""
        if [ -n "$movie_year" ]; then
            # Remove problematic characters from movie title for directory name
            local safe_title
            safe_title=$(echo "$movie_title" | sed 's/[<>:"/\\|?*]/_/g' | sed 's/_*$//' | sed 's/^_*//')
            subfolder_name="${safe_title}_${movie_year}"
        else
            local safe_title
            safe_title=$(echo "$movie_title" | sed 's/[<>:"/\\|?*]/_/g' | sed 's/_*$//' | sed 's/^_*//')
            subfolder_name="$safe_title"
        fi

        # Ensure subfolder name is not empty
        if [ -z "$subfolder_name" ]; then
            subfolder_name="Unknown_Movie_$(date +%s)"
            echo "Using fallback folder name: $subfolder_name"
        fi

        local subfolder_path="${output_dir}/${subfolder_name}"
        echo "Creating subfolder: $subfolder_name"

        # Create subfolder
        if ! mkdir -p "$subfolder_path" 2>/dev/null; then
            echo "Failed to create subfolder: $subfolder_path"
            echo "Check permissions and available disk space."
            continue
        fi
        echo "Subfolder created"

        # Move video file to subfolder
        echo "Moving video file..."
        local new_video_path
        local target_path="${subfolder_path}/$(basename "$file")"
        new_video_path=$(get_unique_filepath "$target_path")
        
        if [ "$new_video_path" != "$target_path" ]; then
            echo "Duplicate detected: will save as $(basename "$new_video_path")"
        fi
        
        if mv "$file" "$new_video_path" 2>/dev/null; then
            echo "Moved video file to: $(basename "$new_video_path")"
            file="$new_video_path"
        else
            echo "Failed to move video file"
            echo "Check permissions and available disk space."
            continue
        fi

        # Find and move subtitle files (with duplicate handling)
        echo "Searching for subtitle files..."
        local subtitle_count=0
        while IFS= read -r subtitle_file; do
            if [ -z "$subtitle_file" ]; then
                continue
            fi
            if [ $subtitle_count -eq 0 ]; then
                echo "Found subtitle files:"
            fi
            local subtitle_name
            subtitle_name=$(basename "$subtitle_file")
            echo "  Moving subtitle: $subtitle_name"
            
            # Check for duplicate subtitles
            local target_sub_path="${subfolder_path}/${subtitle_name}"
            local new_subtitle_path=$(get_unique_filepath "$target_sub_path")
            
            if [ "$new_subtitle_path" != "$target_sub_path" ]; then
                echo "    Duplicate subtitle detected: saving as $(basename "$new_subtitle_path")"
            fi
            
            if mv "$subtitle_file" "$new_subtitle_path" 2>/dev/null; then
                echo "  Moved: $(basename "$new_subtitle_path")"
                ((subtitle_count++))
            else
                echo "  Failed to move: $subtitle_name"
            fi
        done < <(find_subtitle_files "$source_folder" "$movie_title")

        if [ "$subtitle_count" -eq 0 ]; then
            echo "No subtitle files found"
        else
            echo "Moved $subtitle_count subtitle file(s)"
        fi

        # Get audio languages (detailed track info)
        echo "Analyzing audio tracks..."
        local audio_track_info
        audio_track_info=$(get_audio_languages "$file")
        local track_languages=()
        local track_count=0

        # Parse audio track information
        while IFS=',' read -r tag language; do
            if [[ "$tag" == "language" ]]; then
                ((track_count++))
                local track_lang="${language:-und}"
                # Remove any trailing newlines or carriage returns
                track_lang=$(echo "$track_lang" | tr -d '\n\r' | xargs)
                track_languages+=("$track_lang")
            fi
        done <<< "$audio_track_info"

        # Display current audio track information
        if [ "$track_count" -eq 0 ]; then
            echo "No audio tracks detected"
            # Try alternative detection
            echo "Trying alternative audio detection..."
            local alt_info
            alt_info=$(ffprobe -v quiet -show_streams -select_streams a "$file" 2>/dev/null | grep -c "codec_type=audio" || echo "0")
            if [ "$alt_info" -gt 0 ]; then
                echo "Found $alt_info audio stream(s) via alternative method"
                track_count=$alt_info
                for ((i=0; i<track_count; i++)); do
                    track_languages+=("und")
                done
            fi
        fi

        echo "Audio tracks: $track_count"
        local has_undefined=false
        for i in "${!track_languages[@]}"; do
            local track_num=$((i + 1))
            local lang="${track_languages[$i]}"

            if [[ "$lang" == "und" ]] || [ -z "$lang" ]; then
                echo "  Track $track_num: $lang (undefined)"
                has_undefined=true
            else
                echo "  Track $track_num: $lang"
            fi
        done

        # Only prompt for language selection if there are undefined tracks
        if [ "$has_undefined" = false ]; then
            echo "All audio tracks have defined languages. Skipping language selection."
        else
            # Handle language selection for tracks with undefined languages
            echo "Playing video to identify or verify languages for undefined tracks..."
            play_video "$file" "$DEFAULT_PLAYER"

            echo
            echo "Video player closed. Please select language codes for tracks:" >&2

            # Prompt only for tracks with undefined languages
            for i in "${!track_languages[@]}"; do
                local track_num=$((i + 1))
                local current_lang="${track_languages[$i]}"
                
                # Skip tracks that already have defined languages
                if [[ "$current_lang" != "und" ]] && [ -n "$current_lang" ]; then
                    echo "Track $track_num: $current_lang (already defined, skipping)" >&2
                    continue
                fi
                
                local lang_display="undefined"
                
                echo "Track $track_num currently set to: $lang_display" >&2
                local language_code
                language_code=$(get_language_choice "$track_num")

                # Set the audio language for this specific track
                set_audio_language "$file" "$i" "$language_code"
                
                # Verify the language was set correctly
                local verified_lang
                verified_lang=$(ffprobe -v quiet -select_streams a:$i -show_entries stream_tags=language -of csv=p=0 "$file" 2>/dev/null | tr -d '\n\r' | xargs)
                if [[ "$verified_lang" == "$language_code" ]]; then
                    echo "✓ Track $track_num language verified: $language_code"
                    track_languages[$i]="$language_code"
                else
                    echo "⚠ Warning: Track $track_num verification failed (expected: $language_code, got: $verified_lang)"
                    track_languages[$i]="$language_code"
                fi
            done
        fi

        # Prepare language string for renaming
        local language_string=""
        if [ "$track_count" -gt 1 ]; then
            # Multiple tracks: create track1lang_track2lang format
            for i in "${!track_languages[@]}"; do
                local track_num=$((i + 1))
                local lang="${track_languages[$i]}"
                if [ -n "$language_string" ]; then
                    language_string="${language_string}_${lang}"
                else
                    language_string="$lang"
                fi
            done
        else
            # Single track: use simple language
            language_string="${track_languages[0]}"
        fi

        # Final verification summary
        echo "Final audio track configuration:"
        for i in "${!track_languages[@]}"; do
            local track_num=$((i + 1))
            echo "  Track $track_num: ${track_languages[$i]}"
        done

        # Rename file with languages if languages were detected
        if [ -n "$language_string" ]; then
            echo "Creating clean filename..."
            local current_name
            current_name=$(basename "$file")
            
            # Build the desired final filename (combining all fixes in one pass)
            # 1. Check if language tags appear BEFORE the year and fix them
            local cleaned_name
            cleaned_name=$(clean_language_tags_before_year "$current_name")
            
            local current_ext="${cleaned_name##*.}"
            local extension="$current_ext"
            
            # 2. Desired base (without extension)
            local desired_base
            if [ -n "$movie_year" ]; then
                desired_base="${movie_title}.${movie_year}"
            else
                desired_base="${movie_title}"
            fi

            # 3. Build desired final filename
            local desired_name="${desired_base}_${language_string}.${extension}"

            # 4. Sanitize desired name
            desired_name=$(echo "$desired_name" | sed 's/[<>:"/\\|?*]/_/g')

            # 5. Check if already in desired format to avoid unnecessary move
            local current_base="${cleaned_name%.*}"
            if [[ "$current_base" == "${desired_base}_${language_string}" ]]; then
                # Already correct, but may need to apply language tag fix if cleaned_name differs
                if [ "$cleaned_name" != "$current_name" ]; then
                    echo "Fixing language tag placement: $current_name -> $cleaned_name"
                    local new_file_path="${subfolder_path}/${cleaned_name}"
                    if mv "$file" "$new_file_path" 2>/dev/null; then
                        file="$new_file_path"
                        echo "✓ Language tags relocated"
                    else
                        echo "Warning: Could not relocate language tags"
                    fi
                else
                    echo "Filename already in desired format: $current_name"
                fi
            else
                # Need to rename: apply all fixes in single move
                echo "Applying filename fixes..."
                local new_file_path="${subfolder_path}/${desired_name}"
                if mv "$file" "$new_file_path" 2>/dev/null; then
                    echo "Renamed to: $desired_name"
                    file="$new_file_path"
                else
                    echo "Failed to rename file"
                fi
            fi
        fi

        echo "Processing complete for: $(basename "$file")"
        echo "Progress: $processed_count/$file_count files processed"
        echo
    done

    # Summary
    echo "==============================="
    echo "ORGANIZATION COMPLETE!"
    echo "==============================="
    echo "Summary:"
    echo "  Processed: $processed_count video file(s)"
    echo "  Organized in: $output_dir"
    echo "  Original files: $removed_folder"
    echo "  Space saved: ~${total_required_mb}MB organized"
    echo
    echo "Your video library is now perfectly organized!"
    echo "Tip: Check $output_dir for your organized movies"
}

# Call main function with arguments
main "$@"