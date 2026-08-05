import 'package:flutter/material.dart';
import 'models/board.dart';
import 'models/move.dart';
import 'ui/board_widget.dart';

void main() {
  runApp(const GoReviewApp());
}

class GoReviewApp extends StatelessWidget {
  const GoReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoReview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Board _board = Board(); // Default 19x19

  @override
  void initState() {
    super.initState();
    // Place some test stones to verify rendering!
    _board.play(const Point(3, 3)); // Player 1 (Black)
    _board.play(const Point(15, 3)); // Player 2 (White)
    _board.play(const Point(15, 15)); // Player 1 (Black)
    _board.play(const Point(3, 15)); // Player 2 (White)
    _board.play(const Point(15, 16)); // Player 1 (Black)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoReview'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(child: BoardWidget(board: _board)),
    );
  }
}
