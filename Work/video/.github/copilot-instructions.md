# Video Organizer - AI Coding Agent Instructions

## Project Overview
Bash-based video library organizer that automates file organization, audio language metadata management, and intelligent renaming. Core script: `set_v.sh` (1565 lines) with supporting helpers.

## Architecture & Data Flow
**Main Workflow** (`set_v.sh` main function):
1. Dependencies check → Auto-install ffmpeg/ffprobe, video players (smplayer/vlc/mpv)
2. Folder selection → GUI picker (zenity/kdialog/yad) or CLI fallback (`pick_folder()`)
3. Staging → Move all files to `aA.removed/` subdirectory
4. Video detection → Recursive scan for videos >600MB threshold
5. Processing pipeline per video:
   - Extract title/year via regex (`extract_movie_info()`)
   - Optional IMDb verification (`verify_title_year_with_imdb()`)
   - Detect audio tracks (`get_audio_languages()` via ffprobe)
   - Interactive language selection if undefined
   - Update metadata (`set_audio_language()`: mkvpropedit preferred, ffmpeg fallback)
   - Create `Title_Year/` folder
   - Rename: `Title_Year_lang1_lang2.ext` (`rename_with_languages()`)
   - Move subtitles matching normalized title

## Key Conventions
- **Folders**: `Movie_Name_2024/` (underscores, not dots)
- **Files**: `Movie_Name_2024_eng_hun.mkv` (ISO 639-2 codes: eng, hun, ger, kor, fre, spa, ita, por, rus, jpn)
- **Year extraction**: Regex patterns match `[._-]YYYY[._-]`, `(YYYY)`, trailing `YYYY`
- **Language positioning**: Fix `_lang_YYYY` to `_YYYY_lang` (`clean_language_tags_before_year()`)
- **Staging**: `aA.removed/` preserves originals, sorts first in listings

## Configuration System
INI-based settings in `set_v.ini`:
```ini
min_file_size_mb=600
default_player=smplayer
video_extensions=avi|mkv|mp4|...
enable_auto_update=true
github_raw_url=https://raw.githubusercontent.com/Gyurus/Vid-organ/main/Work/video
```

Loaded at startup (`load_config()`); missing values use defaults.

## External Dependencies & Integration
- **Required**: ffmpeg/ffprobe, video player (smplayer preferred)
- **Optional**: mkvpropedit (faster MKV edits), curl (IMDb verification, auto-update)
- **GUI dialogs**: zenity (GNOME), kdialog (KDE), yad, Xdialog
- **Auto-update**: Downloads from GitHub RAW URL, atomic swap with backup
- **IMDb verification**: OMDb API (if `$OMDB_API_KEY` set) or unofficial suggestion API

## Critical Patterns & Examples
- **Title extraction** (`extract_movie_info()`): Aggressive regex cleanup of quality tags (BluRay, 1080p, x264), release groups, language codes before year detection
- **Metadata handling**: MKV prefers `mkvpropedit` (in-place), MP4 uses `ffmpeg -movflags use_metadata_tags`
- **Language detection**: `ffprobe -select_streams a -show_entries stream_tags=language` returns CSV; undefined tracks default to "und"
- **User interaction**: All prompts use `< /dev/tty` for input, `>&2` for output; video playback restores terminal state (`tput reset`, `stty sane`)
- **Path safety**: `get_unique_filepath()` adds `_copy_N` for collisions
- **Normalization**: `normalize_string()` for fuzzy matching (lowercase, alphanumeric only)

## Development Workflow
- **Testing**: Use `test_menu.sh` for menu validation without full pipeline
- **Debugging**: ffmpeg commands use `-v quiet` or `-loglevel error`; progress via Unicode blocks
- **Installer**: `vid.online.sh` downloads to `~/.local/bin/`, config to `~/.config/video-organizer/`
- **Common pitfalls**: Language codes duplicated (check existing suffix), terminal blocked (tty redirection), container limitations (AVI/TS may not persist tags)

## File Organization Strategy
Source folder → `aA.removed/` staging → Process videos → Output to `Movies.org/` (configurable via `default_output_dir`)

This preserves originals while creating clean organized structure.
