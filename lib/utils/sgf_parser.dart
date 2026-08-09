import '../models/tree.dart';
import '../models/move.dart';

class SgfParser {
  /// Parses an SGF string and returns a GameSession
  static GameSession parse(String sgfText) {
    GameSession session = GameSession();
    List<TreeNode> stack = [];
    TreeNode currentNode = session.rootNode;
    bool isFirstNode = true;

    int i = 0;
    while (i < sgfText.length) {
      String char = sgfText[i];

      if (char == '(') {
        stack.add(currentNode);
        i++;
      } else if (char == ')') {
        if (stack.isNotEmpty) {
          currentNode = stack.removeLast();
        }
        i++;
      } else if (char == ';') {
        if (isFirstNode) {
          // The first node in the file IS the root node (setup / metadata)
          currentNode = session.rootNode;
          isFirstNode = false;
        } else {
          // Create a new child node
          TreeNode child = TreeNode(parent: currentNode);
          currentNode.children.add(child);
          currentNode = child;
        }
        i++;

        // Parse properties for this node
        while (i < sgfText.length) {
          // Skip whitespace between properties
          while (i < sgfText.length && _isWhitespace(sgfText[i])) {
            i++;
          }

          if (i >= sgfText.length) break;

          // If we hit a structural character, we're done parsing properties for this node
          if (sgfText[i] == '(' || sgfText[i] == ')' || sgfText[i] == ';') {
            break;
          }

          // Parse Property Key (A-Z)
          String key = "";
          while (i < sgfText.length && _isUpperCaseLetter(sgfText[i])) {
            key += sgfText[i];
            i++;
          }

          // Parse Property Values (e.g. [pd][dp])
          List<String> values = [];
          while (i < sgfText.length) {
            // Skip whitespace before bracket
            while (i < sgfText.length && _isWhitespace(sgfText[i])) {
              i++;
            }

            if (i < sgfText.length && sgfText[i] == '[') {
              i++; // Skip '['
              String value = "";
              // Handle escaping inside brackets
              while (i < sgfText.length) {
                if (sgfText[i] == '\\' && i + 1 < sgfText.length) {
                  value += sgfText[i + 1];
                  i += 2;
                } else if (sgfText[i] == ']') {
                  break;
                } else {
                  value += sgfText[i];
                  i++;
                }
              }
              if (i < sgfText.length && sgfText[i] == ']') {
                i++; // Skip ']'
              }
              values.add(value);
            } else {
              // No more brackets for this property
              break;
            }
          }

          if (key.isNotEmpty) {
            _applyPropertyToNode(session, currentNode, key, values);
          }
        }
      } else {
        // Skip junk outside of nodes (sometimes SGF files have comments or whitespace outside)
        i++;
      }
    }

    return session;
  }

  static void _applyPropertyToNode(
    GameSession session,
    TreeNode node,
    String key,
    List<String> values,
  ) {
    if (values.isEmpty) return;

    // 1. Core Moves
    if (key == 'B' || key == 'W') {
      int player = (key == 'B') ? 1 : 2;
      String val = values[0];

      // SGF uses "" or "tt" for pass (on 19x19)
      if (val.isEmpty || val.toLowerCase() == 'tt') {
        node.move = Pass(player);
      } else if (val.length >= 2) {
        int x = val.codeUnitAt(0) - 97; // 'a' is 97
        int y = val.codeUnitAt(1) - 97;
        node.move = Play(player, x, y);
      }
      return;
    }

    // 2. Text and Annotations
    if (key == 'C') {
      node.comment = values.join('\n');
      return;
    }
    if (key == 'N') {
      node.nodeName = values[0];
      return;
    }

    // 3. Time Remaining
    if (key == 'BL') {
      node.timeLeft[0] = values[0];
      return;
    }
    if (key == 'WL') {
      node.timeLeft[1] = values[0];
      return;
    }

    // 4. Board Annotations (Setup Stones & Marks)
    // SGF properties like AB, AW, TR, SQ can contain multiple values
    List<int> indices = _parseCoordinatesToIndices(
      values,
      19,
    ); // Defaulting to 19x19 for index math, could pull from session later

    switch (key) {
      case 'AB':
        node.setupBlackStones.addAll(indices);
        break;
      case 'AW':
        node.setupWhiteStones.addAll(indices);
        break;
      case 'TR':
        node.triangleMarks.addAll(indices);
        break;
      case 'SQ':
        node.squareMarks.addAll(indices);
        break;
      case 'CR':
        node.circleMarks.addAll(indices);
        break;
      case 'MA':
        node.crossMarks.addAll(indices);
        break;
    }

    // 5. Game Metadata (Global properties usually found on root node)
    switch (key) {
      case 'PB':
        session.info.blackName = values[0];
        break;
      case 'PW':
        session.info.whiteName = values[0];
        break;
      case 'BR':
        session.info.blackRank = values[0];
        break;
      case 'WR':
        session.info.whiteRank = values[0];
        break;
      case 'DT':
        session.info.date = values[0];
        break;
      case 'RE':
        session.info.result = values[0];
        break;
      case 'KM':
        session.info.komi = values[0];
        break;
      case 'RU':
        session.info.rules = values[0];
        break;
      case 'EV':
        session.info.event = values[0];
        break;
      case 'TM':
        session.info.baseTime = values[0];
        break;
      case 'OT':
        session.info.overtime = values[0];
        break;
    }
  }

  static List<int> _parseCoordinatesToIndices(
    List<String> values,
    int columns,
  ) {
    List<int> indices = [];
    for (var val in values) {
      if (val.length >= 2) {
        int x = val.codeUnitAt(0) - 97;
        int y = val.codeUnitAt(1) - 97;
        indices.add(y * columns + x);
      }
    }
    return indices;
  }

  static bool _isWhitespace(String c) {
    return c == ' ' || c == '\n' || c == '\r' || c == '\t';
  }

  static bool _isUpperCaseLetter(String c) {
    int code = c.codeUnitAt(0);
    return code >= 65 && code <= 90; // 'A' to 'Z'
  }
}
