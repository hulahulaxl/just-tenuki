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
            _applyPropertyToNode(currentNode, key, values);
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
    TreeNode node,
    String key,
    List<String> values,
  ) {
    if (values.isEmpty) return;

    // Store all raw properties for future features (like AB, AW, TR, CR, C)
    node.properties[key] = values.length == 1 ? values[0] : values;

    // Special logic for Moves
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
    }
  }

  static bool _isWhitespace(String c) {
    return c == ' ' || c == '\n' || c == '\r' || c == '\t';
  }

  static bool _isUpperCaseLetter(String c) {
    int code = c.codeUnitAt(0);
    return code >= 65 && code <= 90; // 'A' to 'Z'
  }
}
