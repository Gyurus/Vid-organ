# Known Limitations and Considerations

## JSON Parsing

The TMDb and IMDb integration uses pure bash (grep/sed) for JSON parsing to avoid external dependencies like `jq`. This has some limitations:

### Limitations:
- **Nested Objects**: May not correctly parse movie objects containing deeply nested JSON structures
- **Null Values**: Assumes `release_date` has a valid string value, not null
- **Complex Arrays**: Limited support for arrays within movie objects

### Why This Is Acceptable:
1. **TMDb/IMDb Response Format**: These APIs return simple, flat movie objects in their search results
2. **Typical Use Case**: Movie search responses rarely contain deeply nested structures
3. **Graceful Degradation**: Parse failures simply result in missing suggestions (not crashes)
4. **User Override**: Manual entry option always available as fallback

### Future Improvements:
If more robust JSON parsing is needed:
- Add optional `jq` support (detect and use if available)
- Fall back to current grep/sed approach if `jq` not installed
- Keep zero-dependency approach as default

## Return Code vs String Matching

The workflow uses `grep -q "✓ IMDb Match Found"` to check verification success. While functional, a cleaner approach would be checking exit codes directly.

### Current Approach:
```bash
if ! check_imdb_match "$movie_title" "$movie_year" 2>&1 | grep -q "✓ IMDb Match Found"; then
```

### Alternative (Future):
```bash
if ! check_imdb_match "$movie_title" "$movie_year"; then
    # Exit code 0 = exact match, 1 = suggestions available
```

This is a low-priority improvement since the current method works reliably.

## Array Bounds

User input validation occurs before array access, but additional defensive checks could be added for extra safety. Current validation is sufficient for normal use.

## Testing Recommendations

When testing this feature:
1. Test with various movie title formats
2. Test with missing year information
3. Test with and without API keys
4. Test network failure scenarios
5. Test manual entry mode
6. Test with special characters in titles

These scenarios are all handled gracefully by the current implementation.
