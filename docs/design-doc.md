# Just Tenuki

> When in doubt, Tenuki.

An offline-first app for reviewing Go/Baduk/Weiqi games, focusing on analyzing variations and AI insights.

## General Info

- Name: Just Tenuki
- Platform: Desktop (Windows, macOS, Linux) via Direct Download (GitHub Releases).
- Tech Stack: Flutter (Custom UI using `CustomPaint` for the board to ensure flexibility for arbitrary sizes and themes).

## High-level Features

- **Flexible Board:** Support any board size (standard 9x9, 13x13, 19x19, and arbitrary sizes).
- **Custom Rendering:** We will implement the board rendering ourselves using Flutter's `CustomPaint` for maximum flexibility and custom theming.
- **Basic Rules (Review Mode):** Initially, we will only enforce basic rules (like liberties and overlapping stones). Complex rules like Ko/Superko will be skipped or deferred, as this is primarily a review app, not a strict game server.
- **SGF & Variations:**
  - Load games from standard SGF files.
  - Support for SGF collections (potentially integrated with a free SGF API like OGS so users don't have to provide their own files).
  - Robust support for branching variations (exploring "what if" scenarios).
- **AI Integration (KataGo):**
  - Use KataGo as the AI engine for counting, estimating, and move analysis.
  - Users can load custom neural network weights (e.g., `.bin.gz`) from local files.

## Architecture & Flow

- **Offline First & Free Distribution:** The app operates entirely offline. It will be distributed as an unsigned `.zip` or `.dmg` via GitHub Releases to avoid costly Code Signing certificates.
- **AI Execution (KataGo):**
  - **The Solution:** Targeting desktop makes KataGo integration trivial. We will bundle the standard, official KataGo executable (`.exe` on Windows, Unix binary on Mac/Linux) next to our app.
  - **Integration:** The Flutter app will spawn KataGo as a background process using standard Input/Output (Dart's `Process.start`) and communicate via the Go Text Protocol (GTP).
  - **Engine Configuration (Local vs Remote):** The app's architecture will abstract the engine interface, allowing users to configure the AI source:
    - _Desktop:_ Uses the local bundled executable (offline).
    - _Mobile (Power User Mode):_ Users can run a lightweight KataGo server script on their desktop PC, and configure the mobile app to connect to their desktop's local IP address (over local WiFi). This allows a powerful, free mobile app immediately without cloud costs.
    - _Mobile (Future):_ Point the app to a managed cloud server.
  - **Hardware:** Local desktop execution (or local WiFi streaming) allows the app to automatically leverage the user's powerful desktop GPU to run massive, superhuman neural networks seamlessly.
- **Flow:**
  - User starts an empty board or loads an SGF file.
  - User browses variations, adds annotations, or activates KataGo to analyze the current board state.
