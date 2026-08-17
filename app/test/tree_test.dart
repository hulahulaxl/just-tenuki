import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_tenuki/models/tree.dart';
import 'package:just_tenuki/models/move.dart';

void main() {
  test('Serialize and deserialize', () {
    var session = GameSession();
    session.play(10, 10);
    session.play(11, 11);

    var jsonMap = session.toJson();
    // Simulate Hive roundtrip
    var jsonString = jsonEncode(jsonMap);
    var hiveMap = jsonDecode(jsonString) as Map<dynamic, dynamic>;

    var loadedSession = GameSession.fromJson(hiveMap);
    expect(loadedSession.currentNode.move is Play, isTrue);
  });
}
