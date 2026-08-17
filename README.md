# Just Tenuki (Go Review App)

> This README is AI generated

A modern, highly responsive, and feature-rich Go (Baduk/Weiqi) game review application built with Flutter. It features a custom-built SGF parser, multi-tab session management, local storage, and real-time integration with KataGo for superhuman analysis.

## 🚀 Features

- **Multi-Tab Interface:** Open and review multiple game records simultaneously. Features a vertical rail sidebar for desktop and a horizontal scrolling tab bar for mobile.
- **KataGo Integration:** Connects to a local KataGo WebSocket backend for real-time, infinite game analysis and win-rate graphs.
- **Advanced SGF Support:** Parses complex `.sgf` files including variations, comments, player metadata, setup stones (AB/AW), and board markup (triangles, squares, circles, letters).
- **Responsive & Resizable UI:** The workspace is divided into fully draggable, resizable panes (Tree Graph, Analysis, Comments, and Board Marks).
- **Mobile-First Enhancements:** Tailored UI for mobile browsers, including large touch targets, a custom heuristic to handle virtual keyboard overlaps smoothly, and swipe-friendly navigation.
- **Auto-Save & Persistence:** Uses a local database to instantly auto-save every single move, variation, and pane layout configuration so you never lose progress.

## 🏗 Architecture & Techniques

### Pure Event Sourcing for Game State

Instead of storing a massive physical board state array inside every single node of the tree, this app uses a **Pure Event Sourcing** architecture.
The `GameSession` only stores the exact _action_ (e.g., `Play(Black, X, Y)` or `Pass()`). Whenever the user jumps to a completely different branch in the timeline, the app instantly resets the board and recalculates the state by sequentially replaying the events from the root node. This eliminates edge cases with captures, ko rules, and complex variation branching.

### High-Performance Canvas Rendering

The Go board is not built out of hundreds of heavy DOM elements or widgets. It uses Flutter's highly performant `CustomPaint` API to mathematically draw the grid, star points, wood textures, and stones directly to the GPU canvas.

### Local NoSQL Storage (Hive)

Session states, active tabs, and user layout preferences are persisted locally using **Hive** (a lightweight and blazing fast key-value database for Dart). This allows the app to completely restore your workspace instantly upon reload.

### Custom Binary Protocol

Communication with the KataGo engine backend is handled via WebSockets using a heavily optimized **Custom Binary Protocol** (instead of heavy JSON payloads). This allows for lightning-fast streaming of win-rates and principal variations.

## 📂 Project Structure

- `lib/api/` - WebSocket client and binary protocol handling for KataGo.
- `lib/engine/` - Game rules, capture logic, and the physical `Board` state.
- `lib/models/` - SGF parsing (`sgf_parser.dart`) and event-sourcing tree management (`tree.dart`).
- `lib/services/` - `SettingsService` for Hive database persistence.
- `lib/ui/` - All UI components, including the custom board canvas, resizable panes, and responsive layout builders.

## 🛠 Getting Started

1. Ensure you have the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
2. Clone this repository.
3. Run `flutter pub get` to install dependencies.
4. Run `flutter run -d chrome` to launch the web app locally, or build it for your preferred platform.

## ⚠️ Tech Debt & Confessions

1. **AI Integration Pending:** The real-time KataGo integration architecture is technically there, but the actual implementation is currently taking a well-deserved vacation. We disabled it for the beta because no one likes a robotic back-seat driver anyway.
2. **Incomplete Features:** While the core viewing experience is rock solid, several planned features are still firmly stuck in the "I'll definitely get to it this weekend" phase.
3. **Architectural Scaling:** I started this project purely as an excuse to learn Flutter, with a feature plan that could fit on a sticky note. But then scope creep happened, features multiplied like rabbits, and now the architecture is holding on by duct tape and sheer willpower. If I ever decide to continue development, I will almost certainly need to burn the entire codebase to the ground and rewrite it from scratch.
