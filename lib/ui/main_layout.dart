import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedTabIndex = 0; // 0 = Lobby

  @override
  Widget build(BuildContext context) {
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
          if (_selectedTabIndex == 0) ..._buildLobbyContent(),
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
          _buildTabIcon(Icons.space_dashboard_outlined, 0),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black54),
            tooltip: 'Add Tab',
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            tooltip: 'Settings',
            onPressed: () {},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
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

      // Column 3: Context / Details (Mock UI)
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

  Widget _buildMenuTile(String title, IconData icon, bool isSelected) {
    return Container(
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

  Widget _buildDetailCard(String title, String subtitle, IconData icon) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: InkWell(
        onTap: () {}, // No functionality yet
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
