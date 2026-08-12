import 'dart:typed_data';
import '../models/tree.dart';
import '../models/move.dart';

class MoveOption {
  final int moveIndex;
  final double winrate;
  final double scoreLead;
  final int visits;
  final List<int> pvIndices;

  MoveOption({
    required this.moveIndex,
    required this.winrate,
    required this.scoreLead,
    required this.visits,
    required this.pvIndices,
  });
}

class EngineResponse {
  final int queryId;
  final double rootWinrate;
  final double rootScoreLead;
  final List<MoveOption> moveOptions;

  EngineResponse({
    required this.queryId,
    required this.rootWinrate,
    required this.rootScoreLead,
    required this.moveOptions,
  });
}

class BinaryProtocol {
  /// Encodes a GameSession path into a tight binary array for the Go server
  static Uint8List encodeAnalyzeRequest(int queryId, GameSession session) {
    BytesBuilder builder = BytesBuilder();

    // 0x00 OpCode (0x01 = Analyze Request)
    builder.addByte(0x01);

    // 0x01 Query ID (uint16)
    var buf16 = ByteData(2);
    buf16.setUint16(0, queryId, Endian.big);
    builder.add(buf16.buffer.asUint8List());

    // 0x03 Board Size (uint8)
    builder.addByte(session.currentBoard.columns);

    // 0x04 Rules (uint8) - 0 = Japanese
    builder.addByte(0);

    // 0x05 Komi (uint8) - (e.g. 6.5 -> 65)
    double komiVal = double.tryParse(session.info.komi) ?? 6.5;
    builder.addByte((komiVal * 10).toInt());

    // 0x06 Setup Count (uint16)
    int setupCount =
        session.rootNode.setupBlackStones.length +
        session.rootNode.setupWhiteStones.length;
    buf16.setUint16(0, setupCount, Endian.big);
    builder.add(buf16.buffer.asUint8List());

    // Setup Stones Data
    for (int index in session.rootNode.setupBlackStones) {
      builder.addByte(0); // 0 = Black
      buf16.setUint16(0, index, Endian.big);
      builder.add(buf16.buffer.asUint8List());
    }
    for (int index in session.rootNode.setupWhiteStones) {
      builder.addByte(1); // 1 = White
      buf16.setUint16(0, index, Endian.big);
      builder.add(buf16.buffer.asUint8List());
    }

    // Traverse the path to get the move history
    List<Move> path = [];
    TreeNode? curr = session.currentNode;
    while (curr != null) {
      if (curr.move != null) path.insert(0, curr.move!);
      curr = curr.parent;
    }

    // Move Count (uint16)
    buf16.setUint16(0, path.length, Endian.big);
    builder.add(buf16.buffer.asUint8List());

    // Moves Data
    for (Move m in path) {
      int playerByte = (m.playerId == 1) ? 0 : 1; // 1=Black->0, 2=White->1
      builder.addByte(playerByte);

      if (m is Pass) {
        buf16.setUint16(0, 0xFFFF, Endian.big); // 0xFFFF = Pass
      } else if (m is Play) {
        int index = m.x + (m.y * session.currentBoard.columns);
        buf16.setUint16(0, index, Endian.big);
      }
      builder.add(buf16.buffer.asUint8List());
    }

    return builder.toBytes();
  }

  /// Decodes the ultra-tight binary response back into Dart objects
  static EngineResponse? decodeAnalyzeResponse(Uint8List payload) {
    if (payload.isEmpty || payload[0] != 0x02) return null;

    ByteData view = ByteData.sublistView(payload);
    int offset = 1;

    // 0x01 Query ID (uint16)
    int queryId = view.getUint16(offset, Endian.big);
    offset += 2;

    // 0x03 Winrate (uint16)
    double rootWinrate = view.getUint16(offset, Endian.big) / 1000.0;
    offset += 2;

    // 0x05 ScoreLead (int16)
    double rootScoreLead = view.getInt16(offset, Endian.big) / 10.0;
    offset += 2;

    // 0x07 Move Options count (uint8)
    int optionsCount = view.getUint8(offset);
    offset += 1;

    List<MoveOption> options = [];

    // Move Blocks
    for (int i = 0; i < optionsCount; i++) {
      int moveIndex = view.getUint16(offset, Endian.big);
      offset += 2;

      double moveWinrate = view.getUint16(offset, Endian.big) / 1000.0;
      offset += 2;

      double moveScoreLead = view.getInt16(offset, Endian.big) / 10.0;
      offset += 2;

      int visits = view.getUint32(offset, Endian.big);
      offset += 4;

      int pvLen = view.getUint8(offset);
      offset += 1;

      List<int> pvIndices = [];
      for (int j = 0; j < pvLen; j++) {
        pvIndices.add(view.getUint16(offset, Endian.big));
        offset += 2;
      }

      options.add(
        MoveOption(
          moveIndex: moveIndex,
          winrate: moveWinrate,
          scoreLead: moveScoreLead,
          visits: visits,
          pvIndices: pvIndices,
        ),
      );
    }

    return EngineResponse(
      queryId: queryId,
      rootWinrate: rootWinrate,
      rootScoreLead: rootScoreLead,
      moveOptions: options,
    );
  }
}
