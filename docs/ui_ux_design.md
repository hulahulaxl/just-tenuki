# GoReview UI/UX Design Specification

## Overview
GoReview uses a modern, 3-column layout optimized for desktop (landscape) screens. The design is heavily inspired by professional IDEs like VS Code, featuring a minimalist aesthetic and tab-based navigation.

## Design Language
- **Font**: [Lexend](https://fonts.google.com/specimen/Lexend) (Clean, highly readable, modern typography).
- **Theme**: Light Theme default (White backgrounds, high contrast text).
- **Style**: Minimalist. The background should be predominantly white, accented with very subtle background grid lines (large gaps) to provide structural texture without being noisy or distracting.

## Layout Architecture
The application is divided into three primary vertical columns:

### 1. Left Column: Vertical Tab Bar (Navigation)
- **Concept**: Behaves like Chrome browser tabs, but oriented vertically and icon-based (similar to the VS Code activity bar).
- **Behavior**:
  - Each icon represents an open "Tab" (a separate game, an analysis session, or a new lobby).
  - Users can have multiple tabs open simultaneously.
  - A permanent "Add Tab" (`+`) button allows spawning a new session.
  - On first launch, the app automatically opens exactly 1 tab (The Lobby).

### 2. Middle Column: Primary Content / Menus
The content of this column changes depending on the state of the active Tab.

**State A: Lobby / Main Menu**
- When a tab is first opened, this column acts as the "Main Menu".
- It displays a vertical list of primary categories:
  - `New...`
  - `Recent Files`
  - `Saved Files`

**State B: Active Game / Analysis**
- Once a board is started or loaded, this column transitions to the **Go Board**.
- The board takes up the entirety of this column, scaling cleanly within a responsive `AspectRatio`.

### 3. Right Column: Details / Context Menus
This column provides contextual details based on what is selected in the Middle Column.

**State A: Lobby Context**
- If `New...` is selected in the mid-column, this right column reveals the specific creation options:
  - `Empty Board` (Prompts for 9x9, 13x13, 19x19)
  - `Import SGF`
  - `Load GoReview`
- If `Recent Files` is selected, this column shows a list of recent games, metadata, dates, or thumbnails.

**State B: Active Game Context**
- While playing or analyzing a game, this column becomes the **Control Center**.
- Contains:
  - Game Tree (branching moves and history).
  - AI Analysis (Win-rate graph, score lead, PVs).
  - Annotation Tools (Markers, labels).
  - Playback Controls.
