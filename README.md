# HanaYomi
HanaYomi is a beautiful, premium, and native manga reader application designed for **Ubuntu Touch** devices, heavily inspired by the desktop/mobile elegance of **Mihon** (and Tachiyomi). Built on top of C++ and Qt Quick/QML with Lomiri Components 1.3, HanaYomi delivers a fluid and highly responsive manga reading experience.
---
## Features
- **MangaDex Integration**: Native support for browsing, searching, and reading manga directly from MangaDex.
- **Extension Store**: Support for third-party extensions (e.g., Keiyoushi repository index compatibility) to discover and add manga sources.
- **Library Categories**: Organize your favorite manga into custom categories (e.g., *Reading*, *Plan to Read*, *Completed*) just like in Mihon.
- **Advanced Library Filters**: Sort your library by title, last update, or date added, and filter entries by status (Ongoing, Completed, etc.).
- **Custom Reader Modes**:
  - **Webtoon Mode**: Smooth, continuous vertical scrolling.
  - **Pager Mode**: Horizontal page-by-page swipe layout with snap transitions.
- **History & Updates**: Keep track of what you read, when you read it, and stay notified on new chapter releases.
- **Premium Aesthetics**: Harmonious dark mode design utilizing glassmorphism hints, curated HSL-tailored colors, and smooth micro-animations.
- **Custom Network Factory**: Bypasses typical MangaDex API blocks via global QML User-Agent header injection (`HanaYomi/1.0.0`).
---
## Screenshots
Upcomming...
---
## Installation
### Prerequisites
To compile and package HanaYomi for Ubuntu Touch, you will need **Clickable** installed on your system.
If you don't have Clickable, install it by following the instructions at [clickable-ut.dev](https://clickable-ut.dev/en/latest/install.html).
### Building & Running on Desktop (Docker Mode)
To build and run the application in a sandboxed Ubuntu Touch environment on your desktop, execute:
```bash
sg docker -c "clickable desktop"
```
This command automatically pulls the correct Docker builder container, compiles the C++ codebase, compiles the QML resources, and launches the application.
### Building & Installing to a Connected Device
To package and install the application directly onto a USB-connected Ubuntu Touch device:
```bash
sg docker -c "clickable"
```
---
## Usage
1. **Browse & Search**: Go to the **Browse** tab, select a source (like MangaDex), or add extension links (such as Keiyoushi repo indexes) to search for manga.
2. **Organize**: In the **Manga Detail** page, click **Add to Library** to trigger the category selection overlay and assign the manga to your personalized lists.
3. **Customize Reader**: While reading a chapter, tap the center of the screen to open the reader settings. Toggle between **Webtoon** (vertical) and **Pager** (horizontal) modes.
4. **Settings & More**: Manage your database, clear cache, or check statistics in the **More** tab.
---
## Architecture & Code Structure
The project splits performance-critical backend tasks (database operations and API interactions) into C++ classes, exposing them to the QML declarative interface:
- `src/main.cpp`: Entrypoint initializing the QML engine and setting up the network access manager factory.
- `src/DatabaseHelper.cpp`: Handles all SQLite interactions (history, category configurations, library tables).
- `src/MangaDexSource.cpp`: Communicates with source REST APIs and processes QML-level data hooks.
- `qml/Main.qml`: Root application interface and bottom navigation bar.
- `qml/pages/`: Contains page files (`LibraryPage.qml`, `ReaderPage.qml`, `MangaDetailPage.qml`, `BrowsePage.qml`, `MorePage.qml`, etc.).
- `qml/assets/`: Stores local resources and logos.
---
## Contributing
Contributions from the community are extremely welcome! If you want to help make HanaYomi the best manga reader on Ubuntu Touch, here is how you can get started:
### Development Workflow
1. **Fork the Repository**: Create a personal fork on GitHub.
2. **Clone the Project**: Clone your fork locally.
3. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/amazing-feature
   ```
4. **Implement & Test**: Make your changes, then run `clickable desktop` to ensure everything compiles and runs without QML warnings.
5. **Commit & Push**:
   ```bash
   git commit -m "Add some amazing feature"
   git push origin feature/amazing-feature
   ```
6. **Open a Pull Request**: Submit your pull request to the main repository.
### TODO List / Roadmap
Feel free to pick up any of the following tasks if you are looking for things to contribute:
- [ ] **Local Backups**: Import/Export database backups compatible with Mihon format.
- [ ] **Multi-Source Support**: Add local chapter parsing (EPUB/CBZ formats).
- [ ] **Offline Downloading**: Downloader queue manager for reading chapters offline.
- [ ] **Extension Updates Indicator**: Notification badge when extension indexes receive package updates.
- [ ] **Tracking Integration**: Sync progress with platforms like Anilist or MyAnimeList.
- [ ] **Advanced Zooming**: Double-tap and pinch-to-zoom gestures inside the Pager mode reader.
---
## License
HanaYomi is licensed under the MIT License. See the `LICENSE` file for details.