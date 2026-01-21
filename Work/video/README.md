# Video Audio Language Setter

A comprehensive bash script for organizing and managing video files with automatic audio language metadata handling.

## Features

- 🎬 **Audio Language Management** - Set/verify audio language metadata in video files
- 📁 **Auto-Organization** - Organize videos into `Title.Year` folder structure with intelligent naming
- � **TV Series Support** - Automatic detection and organization of TV series with SxxExx pattern
- 🗑️ **Smart Cleanup** - Remove sample files and move old directories to `Aa.removed` folder
- ⚙️ **Configuration** - INI file for easy customization (configurable thresholds, settings)
- 🔄 **Auto-Update** - Automatic GitHub-based update detection with true auto-download
- 🎨 **Modern UI** - 256-color palette with visual feedback and clear status indicators
- 🛡️ **Safety Features** - Protects script and INI file from accidental deletion
- 🌐 **API Verification** - Verify movie titles and years using multiple online databases
- 📝 **Smart Subtitle Detection** - Recursively finds and moves subtitles from all subfolders

## API Verification

The script uses multiple movie database APIs for title and year verification:

### Primary API: TMDB (The Movie Database)
- **Recommended** - Most comprehensive movie data
- **Free API key** required from [TMDB](https://www.themoviedb.org/settings/api)
- Best reliability and data quality

### Secondary API: OMDb (Open Movie Database)
- **Optional** - Good basic movie information
- **Free API key** required from [OMDb](https://www.omdbapi.com/apikey.aspx)
- Used as fallback when TMDB is unavailable

### Last Resort: IMDb Suggestion API
- **Unofficial** - No API key required
- Less reliable than official APIs
- Used only when other APIs fail

### Configuration
```ini
# Master setting - enable/disable all online verification (default: false)
enable_online_verification=false

# TMDB API (recommended primary) - only used if enable_online_verification=true
tmdb_api_key=your_tmdb_key_here
enable_tmdb_verification=true

# OMDb API (optional secondary) - only used if enable_online_verification=true
omdb_api_key=your_omdb_key_here

# IMDb fallback - only used if enable_online_verification=true
enable_imdb_verification=true
```

## Features Details

### Naming Convention
**Movies:**
- **Folders:** `Movie_Name.2024`
- **Single Audio:** `Movie_Name_2024_eng.mkv`
- **Multiple Audio:** `Movie_Name_2024_eng_hun_rus.mkv`

**TV Series:**
- **Folders:** `Serials.org/Series Name/Season 01/`
- **Files:** `Series.Name.S01E05.Episode.Title.mkv`
- **With Language:** `Series.Name.S01E05.Episode.Title.eng.mkv`

### TV Series Detection
- Automatically detects SxxExx pattern (e.g., S01E05, s02e10)
- Organizes into: `Serials.org/Series Name/Season XX/`
- Preserves episode titles from filename
- Handles subtitles for series episodes

### Smart Organization
- Auto-plays video if language metadata is missing
- Detects undefined (und) audio tracks and prompts for language
- Handles files with multiple audio tracks automatically
- Moves old directories to removed folder after reorganization
- Recursively searches for subtitles in all subfolders (Subs, Sub, etc.)

### Configuration
All settings are stored in `set_audio.ini` with auto-update for missing settings:
- `enable_sample_removal` - Remove small video files
- `enable_rename` - Organize files into folders
- `enable_update_check` - Auto-download updates
- `default_audio_language` - Default language code (e.g., hun, eng)
- `small_video_file_size_mb` - Threshold for sample detection (default: 400)
- `large_file_size_gb` - Threshold for large files (default: 1)
- `removed_folder_name` - Name of cleanup folder (default: Aa.removed)

### Auto-Update
- First run: Choose 'a' to enable auto-update (saves to INI)
- Subsequent runs: Updates download silently on startup if available
- Manual mode: Choose 'y/n/e' for one-time update decisions

## Installation

```bash
git clone https://github.com/Gyurus/Vid-organ.git
cd Vid-organ/Work/video
chmod +x set_video.sh
```

## Usage

```bash
# Interactive mode (will prompt for folder)
./set_video.sh

# Specify folder directly
./set_video.sh /path/to/videos

# Skip file organization
./set_video.sh --norename /path/to/videos

# Skip sample file removal
./set_video.sh --nosample /path/to/videos

# Help
./set_video.sh --help
```

## Requirements

- `bash` 4.0+
- `ffmpeg` & `ffprobe` - For audio metadata detection
- `curl` - For update checking and auto-download
- Video player: `smplayer`, `mpv`, `vlc`, or `mplayer`
- `mkvpropedit` (optional) - For faster MKV metadata editing

## Configuration Example

Settings are automatically created/updated in `set_audio.ini`:

```ini
ini_version=0.6.9
enable_sample_removal=true
enable_rename=true
enable_update_check=false
default_audio_language=hun
small_video_file_size_mb=400
large_file_size_gb=1
removed_folder_name=Aa.removed
default_folder=/path/to/movies
```

## Example Workflow

```
Input:  Movie.2025.1080p.mkv (language: und/undefined)
        Subfolder: Movie.2025.1080p/

↓ Auto-plays video

↓ User enters language: hun

↓ Processes audio metadata

Output: Movie.2025/ (new organized folder)
        Movie_2025_hun.mkv (renamed with language)
        Old folder moved to: Aa.removed/Movie.2025.1080p/
```

## Color Scheme

The script uses modern 256-color ANSI palette for better visual clarity:
- 🔴 **Red (196)** - Errors and warnings
- 🟢 **Green (46)** - Success and completed actions
- 🟡 **Yellow (226)** - Information and caution
- 🔵 **Cyan (51)** - Highlights and prompts
- 🟣 **Purple (135)** - Decorative elements
- ⚪ **Gray (243)** - Secondary information

## Version

**Current:** v1.5.2

Updates are checked automatically from GitHub on startup (can be disabled in INI).

## Recent Changes

### v1.5.2
- Fixed config file location to use XDG config directory (~/.config/video-organizer/)
- Improved installer to automatically add ~/.local/bin to PATH
- Enhanced config file security (permissions set to 600)
- Updated AI coding agent instructions for better guidance

### v1.5.1
- Code cleanup and optimization (reduced from 1588 to 1564 lines)
- Fixed indentation inconsistencies in helper functions
- Removed unused variables and redundant code
- Consolidated string processing operations
- Improved readability and maintainability

### v0.6.9
- True auto-update implementation (automatically downloads when enabled)
- Underscore separators in filenames for better compatibility
- Modern 256-color UI scheme
- Always move old directories to removed folder after reorganization

### v0.6.8
- Modernized naming convention (Title.Year format)
- Simplified directory cleanup logic

### v0.6.7
- Auto-play video on missing metadata
- INI version failsafe with dynamic versioning
- Safety checks for script/INI protection
- Audio stream detection

## License

MIT

## Author

Gyurus - https://github.com/Gyurus
