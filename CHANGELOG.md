# Changelog

All notable changes to the HanaYomi project will be documented in this file.

---

## [1.0.1] - 2026-07-01

### Fixed
- **Latest vs Popular Manga Filter**: Fixed the "Latest" button in the Browse search screen to fetch the latest updates (`getLatestManga`) instead of repeating popular manga (`getPopularManga`).
- **Visual Overlap Overlays**: Fixed overlap issues in the Extensions tab caused by using `anchors.centerIn` inside vertical QML `Column` positioning.
- **Top Black Gap Offset**: Resolved viewport top offset layout gaps by recalculating element heights dynamically in `BrowsePage.qml` (`height: parent.height - y`).
---

## [1.0.0] - 2026-07-01

### Added
- **Suwayomi Runner & Embedded JRE**: Bundled a sandboxed ARM64 Java Runtime Environment (JRE) to boot a local Suwayomi server directly on Ubuntu Touch.
- **Teal Color Palette**: Updated navigation selection highlights, buttons, and badges to match the Suwayomi WebUI aesthetic (`#00bfa5`).
- **Dynamic Layout Settings**: Introduced Comfortable Grid, Compact Grid, and List views for browsing manga.
- **OpenStore Badge & Disclaimer**: Updated `README.md` with official store badges, metadata description, and developer disclaimers.

### Fixed
- **AppArmor DB Lockout**: Fixed database loading crashes by routing SQLite paths directly to the whitelisted data folder `~/.local/share/hanayomi.hakim`.
- **JRE Permissions**: Configured build steps in `CMakeLists.txt` to keep execution permissions (`+x`) on the bundled JRE binaries during click packaging.
- **MangaDex Source Duplication**: Resolved UI listing issues where local sources duplicated remote Suwayomi source references.

### Changed
- **License Update**: Migrated project licensing from MIT to the Apache License 2.0.
- **Removed Hardcoded MangaDex**: Removed the default built-in MangaDex extension to rely entirely on dynamic Suwayomi source fetching.
