# Interactive Movie Title Verification

## Overview

This enhancement adds interactive verification of extracted movie titles and years using **both TMDb and IMDb APIs**. When the script extracts a movie title from a filename, it now:

1. Queries both TMDb and IMDb for matching titles
2. Shows the user suggestions from both databases
3. Allows the user to select the correct match or enter manually
4. Uses the verified title/year for organizing the movie

## New Features

### 1. TMDb API Integration

- **Function**: `search_tmdb(title, year)`
- Queries The Movie Database (TMDb) API for movie matches
- Returns top 5 results with titles and years
- Requires free API key from https://www.themoviedb.org/settings/api

### 2. Interactive Selection Menu

- **Function**: `prompt_user_for_title_selection(extracted_title, extracted_year, imdb_results, tmdb_results)`
- Displays combined results from both IMDb and TMDb
- Numbered selection menu with:
  - `[1-N]` - Select from database matches
  - `[0]` - Use extracted values as-is
  - `[m]` - Manual entry mode
- Shows source (IMDb/TMDb) for each option

### 3. Enhanced Configuration

New settings in `set_v.ini`:

```ini
# TMDb API Configuration
tmdb_api_key=
enable_tmdb_verification=true
enable_imdb_verification=true
```

## Usage

### Getting a TMDb API Key

1. Create free account at https://www.themoviedb.org
2. Go to Settings → API
3. Request API key (choose "Developer" option)
4. Copy the API Key (v3 auth)
5. Add to `set_v.ini`: `tmdb_api_key=your_key_here`

### Interactive Verification Workflow

When processing a video file, the script will:

```
Processing file: The_Matrix_1999_BluRay.mkv

Extracting movie information...
Title: The Matrix
Year: 1999

Verifying title and year with online databases...
Checking IMDb...
Checking TMDb...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠  TITLE VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Extracted: The Matrix (1999)

From IMDb:
  [1] The Matrix (1999)
  [2] The Matrix Reloaded (2003)
  [3] The Matrix Resurrections (2021)

From TMDb:
  [4] The Matrix (1999)
  [5] The Matrix Revolutions (2003)

  [0] Use extracted values: The Matrix (1999)
  [m] Enter title/year manually

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Select correct match (0-5 or 'm' for manual): 1

✓ Selected from imdb: The Matrix (1999)

Using verified title: The Matrix (1999)
```

### Manual Entry Mode

If none of the suggestions match or you want custom values:

```
Select correct match (0-5 or 'm' for manual): m

Enter movie details manually:
Title: [The Matrix]
Year: [1999]
```

### Disable Verification

To disable verification (use extracted values only):

```ini
enable_tmdb_verification=false
enable_imdb_verification=false
```

Or disable individually:

```ini
# Only use IMDb
enable_tmdb_verification=false
enable_imdb_verification=true
```

## Technical Details

### API Endpoints

**TMDb API v3**
- Endpoint: `https://api.themoviedb.org/3/search/movie`
- Parameters: `api_key`, `query` (title), `year` (optional)
- Returns: JSON with movie results including title and release_date

**IMDb Suggestion API** (unofficial)
- Endpoint: `https://v2.sg.media-imdb.com/suggestion/{first_letter}/{title}.json`
- Returns: JSON with suggestions including title (`l`) and year (`y`)

### Error Handling

- Gracefully handles missing API keys (skips that source)
- Network failures don't block processing (falls back to extracted values)
- Invalid selections prompt user again
- No dependencies on external JSON parsers (uses grep/sed)

### Function Flow

```
main()
  ↓
extract_movie_info()
  ↓
[New] Interactive Verification:
  ├→ check_imdb_match() → Get IMDb suggestions
  ├→ search_tmdb() → Get TMDb suggestions
  ↓
  └→ prompt_user_for_title_selection()
     ├→ Display combined results
     ├→ User selects match
     └→ Return verified title/year
  ↓
Use verified values for folder name
```

## Examples

### Example 1: Correct Match Found

```
Filename: Inception.2010.1080p.BluRay.x264.mkv
Extracted: Inception (2010)

✓ IMDb Match Found:
  Title: Inception
  Year: 2010

✓ Title/year verified successfully
```

### Example 2: Multiple Close Matches

```
Filename: Avatar_2009_extended.mkv
Extracted: Avatar (2009)

⚠  TITLE VERIFICATION
Extracted: Avatar (2009)

From IMDb:
  [1] Avatar (2009)
  [2] Avatar: The Way of Water (2022)
  [3] The Last Airbender (2010)

From TMDb:
  [4] Avatar (2009)
  [5] Avatar: The Last Airbender (2024)

Select correct match (0-5 or 'm' for manual): 1
```

### Example 3: No Year in Filename

```
Filename: Interstellar.BluRay.mkv
Extracted: Interstellar (no year)

⚠  TITLE VERIFICATION
Extracted: Interstellar (no year)

From IMDb:
  [1] Interstellar (2014)
  [2] Interstellar (2007)

From TMDb:
  [3] Interstellar (2014)

Select correct match (0-3 or 'm' for manual): 1
✓ Selected from imdb: Interstellar (2014)
```

## Configuration Options

| Setting | Default | Description |
|---------|---------|-------------|
| `tmdb_api_key` | *(empty)* | TMDb API key (get from themoviedb.org) |
| `enable_tmdb_verification` | `true` | Enable TMDb verification |
| `enable_imdb_verification` | `true` | Enable IMDb verification |

## Benefits

1. **Accuracy**: Ensures correct movie titles and years
2. **User Control**: Full control over final metadata
3. **Flexibility**: Multiple sources and manual override
4. **Graceful Degradation**: Works without API keys (IMDb only)
5. **No External Dependencies**: Pure bash with curl

## Troubleshooting

**Q: Not seeing TMDb results?**
- Check if `tmdb_api_key` is set in `set_v.ini`
- Verify API key is valid (test at https://www.themoviedb.org)
- Check `enable_tmdb_verification=true`

**Q: Script hangs at verification?**
- Network issue - check internet connection
- Press Ctrl+C and restart with `enable_*_verification=false`

**Q: Want to skip verification for specific file?**
- Select option `[0]` to use extracted values

**Q: Results don't match my file?**
- Use option `[m]` for manual entry
- Update filename to have clearer title/year format
