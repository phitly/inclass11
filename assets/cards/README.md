# Card Assets

This directory contains card images for the Card Organizer app.

## Image Structure

Card images should follow this naming convention:
- `{value}{suit}.png`
- Values: a, 2, 3, 4, 5, 6, 7, 8, 9, 10, j, q, k
- Suits: h (hearts), s (spades), d (diamonds), c (clubs)

Examples:
- `ah.png` = Ace of Hearts
- `ks.png` = King of Spades
- `10d.png` = 10 of Diamonds

## Image Sources

For this demo app, we use:
1. Network images from deckofcardsapi.com
2. Fallback to placeholder cards with suit icons
3. Optional local assets (this directory)

## Implementation Notes

- Images are cached in the SQLite database as BLOB data
- The ImageService handles loading, caching, and fallbacks
- Images can be downloaded for offline use via the Image Management screen