import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/tree.dart';
import '../models/move.dart';
import '../utils/sgf_parser.dart';
import '../api/client.dart';
import '../api/protocol.dart';
import 'dart:async';
import 'board_widget.dart';
import 'tree/tree_graph_widget.dart';

// --- Tab State Models ---
enum BoardEditMode { play, addBlack, addWhite, remove }

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

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  final List<AppTab> _tabs = [LobbyTab()]; // Start with 1 Lobby tab
  int _activeIndex = 0;
  BoardEditMode _editMode = BoardEditMode.play;

  StreamSubscription<EngineResponse>? _analysisSub;
  EngineResponse? _currentAnalysis;
  int? _lastAnalysisTurn;
  double _maxScoreScale = 10.0;

  late TabController _rightTabController;

  @override
  void initState() {
    super.initState();
    _rightTabController = TabController(length: 3, vsync: this);
    _rightTabController.addListener(() {
      if (mounted) setState(() {});
    });

    engineClient.connect();
    _analysisSub = engineClient.updates.listen((response) {
      if (mounted) {
        setState(() {
          _currentAnalysis = response;
          if (_tabs[_activeIndex] is GameTab) {
            _lastAnalysisTurn = (_tabs[_activeIndex] as GameTab)
                .session
                .currentBoard
                .currentTurn;
          }
          if (response.rootScoreLead.abs() > _maxScoreScale) {
            _maxScoreScale = response.rootScoreLead.abs();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _analysisSub?.cancel();
    engineClient.disconnect();
    _rightTabController.dispose();
    super.dispose();
  }

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
        onTap: () {
          setState(() => _activeIndex = index);
          if (_tabs[index] is GameTab) {
            engineClient.analyze((_tabs[index] as GameTab).session);
          }
        },
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
                    _maxScoreScale = 10.0;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDetailCard(
                'Import SGF',
                'Load a standard .sgf game record to review or play against AI.',
                Icons.file_download_outlined,
                onTap: _pickAndLoadSgf,
              ),
              const SizedBox(height: 16),
              _buildDetailCard(
                'Load .tenuki',
                'Open a proprietary project containing AI analysis and custom annotations.',
                Icons.analytics_outlined,
                onTap: _pickAndLoadSgf,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Future<void> _pickAndLoadSgf() async {
    // 1. Pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sgf', 'tenuki'],
      withData: true, // Crucial for Web support
    );

    if (result != null) {
      String sgfText;

      // 2. Read the file (Handle Web vs Desktop differently)
      if (kIsWeb) {
        sgfText = utf8.decode(result.files.single.bytes!);
      } else {
        File file = File(result.files.single.path!);
        sgfText = await file.readAsString();
      }

      // 3. Parse and load
      GameSession parsedSession = SgfParser.parse(sgfText);
      // Guarantee that the root board state (including setup stones) is physically applied
      parsedSession.first();

      setState(() {
        _tabs[_activeIndex] = GameTab(parsedSession);
        _maxScoreScale = 10.0;
        engineClient.analyze(parsedSession);
      });
    }
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
                      board: tab.session.currentBoard,
                      latestMoveX: tab.session.currentNode.move is Play
                          ? (tab.session.currentNode.move as Play).x
                          : null,
                      latestMoveY: tab.session.currentNode.move is Play
                          ? (tab.session.currentNode.move as Play).y
                          : null,
                      onIntersectionTapped: (x, y) {
                        // Edit tools only work when the Tools tab is active
                        BoardEditMode effectiveMode = _rightTabController.index == 2
                            ? _editMode
                            : BoardEditMode.play;

                        if (effectiveMode == BoardEditMode.play) {
                          // Let the session manage the move and tree timeline!
                          if (tab.session.play(x, y)) {
                            setState(() {});
                            // We do not analyze right now as requested by user
                            // engineClient.analyze(tab.session);
                          }
                        } else {
                          // Handle setup stone placement/removal
                          int playerVal = 0; // Empty
                          if (effectiveMode == BoardEditMode.addBlack) playerVal = 1;
                          if (effectiveMode == BoardEditMode.addWhite) playerVal = 2;
                          
                          if (tab.session.addSetupStone(x, y, playerVal)) {
                            setState(() {});
                            // engineClient.analyze(tab.session);
                          }
                        }
                      },
                      analysis:
                          (_lastAnalysisTurn ==
                              tab.session.currentBoard.currentTurn)
                          ? _currentAnalysis
                          : null,
                    ),
                  ),
                ),
              ),
              _buildWinrateBar(tab.session),
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
        child: Column(
          children: [
            TabBar(
              controller: _rightTabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.blue,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Tree'),
                Tab(text: 'Analysis'),
                Tab(text: 'Tools'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _rightTabController,
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
    ];
  }

  Widget _buildStatusBar(GameSession session) {
    int blackCaptures = session.currentBoard.captures.isNotEmpty
        ? session.currentBoard.captures[0]
        : 0;
    int whiteCaptures = session.currentBoard.captures.length > 1
        ? session.currentBoard.captures[1]
        : 0;

    String pb = session.info.blackName;
    String br = session.info.blackRank != null
        ? ' [${session.info.blackRank}]'
        : '';
    String blackName = '$pb$br';

    String pw = session.info.whiteName;
    String wr = session.info.whiteRank != null
        ? ' [${session.info.whiteRank}]'
        : '';
    String whiteName = '$pw$wr';

    String blackTime =
        session.currentNode.timeLeft[0] ?? session.info.baseTime ?? '--:--';
    String whiteTime =
        session.currentNode.timeLeft[1] ?? session.info.baseTime ?? '--:--';

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
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.black87, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    blackName,
                    style: const TextStyle(
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
                  Text(
                    blackTime,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation Controls (No Ripples)
          Row(
            children: [
              _buildNavButton(Icons.first_page, () {
                setState(() => session.first());
                engineClient.analyze(session);
              }),
              const SizedBox(width: 4),
              _buildNavButton(Icons.navigate_before, () {
                setState(() => session.undo());
                engineClient.analyze(session);
              }),
              const SizedBox(width: 4),
              _buildNavButton(Icons.navigate_next, () {
                setState(() => session.next());
                engineClient.analyze(session);
              }),
              const SizedBox(width: 4),
              _buildNavButton(Icons.last_page, () {
                setState(() => session.last());
                engineClient.analyze(session);
              }),
            ],
          ),

          // White Info
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                children: [
                  Text(
                    whiteTime,
                    style: const TextStyle(
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
                  Text(
                    whiteName,
                    style: const TextStyle(
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
            ),
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

  Widget _buildWinrateBar(GameSession session) {
    if (_currentAnalysis == null) {
      return const SizedBox(height: 24);
    }

    double winrate = _currentAnalysis!.rootWinrate;
    double scoreLead = _currentAnalysis!.rootScoreLead;

    // KataGo returns values relative to the player to move.
    // Convert to absolute values (Black's perspective)
    // We use _lastAnalysisTurn instead of the current board turn to prevent flickering
    // when a stone is placed but the new AI response hasn't arrived yet!
    int turnToUse = _lastAnalysisTurn ?? session.currentBoard.currentTurn;
    if (turnToUse == 2) {
      winrate = 100 - winrate;
      scoreLead = -scoreLead;
    }

    // Calculate bar width based on scoreLead and historical max score scale.
    // Black's share goes from 0 (White +max) to 1.0 (Black +max)
    double targetBlackShare =
        (scoreLead + _maxScoreScale) / (2 * _maxScoreScale);
    targetBlackShare = targetBlackShare.clamp(0.0, 1.0);

    String scoreStr = scoreLead == 0
        ? '0.0'
        : '+${scoreLead.abs().toStringAsFixed(1)}';

    Alignment textAlignment;
    Color textColor;

    if (scoreLead > 0) {
      textAlignment = Alignment.centerLeft;
      textColor = Colors.white;
    } else if (scoreLead < 0) {
      textAlignment = Alignment.centerRight;
      textColor = Colors.black87;
    } else {
      textAlignment = Alignment.center;
      textColor = Colors.black45;
    }

    return Container(
      height: 24,
      color: Colors.white,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.5, end: targetBlackShare),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, animatedBlackShare, child) {
          int blackFlex = (animatedBlackShare * 1000).round();
          int whiteFlex = 1000 - blackFlex;

          return Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: blackFlex,
                    child: Container(color: Colors.black87),
                  ),
                  Expanded(
                    flex: whiteFlex,
                    child: Container(color: Colors.white),
                  ),
                ],
              ),
              Align(
                alignment: textAlignment,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    scoreStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BOARD EDITING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToolButton(
                Icons.circle,
                'Black Stone',
                isSelected: _editMode == BoardEditMode.addBlack,
                onTap: () {
                  setState(() {
                    _editMode = _editMode == BoardEditMode.addBlack
                        ? BoardEditMode.play
                        : BoardEditMode.addBlack;
                  });
                },
              ),
              _buildToolButton(
                Icons.circle_outlined,
                'White Stone',
                isSelected: _editMode == BoardEditMode.addWhite,
                onTap: () {
                  setState(() {
                    _editMode = _editMode == BoardEditMode.addWhite
                        ? BoardEditMode.play
                        : BoardEditMode.addWhite;
                  });
                },
              ),
              _buildToolButton(
                Icons.close,
                'Remove',
                isSelected: _editMode == BoardEditMode.remove,
                onTap: () {
                  setState(() {
                    _editMode = _editMode == BoardEditMode.remove
                        ? BoardEditMode.play
                        : BoardEditMode.remove;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'MARKUP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToolButton(Icons.change_history, 'Triangle'),
              _buildToolButton(Icons.crop_square, 'Square'),
              _buildToolButton(Icons.radio_button_unchecked, 'Circle'),
              _buildToolButton(Icons.clear, 'Cross'),
              _buildToolButton(Icons.text_fields, 'Letter'),
            ],
          ),
          const Spacer(),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {}, // TODO: Implement SGF Export
              icon: const Icon(Icons.download),
              label: const Text('Export SGF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label,
      {bool isSelected = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue.shade700 : Colors.black87,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue.shade800 : Colors.black54,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
