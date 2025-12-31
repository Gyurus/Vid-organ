# Video Organizer - AI Coding Agent Instructions

## Project Overview

This is a bash-based video library organizer that automates video file organization, audio language metadata management, and intelligent file renaming. The project consists of:

- **Main script:** [set_v.sh](set_v.sh) - Interactive video organizer (1588 lines)
- **Online installer:** [vid.online.sh](vid.online.sh) - Downloads and installs script from GitHub
- **GUI helpers:** [folder-picker.sh](folder-picker.sh) - Cross-platform folder picker
- **Test utilities:** [test_menu.sh](test_menu.sh) - Menu system testing
- **Configuration:** [set_v.ini](set_v.ini) - INI-based settings

## Architecture & Data Flow

### Core Workflow (Main Script)
1. **Dependencies check** → Auto-install ffmpeg/ffprobe and video player (smplayer/vlc/mpv)
2. **Folder selection** → GUI picker (zenity/kdialog/yad) or CLI fallback
3. **Staging** → Move all files to `aA.removed/` subdirectory
4. **Video detection** → Recursive scan for videos > configured size threshold (default 600MB)
5. **Processing pipeline** per video:
   - Extract title/year via regex patterns (remove quality tags, release groups)
   - Verify against IMDb suggestion API (optional, warning-only)
   - Detect audio tracks via `ffprobe`
   - Interactive language selection if undefined (`und`)
   - Update metadata with `mkvpropedit` (MKV) or `ffmpeg` (other formats)
   - Create organized folder: `Title_Year/`
   - Rename file: `Title_Year_lang1_lang2.ext`
   - Move subtitles (matching by normalized title)

## Key Conventions

### Naming Patterns
- **Folders:** `Movie_Name_2024/` (underscores, not dots)
- **Files:** `Movie_Name_2024_eng_hun.mkv` (language codes appended)
- **Language codes:** ISO 639-2 3-letter (eng, hun, ger, kor, fre, spa, ita, por, rus, jpn)
- **Year extraction:** Regex patterns match `[._-]YYYY[._-]`, `(YYYY)`, or trailing `YYYY`

### Language Tag Positioning
Files with language codes BEFORE year (e.g., `Title_eng_2020.mkv`) get fixed to `Title.2020_eng.mkv`. See `clean_language_tags_before_year()` function.

### Metadata Handling
- **MKV files:** Prefer `mkvpropedit` (in-place, fast) over `ffmpeg` remuxing
- **MP4/MOV:** Use `ffmpeg -movflags use_metadata_tags` for language persistence
- **Track indexing:** 0-based internally, 1-based for user display
- **Undefined tracks:** Auto-play video via configured player, then prompt user

## Configuration System

[set_v.ini](set_v.ini) uses simple `key=value` parsing (see `load_config()` function):

```ini
min_file_size_mb=600        # Filter threshold for video detection
video_extensions=avi|mkv|mp4|...  # Pipe-separated patterns
default_player=smplayer     # smplayer|vlc|mpv
enable_auto_update=true     # GitHub-based version check
github_raw_url=https://raw.githubusercontent.com/Gyurus/Vid-organ/main/Work/video
```

Config is loaded at startup; missing values use hardcoded defaults in script.

## External Dependencies

### Required
- `ffmpeg` + `ffprobe` - Audio metadata detection/modification (auto-installed via package manager)
- Video player: `smplayer` (preferred), `vlc`, `mpv`, or `mplayer`
- `bash` 4.0+

### Optional
- `mkvpropedit` - Faster MKV metadata editing (falls back to ffmpeg)
- `curl` - Auto-update and IMDb verification
- GUI dialogs: `zenity` (GNOME), `kdialog` (KDE), `yad`, or `Xdialog`

### Package Manager Support
Auto-install functions detect: `apt-get`, `dnf`, `pacman`, `zypper`

## Important Functions

### File Processing
- `extract_movie_info()` - Aggressive regex cleanup of release tags, quality markers, language codes
- `get_audio_languages()` - Returns CSV format: `language,<code>` per track
- `set_audio_language()` - Container-specific metadata modification
- `rename_with_languages()` - Append language codes only if not already present

### User Interaction
- `get_language_choice()` - Menu-based selection (1-10 presets + manual input)
- `pick_folder()` - Try GUI pickers in order, fallback to CLI
- `play_video()` - Launch player, restore terminal state on exit
- `handle_duplicate_copies()` - Interactive deduplication with video details

### Validation
- `verify_title_year_with_imdb()` - Uses IMDb suggestion API or OMDb (if `$OMDB_API_KEY` set)
- `normalize_string()` - Lowercase + strip non-alphanumeric for fuzzy matching
- `url_encode()` - RFC 3986-compliant encoding for API requests

## Auto-Update Mechanism

When `enable_auto_update=true`:
1. `check_for_updates()` fetches latest version from GitHub RAW URL
2. Compares `SCRIPT_VERSION` string
3. Downloads to `.${script_name}.tmp`, creates `.bak`, swaps atomically
4. Requires script restart to activate

## Development Workflow

### Testing
- Use [test_menu.sh](test_menu.sh) to validate menu interactions without full pipeline
- Run with small test directory to avoid long processing times
- Check `aA.removed/` staging folder for file moves before final organization

### Debugging
- All `ffmpeg`/`ffprobe` commands use `-v quiet` or `-loglevel error` to reduce noise
- Terminal state restoration with `tput reset` and `stty sane` after video playback
- Progress indicators: `show_progress()` uses Unicode block characters

### Common Pitfalls
- **Language codes duplicated:** Script checks existing `_lang1_lang2` suffix before appending
- **Terminal input blocked:** All user prompts use `< /dev/tty` for reads, `>&2` for output
- **Path safety:** Use `get_unique_filepath()` for collision avoidance (adds `_copy_N`)
- **Container limitations:** AVI/TS/MPEG may not persist language tags reliably (warning issued)

## File Organization Strategy

Source folder → Everything moved to `aA.removed/` → Process videos → Output to `Movies.org/`

This preserves originals in staging while creating clean organized structure. The `aA.` prefix ensures removed folder sorts first in directory listings.

## GitHub Integration

- **Repository:** `Gyurus/Vid-organ`
- **Branch:** `main`
- **Path:** `Work/video/`
- **Installer:** [vid.online.sh](vid.online.sh) downloads to `~/.local/bin/` with config in `~/.config/video-organizer/`
