import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(TypingSpeedApp());

class TypingSpeedApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TypeRush — Typing Speed Tester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: TypingScreen(),
    );
  }
}

class TypingScreen extends StatefulWidget {
  @override
  _TypingScreenState createState() => _TypingScreenState();
}

class _TypingScreenState extends State<TypingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  // sample text pool
  final List<String> _passages = [
    "Speed comes from practice. Keep your eyes on the screen and your fingers on the keys.",
    "Good typing blends rhythm and accuracy. Focus and flow will increase your WPM quickly.",
    "Small, consistent daily practice is the key to mastery. Try short bursts and measure progress.",
    "Programming needs clear thinking and confident typing. Build both by deliberate practice."
  ];

  late String targetText;
  int totalTime = 60; // seconds
  int remaining = 60;
  Timer? _timer;
  bool running = false;
  int correctChars = 0;
  int totalTyped = 0;
  int elapsed = 0;

  // glow animation
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _resetTest();
    _glowController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
      lowerBound: 0.85,
      upperBound: 1.15,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (running) return;
    setState(() {
      running = true;
      remaining = totalTime;
      elapsed = 0;
      correctChars = 0;
      totalTyped = 0;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (remaining > 0) {
        setState(() {
          remaining--;
          elapsed++;
        });
      } else {
        t.cancel();
        setState(() {
          running = false;
          _focus.unfocus();
        });
      }
    });
  }

  void _resetTest() {
    _controller.clear();
    targetText = _passages[Random().nextInt(_passages.length)];
    _timer?.cancel();
    running = false;
    remaining = totalTime;
    elapsed = 0;
    correctChars = 0;
    totalTyped = 0;
    setState(() {});
  }

  void _onTextChanged(String v) {
    if (!running && v.isNotEmpty) _startTimer();

    totalTyped = v.length;
    int correct = 0;
    for (int i = 0; i < v.length && i < targetText.length; i++) {
      if (v[i] == targetText[i]) correct++;
    }
    correctChars = correct;
    setState(() {});
    // stop early if user finishes text
    if (v == targetText) {
      _timer?.cancel();
      running = false;
      _focus.unfocus();
    }
  }

  double _wpm() {
    if (elapsed == 0) return 0;
    // standard: 5 chars = 1 word
    double words = totalTyped / 5;
    double minutes = elapsed / 60;
    return minutes == 0 ? 0 : words / minutes;
  }

  double _accuracy() {
    return totalTyped == 0 ? 0 : (correctChars / totalTyped) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(0xFF00FFA3); // neon green
    final glow = Color(0xFF00FFA3).withOpacity(0.12);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 22),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  ScaleTransition(
                    scale: _glowController,
                    child: _NeonBadge(accent: accent),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TypeRush",
                          style: TextStyle(
                              color: accent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text("Typing Speed Tester",
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  Spacer(),
                  _StatChip(label: "WPM", value: _wpm().toInt().toString()),
                  SizedBox(width: 8),
                  _StatChip(
                      label: "Acc", value: "${_accuracy().toStringAsFixed(0)}%"),
                ],
              ),

              SizedBox(height: 20),

              // neon card with passage
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: accent.withOpacity(0.18), width: 1.1),
                    boxShadow: [
                      BoxShadow(
                          color: glow, blurRadius: 30, spreadRadius: 1),
                      BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          offset: Offset(0, 8),
                          blurRadius: 20)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Type the text below as quickly and accurately as you can:",
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: RichText(
                            text: TextSpan(
                              children: _buildHighlightedText(),
                              style: TextStyle(fontSize: 18, height: 1.5),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),

                      // neon progress + timer
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: 1 - remaining / totalTime,
                              minHeight: 6,
                              backgroundColor: Colors.white10,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                          SizedBox(width: 14),
                          _TimePill(remaining: remaining, accent: accent),
                        ],
                      ),

                      SizedBox(height: 12),

                      // input field
                      TextField(
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: _onTextChanged,
                        enabled: remaining > 0,
                        maxLines: 3,
                        style: TextStyle(color: Colors.white70),
                        decoration: InputDecoration(
                          hintText: running
                              ? "Keep typing..."
                              : "Start typing to begin test",
                          hintStyle: TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: Colors.black,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      // actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (!running) {
                                  _controller.clear();
                                  _startTimer();
                                  _focus.requestFocus();
                                }
                              },
                              icon: Icon(Icons.play_arrow),
                              label: Text("Start"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 8,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _resetTest,
                              child: Icon(Icons.refresh),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white10,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),

              SizedBox(height: 18),

              // results summary
              _ResultBar(
                wpm: _wpm(),
                accuracy: _accuracy(),
                typed: totalTyped,
                correct: correctChars,
                accent: accent,
              ),
              SizedBox(height: 6),
              Text(
                "Tip: 5 characters = 1 word standard. Practice daily to improve!",
                style: TextStyle(color: Colors.white24, fontSize: 12),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText() {
    final input = _controller.text;
    List<TextSpan> spans = [];
    for (int i = 0; i < targetText.length; i++) {
      final char = targetText[i];
      Color c = Colors.white54;
      if (i < input.length) {
        if (input[i] == char) {
          c = Color(0xFF00FFA3); // correct neon
        } else {
          c = Colors.redAccent;
        }
      }
      spans.add(TextSpan(text: char, style: TextStyle(color: c)));
    }
    return spans;
  }
}

class _NeonBadge extends StatelessWidget {
  final Color accent;
  const _NeonBadge({required this.accent});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent, Colors.cyanAccent]),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.35), blurRadius: 28, spreadRadius: 1),
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12, offset: Offset(0,6))
        ],
      ),
      child: Center(
        child: Icon(Icons.flash_on, color: Colors.black, size: 26),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final int remaining;
  final Color accent;
  const _TimePill({required this.remaining, required this.accent});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, size: 18, color: accent),
          SizedBox(width: 6),
          Text("$remaining s",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 10)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  final double wpm;
  final double accuracy;
  final int typed;
  final int correct;
  final Color accent;
  const _ResultBar({
    required this.wpm,
    required this.accuracy,
    required this.typed,
    required this.correct,
    required this.accent,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _smallStat("WPM", wpm.toInt().toString(), accent),
          SizedBox(width: 12),
          _smallStat("Acc", "${accuracy.toStringAsFixed(0)}%", accent),
          SizedBox(width: 12),
          _smallStat("Typed", typed.toString(), accent),
          SizedBox(width: 12),
          _smallStat("Correct", correct.toString(), accent),
        ],
      ),
    );
  }

  Widget _smallStat(String label, String value, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 12)),
        SizedBox(height: 6),
        Text(value, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
