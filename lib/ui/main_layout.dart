import 'package:flutter/material.dart';
import '../models/tree.dart';
import 'board_widget.dart';
import 'tree/tree_graph_widget.dart';

// --- Tab State Models ---
abstract class AppTab {
  IconData get icon;
  String get tooltip;
}

class LobbyTab extends AppTab {
  @override
  IconData get icon => Icons.space_dashboard_outlined;
  @override
  String get tooltip => 'Lobby';
}

class GameTab extends AppTab {
  final GameSession session;
  GameTab(this.session);

  @override
  IconData get icon => Icons.grid_4x4_outlined;
  @override
  String get tooltip => 'Analysis';
}

// --- Main Layout ---
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final List<AppTab> _tabs = [LobbyTab()]; // Start with 1 Lobby tab
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activeTab = _tabs[_activeIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          _buildVerticalTabBar(),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color(0xFFEEEEEE),
          ),
          if (activeTab is LobbyTab) ..._buildLobbyContent(),
          if (activeTab is GameTab) ..._buildGameContent(activeTab),
        ],
      ),
    );
  }

  // Column 1: Vertical Tab Bar (VS Code style)
  Widget _buildVerticalTabBar() {
    return Container(
      width: 60,
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Dynamically build the tab icons based on open tabs
          for (int i = 0; i < _tabs.length; i++) ...[
            _buildTabIcon(_tabs[i].icon, i, _tabs[i].tooltip),
            const SizedBox(height: 8),
          ],
          const Spacer(),
          // Add a new Lobby Tab when clicked
          _buildSidebarButton(Icons.add, 'Add Tab', () {
            setState(() {
              _tabs.add(LobbyTab());
              _activeIndex = _tabs.length - 1;
            });
          }),
          const SizedBox(height: 8),
          _buildSidebarButton(Icons.settings_outlined, 'Settings', () {}),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, int index, String tooltip) {
    final isSelected = _activeIndex == index;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => setState(() => _activeIndex = index),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 60,
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black87 : Colors.black38,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 60,
            height: 48,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.black54, size: 26),
          ),
        ),
      ),
    );
  }

  // Column 2 & 3: Lobby State
  List<Widget> _buildLobbyContent() {
    return [
      // Column 2: Main Menu
      Container(
        width: 250,
        color: const Color(0xFFF9F9F9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Text(
                'LOBBY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _buildMenuTile('New...', Icons.add_box_outlined, true),
            _buildMenuTile('Recent Files', Icons.history, false),
            _buildMenuTile('Saved Files', Icons.folder_outlined, false),
          ],
        ),
      ),
      const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEEEEE)),

      // Column 3: Context / Details
      Expanded(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Game',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how you want to begin.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              _buildDetailCard(
                'Empty Board',
                'Start a fresh game on a 9x9, 13x13, or 19x19 board.',
                Icons.grid_on,
                onTap: () {
                  setState(() {
                    // Replace the current LobbyTab with a new GameTab powered by a full GameSession!
                    _tabs[_activeIndex] = GameTab(GameSession());
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDetailCard(
                'Import SGF',
                'Load a standard .sgf game record to review or play against AI.',
                Icons.file_download_outlined,
              ),
              const SizedBox(height: 16),
              _buildDetailCard(
                'Load GoReview',
                'Open a proprietary project containing AI analysis and custom annotations.',
                Icons.analytics_outlined,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Column 2 & 3: Game / Analysis State
  List<Widget> _buildGameContent(GameTab tab) {
    return [
      // Column 2: The Go Board + Status Bar
      Expanded(
        child: Container(
          color: const Color(0xFFF7F7F7),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: BoardWidget(
                      board: tab
                          .session
                          .currentBoard, // Use the physical board from the session
                      onIntersectionTapped: (point) {
                        // Let the session manage the move and tree timeline!
                        if (tab.session.play(point)) setState(() {});
                      },
                    ),
                  ),
                ),
              ),
              _buildStatusBar(tab.session),
            ],
          ),
        ),
      ),
      const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEEEEE)),

      // Column 3: Control Center (Tabbed Interface)
      Container(
        width: 450,
        color: Colors.white,
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.blue,
                labelStyle: TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Tree'),
                  Tab(text: 'Analysis'),
                  Tab(text: 'Tools'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTreeTab(tab),
                    _buildAnalysisTabMock(),
                    _buildToolsTabMock(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildStatusBar(GameSession session) {
    int blackCaptures = session.currentBoard.captures.isNotEmpty
        ? session.currentBoard.captures[0]
        : 0;
    int whiteCaptures = session.currentBoard.captures.length > 1
        ? session.currentBoard.captures[1]
        : 0;

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Black Info
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.black87, size: 14),
              const SizedBox(width: 8),
              const Text(
                'Black [9d]',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Captures: $blackCaptures',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Text(
                '10:00',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          // Navigation Controls (No Ripples)
          Row(
            children: [
              _buildNavButton(
                Icons.first_page,
                () => setState(() => session.first()),
              ),
              const SizedBox(width: 4),
              _buildNavButton(
                Icons.navigate_before,
                () => setState(() => session.undo()),
              ),
              const SizedBox(width: 4),
              _buildNavButton(
                Icons.navigate_next,
                () => setState(() => session.next()),
              ),
              const SizedBox(width: 4),
              _buildNavButton(
                Icons.last_page,
                () => setState(() => session.last()),
              ),
            ],
          ),

          // White Info
          Row(
            children: [
              const Text(
                '10:00',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Captures: $whiteCaptures',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Text(
                'White [9d]',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.black45, width: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.black54, size: 20),
        ),
      ),
    );
  }

  Widget _buildTreeTab(GameTab tab) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: TreeGraphWidget(
        session: tab.session,
        onNodeSelected: () => setState(() {}),
      ),
    );
  }

  Widget _buildAnalysisTabMock() {
    return const Center(
      child: Text(
        'AI Analysis Data (Mock)',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

  Widget _buildToolsTabMock() {
    return const Center(
      child: Text(
        'Annotation Tools (Mock)',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

  Widget _buildMenuTile(String title, IconData icon, bool isSelected) {
    return Material(
      color: isSelected
          ? Colors.black.withValues(alpha: 0.04)
          : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        leading: Icon(
          icon,
          color: isSelected ? Colors.black87 : Colors.black54,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black87 : Colors.black54,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () {}, // No functionality yet
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFFFAFAFA),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 28, color: Colors.blue[700]),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
