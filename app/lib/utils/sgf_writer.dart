import '../models/tree.dart';
import '../models/move.dart';

class SgfWriter {
  /// Converts a GameSession into an SGF string.
  static String write(GameSession session) {
    final buffer = StringBuffer();
    buffer.write('(;FF[4]GM[1]SZ[19]');

    // Write Game Metadata
    final info = session.info;
    if (info.blackName.isNotEmpty) {
      buffer.write('PB[${_escape(info.blackName)}]');
    }
    if (info.whiteName.isNotEmpty) {
      buffer.write('PW[${_escape(info.whiteName)}]');
    }
    if (info.blackRank != null) {
      buffer.write('BR[${_escape(info.blackRank!)}]');
    }
    if (info.whiteRank != null) {
      buffer.write('WR[${_escape(info.whiteRank!)}]');
    }
    if (info.date != null) {
      buffer.write('DT[${_escape(info.date!)}]');
    }
    if (info.result != null) {
      buffer.write('RE[${_escape(info.result!)}]');
    }
    if (info.komi.isNotEmpty) {
      buffer.write('KM[${_escape(info.komi)}]');
    }
    if (info.rules.isNotEmpty) {
      buffer.write('RU[${_escape(info.rules)}]');
    }
    if (info.event != null) {
      buffer.write('EV[${_escape(info.event!)}]');
    }
    if (info.baseTime != null) {
      buffer.write('TM[${_escape(info.baseTime!)}]');
    }
    if (info.overtime != null) {
      buffer.write('OT[${_escape(info.overtime!)}]');
    }

    // The root node can also have annotations, comments, setup stones, etc.
    _writeNodeProperties(session.rootNode, buffer);

    // Write all children
    _writeChildren(session, session.rootNode, buffer);

    buffer.write(')');
    return buffer.toString();
  }

  static void _writeChildren(GameSession session, TreeNode node, StringBuffer buffer) {
    if (node.childIds.isEmpty) return;

    if (node.childIds.length == 1) {
      // Single variation: just continue normally with a new node delimiter
      buffer.write('\n;');
      _writeNode(session, session.nodes[node.childIds.first]!, buffer);
    } else {
      // Multiple variations: wrap each in parentheses
      for (var childId in node.childIds) {
        buffer.write('\n(;');
        _writeNode(session, session.nodes[childId]!, buffer);
        buffer.write(')');
      }
    }
  }

  static void _writeNode(GameSession session, TreeNode node, StringBuffer buffer) {
    _writeNodeProperties(node, buffer);
    _writeChildren(session, node, buffer);
  }

  static void _writeNodeProperties(TreeNode node, StringBuffer buffer) {
    // 1. Core Move
    if (node.move != null) {
      if (node.move is Play) {
        final play = node.move as Play;
        final color = play.playerId == 1 ? 'B' : 'W';
        buffer.write('$color[${_indexToSgfCoord(play.x, play.y)}]');
      } else if (node.move is Pass) {
        final pass = node.move as Pass;
        final color = pass.playerId == 1 ? 'B' : 'W';
        buffer.write(
          '$color[]',
        ); // Pass is represented as empty brackets in modern SGF
      }
    }

    // 2. Setup Stones
    if (node.setupBlackStones.isNotEmpty) {
      buffer.write('AB');
      for (var idx in node.setupBlackStones) {
        buffer.write('[${_idxToSgfCoord(idx)}]');
      }
    }
    if (node.setupWhiteStones.isNotEmpty) {
      buffer.write('AW');
      for (var idx in node.setupWhiteStones) {
        buffer.write('[${_idxToSgfCoord(idx)}]');
      }
    }
    if (node.setupEmptyStones.isNotEmpty) {
      buffer.write('AE');
      for (var idx in node.setupEmptyStones) {
        buffer.write('[${_idxToSgfCoord(idx)}]');
      }
    }

    // 3. Markups
    if (node.triangleMarks.isNotEmpty) {
      buffer.write('TR');
      for (var idx in node.triangleMarks) {
        buffer.write('[${_idxToSgfCoord(idx)}]');
      }
    }
    if (node.squareMarks.isNotEmpty) {
      buffer.write('SQ');
      for (var idx in node.squareMarks) {
        buffer.write('[${_idxToSgfCoord(idx)}]');
      }
    }
    if (node.circleMarks.isNotEmpty) {
      buffer.write('CR');
      for (var idx in node.circleMarks) {
        buffer.write('[${_idxToSgfCoord(idx)}]');
      }
    }
    if (node.crossMarks.isNotEmpty) {
      buffer.write('MA');
      for (var idx in node.crossMarks) {
        buffer.write('[${_idxToSgfCoord(idx)}]');
      }
    }
    if (node.labels.isNotEmpty) {
      buffer.write('LB');
      node.labels.forEach((idx, text) {
        buffer.write('[${_idxToSgfCoord(idx)}:${_escape(text)}]');
      });
    }

    // 4. Time
    if (node.timeLeft[0] != null) {
      buffer.write('BL[${_escape(node.timeLeft[0]!)}]');
    }
    if (node.timeLeft[1] != null) {
      buffer.write('WL[${_escape(node.timeLeft[1]!)}]');
    }

    // 5. Metadata/Comments
    if (node.playerToPlay != null) {
      buffer.write('PL[${node.playerToPlay == 1 ? 'B' : 'W'}]');
    }
    if (node.nodeName != null && node.nodeName!.isNotEmpty) {
      buffer.write('N[${_escape(node.nodeName!)}]');
    }
    if (node.comment.isNotEmpty) {
      buffer.write('C[${_escape(node.comment)}]');
    }
  }

  static String _idxToSgfCoord(int index, {int columns = 19}) {
    int x = index % columns;
    int y = index ~/ columns;
    return _indexToSgfCoord(x, y);
  }

  static String _indexToSgfCoord(int x, int y) {
    final charX = String.fromCharCode(x + 97);
    final charY = String.fromCharCode(y + 97);
    return '$charX$charY';
  }

  static String _escape(String input) {
    // SGF requires escaping ']' and '\'
    return input.replaceAll('\\', '\\\\').replaceAll(']', '\\]');
  }
}
