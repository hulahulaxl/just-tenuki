import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/tree.dart';
import '../models/board_settings.dart';
import '../models/board_styles.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../utils/sgf_parser.dart';
import '../utils/sgf_writer.dart';
import '../utils/download_helper.dart';
import '../api/client.dart';
import '../api/protocol.dart';
import 'dart:async';
import 'board_widget.dart';
import 'tree/tree_graph_widget.dart';

// --- Tab State Models ---
enum BoardEditMode {
  play,
  addBlack,
  addWhite,
  remove,
  markTriangle,
  markSquare,
  markCircle,
  markCross,
  markLetter,
  markNumber,
}

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
  int _lobbyMenuIndex = 0; // 0 = New, 1 = Recent, 2 = Online Library
  BoardEditMode _editMode = BoardEditMode.play;

  StreamSubscription<EngineResponse>? _analysisSub;
  EngineResponse? _currentAnalysis;
  int? _lastAnalysisTurn;
  double _maxScoreScale = 10.0;

  bool _showTreePane = true;
  bool _showAnalysisPane = false;
  bool _showCommentsPane = false;
  bool _showSettingsPane = false;

  final ValueNotifier<BoardSettings> _globalSettings = ValueNotifier(
    const BoardSettings.defaults(),
  );

  // High precision flex values for smooth 1:1 cursor tracking, isolated via ValueNotifier
  final ValueNotifier<List<int>> _paneFlexes = ValueNotifier([
    10000,
    10000,
    10000,
    10000,
  ]);

  double _cumulativeDragDelta = 0;
  int _dragStartFlexTop = 0;
  int _dragStartFlexBottom = 0;

  late TextEditingController _commentController;
  TreeNode? _lastCommentNode;

  @override
  void initState() {
    super.initState();

    _commentController = TextEditingController();

    // TEMP: Commented out WS connection per user request
    // engineClient.connect();
    // _analysisSub = engineClient.updates.listen((response) {
    //   if (mounted) {
    //     setState(() {
    //       _currentAnalysis = response;
    //       if (_tabs[_activeIndex] is GameTab) {
    //         _lastAnalysisTurn = (_tabs[_activeIndex] as GameTab)
    //             .session
    //             .currentBoard
    //             .currentTurn;
    //       }
    //       if (response.rootScoreLead.abs() > _maxScoreScale) {
    //         _maxScoreScale = response.rootScoreLead.abs();
    //       }
    //     });
    //   }
    // });
  }

  @override
  void dispose() {
    _analysisSub?.cancel();
    engineClient.disconnect();
    _commentController.dispose();
    _paneFlexes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = _tabs[_activeIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isPortrait = constraints.maxWidth < constraints.maxHeight;

          if (isPortrait) {
            return Column(
              children: [
                _buildHorizontalTabBar(),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                if (activeTab is LobbyTab) ..._buildLobbyContentPortrait(),
                if (activeTab is GameTab)
                  ..._buildPortraitGameContent(activeTab),
              ],
            );
          }

          return Row(
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
          );
        },
      ),
    );
  }

  // Horizontal Tab Bar for Portrait Mode
  Widget _buildHorizontalTabBar() {
    return Container(
      height: 40,
      color: const Color(0xFFFAFAFA),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Dynamically build the tab icons based on open tabs
                  for (int i = 0; i < _tabs.length; i++) ...[
                    _buildHorizontalTabIcon(_tabs[i].icon, i, _tabs[i].tooltip),
                    const SizedBox(width: 2),
                  ],
                ],
              ),
            ),
          ),
          // Add a new Lobby Tab when clicked
          _buildHorizontalSidebarButton(Icons.add, 'Add Tab', () {
            setState(() {
              _tabs.add(LobbyTab());
              _activeIndex = _tabs.length - 1;
            });
          }),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHorizontalTabIcon(IconData icon, int index, String tooltip) {
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
            width: 40,
            height: 40,
            alignment: Alignment.center,
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

  Widget _buildHorizontalSidebarButton(
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
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.black54, size: 26),
          ),
        ),
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Dynamically build the tab icons based on open tabs
                  for (int i = 0; i < _tabs.length; i++) ...[
                    _buildTabIcon(_tabs[i].icon, i, _tabs[i].tooltip),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          // Add a new Lobby Tab when clicked
          _buildSidebarButton(Icons.add, 'Add Tab', () {
            setState(() {
              _tabs.add(LobbyTab());
              _activeIndex = _tabs.length - 1;
            });
          }),
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
            alignment: Alignment.center,
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

  Widget _buildRightToolbarButton(
    IconData icon,
    String tooltip,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 49,
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.black45,
              size: 22,
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
            const SizedBox(height: 16),
            _buildMenuTile('New...', Icons.add_box_outlined, 0),
            _buildMenuTile('Recent Files', Icons.history, 1),
            _buildMenuTile('Online Library', Icons.public, 2),
          ],
        ),
      ),
      const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEEEEE)),

      // Column 3: Context / Details
      Expanded(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(40.0),
          child: _lobbyMenuIndex != 0
              ? _buildComingSoonMock()
              : _buildNewGameView(),
        ),
      ),
    ];
  }

  List<Widget> _buildLobbyContentPortrait() {
    return [
      Expanded(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: _lobbyMenuIndex != 0
              ? _buildComingSoonMock()
              : _buildNewGameView(),
        ),
      ),
      BottomNavigationBar(
        currentIndex: _lobbyMenuIndex,
        onTap: (index) {
          setState(() {
            _lobbyMenuIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'New',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Recent'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Online'),
        ],
      ),
    ];
  }

  Widget _buildNewGameView() {
    return SingleChildScrollView(
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
        ],
      ),
    );
  }

  Widget _buildComingSoonMock() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.black26),
          SizedBox(height: 16),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
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
      parsedSession.last();

      setState(() {
        _tabs[_activeIndex] = GameTab(parsedSession);
        _maxScoreScale = 10.0;
        engineClient.analyze(parsedSession);
      });
    }
  }

  // Portrait Game / Analysis State
  List<Widget> _buildPortraitGameContent(GameTab tab) {
    return [
      Expanded(
        child: Container(
          color: const Color(0xFFF7F7F7),
          child: Column(
            children: [
              // 1. Board wrapped in AspectRatio (no padding/margin)
              AspectRatio(
                aspectRatio: 1.0,
                child: BoardWidget(
                  board: tab.session.currentBoard,
                  currentNode: tab.session.currentNode,
                  settingsNotifier: _globalSettings,
                  onIntersectionTapped: (x, y) {
                    if (_editMode == BoardEditMode.play) {
                      if (tab.session.play(x, y)) {
                        setState(() {});
                      }
                    } else {
                      // Handle setup stone placement/removal or markups (abridged for portrait)
                      if (_editMode == BoardEditMode.addBlack) {
                        tab.session.addSetupStone(x, y, 1);
                      } else if (_editMode == BoardEditMode.addWhite) {
                        tab.session.addSetupStone(x, y, 2);
                      } else if (_editMode == BoardEditMode.remove) {
                        tab.session.addSetupStone(x, y, 0);
                      }
                      setState(() {});
                    }
                  },
                  analysis:
                      (_lastAnalysisTurn ==
                          tab.session.currentBoard.currentTurn)
                      ? _currentAnalysis
                      : null,
                ),
              ),
              // 2. Winrate Bar directly beneath
              _buildWinrateBar(tab.session, isPortrait: true),
              const Spacer(),
              // 3. Navigation Buttons
              _buildStatusBar(tab.session),
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
                      board: tab.session.currentBoard,
                      currentNode: tab.session.currentNode,
                      settingsNotifier: _globalSettings,
                      onIntersectionTapped: (x, y) {
                        BoardEditMode effectiveMode = _editMode;

                        if (effectiveMode == BoardEditMode.play) {
                          // Let the session manage the move and tree timeline!
                          if (tab.session.play(x, y)) {
                            setState(() {});
                            // We do not analyze right now as requested by user
                            // engineClient.analyze(tab.session);
                          }
                        } else {
                          // Handle setup stone placement/removal
                          if (effectiveMode == BoardEditMode.addBlack ||
                              effectiveMode == BoardEditMode.addWhite ||
                              effectiveMode == BoardEditMode.remove) {
                            int playerVal = 0; // Empty
                            if (effectiveMode == BoardEditMode.addBlack) {
                              playerVal = 1;
                            }
                            if (effectiveMode == BoardEditMode.addWhite) {
                              playerVal = 2;
                            }

                            if (tab.session.addSetupStone(x, y, playerVal)) {
                              setState(() {});
                            }
                          } else {
                            // Handle markups
                            MarkupType? mType;
                            if (effectiveMode == BoardEditMode.markTriangle) {
                              mType = MarkupType.triangle;
                            }
                            if (effectiveMode == BoardEditMode.markSquare) {
                              mType = MarkupType.square;
                            }
                            if (effectiveMode == BoardEditMode.markCircle) {
                              mType = MarkupType.circle;
                            }
                            if (effectiveMode == BoardEditMode.markCross) {
                              mType = MarkupType.cross;
                            }
                            if (effectiveMode == BoardEditMode.markLetter) {
                              mType = MarkupType.letter;
                            }
                            if (effectiveMode == BoardEditMode.markNumber) {
                              mType = MarkupType.number;
                            }

                            if (mType != null &&
                                tab.session.toggleMarkup(x, y, mType)) {
                              setState(() {});
                            }
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

      // Column 3: Right Toolbar (Edit Tools & Toggles)
      Container(
        width: 49,
        height: double.infinity,
        color: const Color(0xFFFAFAFA),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildRightToolbarButton(
                Icons.account_tree_outlined,
                'Move Tree',
                _showTreePane,
                () {
                  setState(() => _showTreePane = !_showTreePane);
                },
              ),
              const SizedBox(height: 8),
              _buildRightToolbarButton(
                Icons.analytics_outlined,
                'AI Analysis',
                _showAnalysisPane,
                () {
                  setState(() => _showAnalysisPane = !_showAnalysisPane);
                },
              ),
              const SizedBox(height: 8),
              _buildRightToolbarButton(
                Icons.chat_bubble_outline,
                'Comments',
                _showCommentsPane,
                () {
                  setState(() => _showCommentsPane = !_showCommentsPane);
                },
              ),
              const SizedBox(height: 8),
              _buildRightToolbarButton(
                Icons.settings_outlined,
                'Settings',
                _showSettingsPane,
                () {
                  setState(() => _showSettingsPane = !_showSettingsPane);
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),
              _buildToolButton(
                Icons.circle,
                'Black Stone',
                isSelected: _editMode == BoardEditMode.addBlack,
                onTap: () => setState(
                  () => _editMode = _editMode == BoardEditMode.addBlack
                      ? BoardEditMode.play
                      : BoardEditMode.addBlack,
                ),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                Icons.circle_outlined,
                'White Stone',
                isSelected: _editMode == BoardEditMode.addWhite,
                onTap: () => setState(
                  () => _editMode = _editMode == BoardEditMode.addWhite
                      ? BoardEditMode.play
                      : BoardEditMode.addWhite,
                ),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                Icons.close,
                'Remove',
                isSelected: _editMode == BoardEditMode.remove,
                onTap: () => setState(
                  () => _editMode = _editMode == BoardEditMode.remove
                      ? BoardEditMode.play
                      : BoardEditMode.remove,
                ),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                Icons.change_history,
                'Triangle',
                isSelected: _editMode == BoardEditMode.markTriangle,
                onTap: () => setState(
                  () => _editMode = _editMode == BoardEditMode.markTriangle
                      ? BoardEditMode.play
                      : BoardEditMode.markTriangle,
                ),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                Icons.crop_square,
                'Square',
                isSelected: _editMode == BoardEditMode.markSquare,
                onTap: () => setState(
                  () => _editMode = _editMode == BoardEditMode.markSquare
                      ? BoardEditMode.play
                      : BoardEditMode.markSquare,
                ),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                Icons.radio_button_unchecked,
                'Circle',
                isSelected: _editMode == BoardEditMode.markCircle,
                onTap: () => setState(
                  () => _editMode = _editMode == BoardEditMode.markCircle
                      ? BoardEditMode.play
                      : BoardEditMode.markCircle,
                ),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                Icons.clear,
                'Cross',
                isSelected: _editMode == BoardEditMode.markCross,
                onTap: () => setState(
                  () => _editMode = _editMode == BoardEditMode.markCross
                      ? BoardEditMode.play
                      : BoardEditMode.markCross,
                ),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                Icons.text_fields,
                'Letter',
                isSelected: _editMode == BoardEditMode.markLetter,
                onTap: () => setState(
                  () => _editMode = _editMode == BoardEditMode.markLetter
                      ? BoardEditMode.play
                      : BoardEditMode.markLetter,
                ),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                Icons.numbers,
                'Number',
                isSelected: _editMode == BoardEditMode.markNumber,
                onTap: () => setState(
                  () => _editMode = _editMode == BoardEditMode.markNumber
                      ? BoardEditMode.play
                      : BoardEditMode.markNumber,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),
              _buildToolButton(
                Icons.download,
                'Export SGF',
                isSelected: false,
                backgroundColor: Colors.blue.shade600,
                iconColor: Colors.white,
                onTap: () {
                  if (_tabs[_activeIndex] is GameTab) {
                    final session = (_tabs[_activeIndex] as GameTab).session;
                    final sgfString = SgfWriter.write(session);
                    String p1 = session.info.blackName.replaceAll(' ', '_');
                    String p2 = session.info.whiteName.replaceAll(' ', '_');
                    String filename = '${p1}_vs_$p2.sgf';
                    if (p1.isEmpty && p2.isEmpty) filename = 'game_review.sgf';
                    downloadTextFile(sgfString, filename);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEEEEE)),

      // Column 4: Active Panes
      Container(
        width: 400,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ValueListenableBuilder<List<int>>(
                    valueListenable: _paneFlexes,
                    builder: (context, flexes, child) {
                      return Column(
                        children: _buildActivePanes(
                          tab,
                          constraints.maxHeight,
                          flexes,
                        ),
                      );
                    },
                  );
                },
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

    String formatTime(String? timeStr, int player) {
      if (timeStr == null || timeStr.isEmpty) return '--:--';
      double? seconds = double.tryParse(timeStr);
      if (seconds == null) {
        return timeStr; // Return as-is if not a valid number (e.g. some weird format)
      }
      int totalSeconds = seconds.round();
      int h = totalSeconds ~/ 3600;
      int m = (totalSeconds % 3600) ~/ 60;
      int s = totalSeconds % 60;

      String formatted;
      if (h > 0) {
        formatted =
            '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      } else {
        formatted =
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }

      String? otStr = session.getOvertimeLeft(player);
      if (otStr != null && otStr.isNotEmpty) {
        // Just append the period counter directly, e.g. (3)
        formatted += ' ($otStr)';
      } else if (session.info.overtime != null &&
          session.info.overtime!.isNotEmpty) {
        formatted += ' + ${session.info.overtime}';
      }
      return formatted;
    }

    String blackTime = formatTime(
      session.getTimeLeft(0) ?? session.info.baseTime,
      0,
    );
    String whiteTime = formatTime(
      session.getTimeLeft(1) ?? session.info.baseTime,
      1,
    );

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

  Widget _buildWinrateBar(GameSession session, {bool isPortrait = false}) {
    double winrate = 50.0;
    double scoreLead = 0.0;

    if (_currentAnalysis != null) {
      winrate = _currentAnalysis!.rootWinrate;
      scoreLead = _currentAnalysis!.rootScoreLead;
    }

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

    if (scoreLead >= 0) {
      textAlignment = Alignment.centerLeft;
      textColor = Colors.white;
    } else {
      textAlignment = Alignment.centerRight;
      textColor = Colors.black87;
    }

    return Container(
      height: isPortrait ? 16 : 24,
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
                      fontSize: isPortrait ? 10 : 12,
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

  // --- Dynamic Resizable Panes Logic ---

  List<Widget> _buildActivePanes(
    GameTab tab,
    double totalHeight,
    List<int> flexes,
  ) {
    List<_ActivePane> active = [];
    if (_showTreePane) active.add(_ActivePane(0, _buildTreeTab(tab)));
    if (_showAnalysisPane) active.add(_ActivePane(1, _buildAnalysisTabMock()));
    if (_showCommentsPane) active.add(_ActivePane(2, _buildCommentsPane(tab)));
    if (_showSettingsPane) active.add(_ActivePane(3, _buildSettingsPaneMock()));

    if (active.isEmpty) {
      return const [
        Expanded(
          child: Center(
            child: Text(
              'No panes active.',
              style: TextStyle(color: Colors.black38),
            ),
          ),
        ),
      ];
    }

    int totalActiveFlex = 0;
    for (var pane in active) {
      totalActiveFlex += flexes[pane.index];
    }

    List<Widget> children = [];
    for (int i = 0; i < active.length; i++) {
      children.add(
        Expanded(flex: flexes[active[i].index], child: active[i].widget),
      );
      if (i < active.length - 1) {
        children.add(
          _buildDraggableDivider(
            active[i].index,
            active[i + 1].index,
            totalHeight,
            totalActiveFlex,
          ),
        );
      }
    }
    return children;
  }

  Widget _buildDraggableDivider(
    int topIndex,
    int bottomIndex,
    double totalHeight,
    int totalActiveFlex,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (details) {
        _cumulativeDragDelta = 0;
        _dragStartFlexTop = _paneFlexes.value[topIndex];
        _dragStartFlexBottom = _paneFlexes.value[bottomIndex];
      },
      onVerticalDragUpdate: (details) {
        _cumulativeDragDelta += details.delta.dy;

        // Exact absolute math from drag start
        double fractionMoved = _cumulativeDragDelta / totalHeight;
        int flexChange = (fractionMoved * totalActiveFlex).round();

        int minFlex = 1000; // 10% of 10000 base

        int newTop = _dragStartFlexTop + flexChange;
        int newBottom = _dragStartFlexBottom - flexChange;

        // Clamp strictly against minFlex
        if (newTop < minFlex) {
          newTop = minFlex;
          newBottom = _dragStartFlexTop + _dragStartFlexBottom - minFlex;
        } else if (newBottom < minFlex) {
          newBottom = minFlex;
          newTop = _dragStartFlexTop + _dragStartFlexBottom - minFlex;
        }

        // Copy the list, update, and reassign to trigger ValueNotifier
        List<int> newFlexes = List.from(_paneFlexes.value);
        newFlexes[topIndex] = newTop;
        newFlexes[bottomIndex] = newBottom;
        _paneFlexes.value = newFlexes;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: Container(
          height: 8,
          color: Colors.transparent, // Invisible hit area
          child: Center(
            child: Container(
              height: 1,
              color: const Color(0xFFDDDDDD), // Visible thin line
            ),
          ),
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

  Widget _buildCommentsPane(GameTab tab) {
    // If the node changed, update the text controller's text!
    if (_lastCommentNode != tab.session.currentNode) {
      _lastCommentNode = tab.session.currentNode;
      _commentController.text = tab.session.currentNode.comment;
    }

    var path = <TreeNode>[];
    TreeNode? curr = tab.session.currentNode;
    while (curr != null) {
      path.insert(0, curr);
      curr = curr.parent;
    }

    int moveCounter = 0;
    List<Widget> historyWidgets = [];

    for (var n in path) {
      if (n.move != null) {
        moveCounter++;
      }

      if (n == tab.session.currentNode) {
        continue;
      }

      if (n.comment.trim().isNotEmpty) {
        String header = '[Move $moveCounter]';
        historyWidgets.add(
          InkWell(
            onTap: () {
              setState(() {
                tab.session.jumpTo(n);
                // Also trigger an AI analysis if the tab is active
                engineClient.analyze(tab.session);
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      header,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    n.comment.trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    String currentHeader = '[Move $moveCounter]';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: CustomScrollView(
        slivers: [
          if (historyWidgets.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: historyWidgets,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                currentHeader,
                style: TextStyle(
                  fontWeight: FontWeight.w900, // Extra bold
                  color: Colors.blue.shade700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: TextField(
              controller: _commentController,
              onChanged: (val) {
                tab.session.currentNode.comment = val;
              },
              maxLines: null, // Unlimited lines
              expands: true,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
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

  Widget _buildSettingsPaneMock() {
    return RepaintBoundary(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: SliderTheme(
          data: SliderTheme.of(
            context,
          ).copyWith(showValueIndicator: ShowValueIndicator.onDrag),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingSelector<Color>(
                  notifier: _globalSettings,
                  selector: (s) => s.boardColor,
                  builder: (context, boardColor) {
                    final int presetIndex = BoardStyles.boardColors
                        .take(9)
                        .toList()
                        .indexOf(boardColor);
                    final int selectedIndex = presetIndex != -1
                        ? presetIndex
                        : 9;

                    return _buildGridSelector(
                      itemCount: 10, // 9 presets + 1 custom
                      selectedIndex: selectedIndex,
                      onSelected: (i) {
                        if (i == 9) {
                          Color tempColor = boardColor;
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Pick Board Color'),
                                content: SingleChildScrollView(
                                  child: ColorPicker(
                                    pickerColor: tempColor,
                                    onColorChanged: (color) {
                                      tempColor = color;
                                      _globalSettings.value = _globalSettings
                                          .value
                                          .copyWith(boardColor: color);
                                    },
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    child: const Text('Done'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          _globalSettings.value = _globalSettings.value
                              .copyWith(boardColor: BoardStyles.boardColors[i]);
                        }
                      },
                      itemBuilder: (context, index, isSelected) {
                        if (index == 9) {
                          return Container(
                            decoration: BoxDecoration(
                              color: presetIndex == -1
                                  ? boardColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.blueAccent,
                                      width: 3,
                                    )
                                  : Border.all(
                                      color: Colors.grey.shade400,
                                      width: 1,
                                    ),
                            ),
                            child: const Icon(
                              Icons.color_lens,
                              color: Colors.black54,
                            ),
                          );
                        }

                        // Board line drawing for thumbnail
                        return Container(
                          decoration: BoxDecoration(
                            color: BoardStyles.boardColors[index],
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: Colors.blueAccent, width: 3)
                                : Border.all(
                                    color: Colors.transparent,
                                    width: 3,
                                  ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -1,
                                bottom: -1,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.black26,
                                        width: 1.5,
                                      ),
                                      left: BorderSide(
                                        color: Colors.black26,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 4),
                // White Stone Color
                SettingSelector<Color>(
                  notifier: _globalSettings,
                  selector: (s) => s.whiteStoneColor,
                  builder: (context, whiteStoneColor) {
                    final int presetIndex = BoardStyles.whiteStoneColorPresets
                        .take(9)
                        .toList()
                        .indexOf(whiteStoneColor);
                    final int selectedIndex = presetIndex != -1
                        ? presetIndex
                        : 9;
                    return _buildGridSelector(
                      itemCount: 10,
                      selectedIndex: selectedIndex,
                      onSelected: (i) {
                        if (i == 9) {
                          Color tempColor = whiteStoneColor;
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Pick White Stone Color'),
                                content: SingleChildScrollView(
                                  child: ColorPicker(
                                    pickerColor: tempColor,
                                    onColorChanged: (color) {
                                      tempColor = color;
                                      _globalSettings.value = _globalSettings
                                          .value
                                          .copyWith(whiteStoneColor: color);
                                    },
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    child: const Text('Done'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          _globalSettings.value = _globalSettings.value
                              .copyWith(
                                whiteStoneColor:
                                    BoardStyles.whiteStoneColorPresets[i],
                              );
                        }
                      },
                      itemBuilder: (context, index, isSelected) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8D4B4),
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: Colors.blueAccent, width: 3)
                                : Border.all(
                                    color: Colors.transparent,
                                    width: 3,
                                  ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: index == 9
                                    ? (presetIndex == -1
                                          ? whiteStoneColor
                                          : Colors.white)
                                    : BoardStyles.whiteStoneColorPresets[index],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 2,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                              child: index == 9
                                  ? const Icon(
                                      Icons.color_lens,
                                      color: Colors.black54,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 4),
                SettingSelector<int>(
                  notifier: _globalSettings,
                  selector: (s) => s.whiteStoneTextureIndex,
                  builder: (context, whiteStoneTextureIndex) {
                    return _buildGridSelector(
                      itemCount: BoardStyles.stoneTextures.length,
                      selectedIndex: whiteStoneTextureIndex,
                      onSelected: (i) => _globalSettings.value = _globalSettings
                          .value
                          .copyWith(whiteStoneTextureIndex: i),
                      itemBuilder: (context, index, isSelected) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8D4B4),
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: Colors.blueAccent, width: 3)
                                : Border.all(
                                    color: Colors.transparent,
                                    width: 3,
                                  ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: CustomPaint(
                              painter: _StoneThumbnailPainter(
                                paintFactory: BoardStyles.stoneTextures[index],
                                baseColor: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 4),
                // Black Stone Color
                SettingSelector<Color>(
                  notifier: _globalSettings,
                  selector: (s) => s.blackStoneColor,
                  builder: (context, blackStoneColor) {
                    final int presetIndex = BoardStyles.blackStoneColorPresets
                        .take(9)
                        .toList()
                        .indexOf(blackStoneColor);
                    final int selectedIndex = presetIndex != -1
                        ? presetIndex
                        : 9;
                    return _buildGridSelector(
                      itemCount: 10,
                      selectedIndex: selectedIndex,
                      onSelected: (i) {
                        if (i == 9) {
                          Color tempColor = blackStoneColor;
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Pick Black Stone Color'),
                                content: SingleChildScrollView(
                                  child: ColorPicker(
                                    pickerColor: tempColor,
                                    onColorChanged: (color) {
                                      tempColor = color;
                                      _globalSettings.value = _globalSettings
                                          .value
                                          .copyWith(blackStoneColor: color);
                                    },
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    child: const Text('Done'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          _globalSettings.value = _globalSettings.value
                              .copyWith(
                                blackStoneColor:
                                    BoardStyles.blackStoneColorPresets[i],
                              );
                        }
                      },
                      itemBuilder: (context, index, isSelected) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8D4B4),
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: Colors.blueAccent, width: 3)
                                : Border.all(
                                    color: Colors.transparent,
                                    width: 3,
                                  ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: index == 9
                                    ? (presetIndex == -1
                                          ? blackStoneColor
                                          : Colors.white)
                                    : BoardStyles.blackStoneColorPresets[index],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 2,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                              child: index == 9
                                  ? const Icon(
                                      Icons.color_lens,
                                      color: Colors.black54,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 4),
                SettingSelector<int>(
                  notifier: _globalSettings,
                  selector: (s) => s.blackStoneTextureIndex,
                  builder: (context, blackStoneTextureIndex) {
                    return _buildGridSelector(
                      itemCount: BoardStyles.stoneTextures.length,
                      selectedIndex: blackStoneTextureIndex,
                      onSelected: (i) => _globalSettings.value = _globalSettings
                          .value
                          .copyWith(blackStoneTextureIndex: i),
                      itemBuilder: (context, index, isSelected) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8D4B4),
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: Colors.blueAccent, width: 3)
                                : Border.all(
                                    color: Colors.transparent,
                                    width: 3,
                                  ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: CustomPaint(
                              painter: _StoneThumbnailPainter(
                                paintFactory: BoardStyles.stoneTextures[index],
                                baseColor: Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 4),
                SettingSelector<Color>(
                  notifier: _globalSettings,
                  selector: (s) => s.lineColor,
                  builder: (context, lineColor) {
                    final int presetIndex = BoardStyles.lineColorPresets
                        .take(9)
                        .toList()
                        .indexOf(lineColor);
                    final int selectedIndex = presetIndex != -1
                        ? presetIndex
                        : 9;
                    return _buildGridSelector(
                      itemCount: 10,
                      selectedIndex: selectedIndex,
                      onSelected: (i) {
                        if (i == 9) {
                          Color tempColor = lineColor;
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Pick Line Color'),
                                content: SingleChildScrollView(
                                  child: ColorPicker(
                                    pickerColor: tempColor,
                                    onColorChanged: (color) {
                                      tempColor = color;
                                      _globalSettings.value = _globalSettings
                                          .value
                                          .copyWith(lineColor: color);
                                    },
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    child: const Text('Done'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          _globalSettings.value = _globalSettings.value
                              .copyWith(
                                lineColor: BoardStyles.lineColorPresets[i],
                              );
                        }
                      },
                      itemBuilder: (context, index, isSelected) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8D4B4),
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: Colors.blueAccent, width: 3)
                                : Border.all(
                                    color: Colors.transparent,
                                    width: 3,
                                  ),
                          ),
                          child: Center(
                            child: index == 9
                                ? const Icon(
                                    Icons.color_lens,
                                    color: Colors.black54,
                                    size: 20,
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 2,
                                        color:
                                            BoardStyles.lineColorPresets[index],
                                      ),
                                      Container(
                                        width: 2,
                                        height: double.infinity,
                                        color:
                                            BoardStyles.lineColorPresets[index],
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                SettingSelector<bool>(
                  notifier: _globalSettings,
                  selector: (s) => s.showCoordinates,
                  builder: (context, showCoordinates) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Show Coordinates',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        Switch(
                          value: showCoordinates,
                          onChanged: (val) =>
                              _globalSettings.value = _globalSettings.value
                                  .copyWith(showCoordinates: val),
                          activeTrackColor: Colors.blue,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                SettingSelector<bool>(
                  notifier: _globalSettings,
                  selector: (s) => s.highlightLastMove,
                  builder: (context, highlightLastMove) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Highlight Last Move',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        Switch(
                          value: highlightLastMove,
                          onChanged: (val) =>
                              _globalSettings.value = _globalSettings.value
                                  .copyWith(highlightLastMove: val),
                          activeTrackColor: Colors.blue,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Line Thickness',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SettingSelector<double>(
                  notifier: _globalSettings,
                  selector: (s) => s.lineThickness,
                  builder: (context, lineThickness) {
                    return Slider(
                      value: lineThickness,
                      min: 0.5,
                      max: 2.5,
                      label: lineThickness.toStringAsFixed(1),
                      onChanged: (val) => _globalSettings.value =
                          _globalSettings.value.copyWith(lineThickness: val),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Star Point Size',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SettingSelector<double>(
                  notifier: _globalSettings,
                  selector: (s) => s.starPointThickness,
                  builder: (context, starPointThickness) {
                    return Slider(
                      value: starPointThickness,
                      min: 2.0,
                      max: 6.0,
                      label: starPointThickness.toStringAsFixed(1),
                      onChanged: (val) =>
                          _globalSettings.value = _globalSettings.value
                              .copyWith(starPointThickness: val),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Stone Size',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SettingSelector<double>(
                  notifier: _globalSettings,
                  selector: (s) => s.stoneScale,
                  builder: (context, stoneScale) {
                    return Slider(
                      value: stoneScale,
                      min: 0.8,
                      max: 1.0,
                      label: stoneScale.toStringAsFixed(2),
                      onChanged: (val) => _globalSettings.value =
                          _globalSettings.value.copyWith(stoneScale: val),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Stone Outline',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SettingSelector<double>(
                  notifier: _globalSettings,
                  selector: (s) => s.stoneOutlineThickness,
                  builder: (context, stoneOutlineThickness) {
                    return Slider(
                      value: stoneOutlineThickness,
                      min: 0.0,
                      max: 2.0,
                      label: stoneOutlineThickness.toStringAsFixed(1),
                      onChanged: (val) =>
                          _globalSettings.value = _globalSettings.value
                              .copyWith(stoneOutlineThickness: val),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Drop Shadow',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SettingSelector<double>(
                  notifier: _globalSettings,
                  selector: (s) => s.stoneDropShadow,
                  builder: (context, stoneDropShadow) {
                    return Slider(
                      value: stoneDropShadow,
                      min: 0.0,
                      max: 4.0,
                      label: stoneDropShadow.toStringAsFixed(1),
                      onChanged: (val) => _globalSettings.value =
                          _globalSettings.value.copyWith(stoneDropShadow: val),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridSelector({
    required int itemCount,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    required Widget Function(BuildContext, int, bool) itemBuilder,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onSelected(index),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: itemBuilder(context, index, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildToolButton(
    IconData icon,
    String tooltip, {
    bool isSelected = false,
    Color? backgroundColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                (isSelected ? Colors.blue.shade50 : Colors.white),
            border: Border.all(
              color: isSelected
                  ? Colors.blue.shade400
                  : (backgroundColor != null
                        ? Colors.transparent
                        : const Color(0xFFE0E0E0)),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              color:
                  iconColor ??
                  (isSelected ? Colors.blue.shade700 : Colors.black87),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(String title, IconData icon, int index) {
    bool isSelected = _lobbyMenuIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _lobbyMenuIndex = index;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          color: isSelected ? const Color(0xFFEEEEEE) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.blue.shade700 : Colors.black54,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
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

class _ActivePane {
  final int index;
  final Widget widget;
  _ActivePane(this.index, this.widget);
}

class SettingSelector<T> extends StatefulWidget {
  final ValueNotifier<BoardSettings> notifier;
  final T Function(BoardSettings settings) selector;
  final Widget Function(BuildContext context, T value) builder;

  const SettingSelector({
    super.key,
    required this.notifier,
    required this.selector,
    required this.builder,
  });

  @override
  State<SettingSelector<T>> createState() => _SettingSelectorState<T>();
}

class _SettingSelectorState<T> extends State<SettingSelector<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.selector(widget.notifier.value);
    widget.notifier.addListener(_listener);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    final newValue = widget.selector(widget.notifier.value);
    if (newValue != _value) {
      setState(() {
        _value = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _value);
  }
}

class _StoneThumbnailPainter extends CustomPainter {
  final StoneTextureFactory paintFactory;
  final Color baseColor;

  _StoneThumbnailPainter({required this.paintFactory, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = paintFactory(rect, baseColor);

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawOval(rect.translate(1, 1), shadowPaint);

    // Draw stone
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _StoneThumbnailPainter oldDelegate) {
    return oldDelegate.paintFactory != paintFactory ||
        oldDelegate.baseColor != baseColor;
  }
}
