import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../core/controllers/assistant_providers.dart';
import '../core/models/chat_message_model.dart';
import 'chat_history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _statusLabel(AssistantStatus status) {
    switch (status) {
      case AssistantStatus.listening:
        return 'Listening...';
      case AssistantStatus.thinking:
        return 'Thinking...';
      case AssistantStatus.executing:
        return 'Executing...';
      case AssistantStatus.idle:
        return 'Tap to speak';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(assistantStatusProvider);
    final chatHistory = ref.watch(chatHistoryProvider);
    final assistantController = ref.watch(assistantControllerProvider);
    final lastMessage = chatHistory.isNotEmpty ? chatHistory.last : null;

    final isBusy = status != AssistantStatus.idle;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PraVIA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // The dynamic, multi-layered Jarvis Arc Reactor Core
            JarvisArcReactor(status: status),
            const SizedBox(height: 32),
            Text(
              _statusLabel(status),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            if (lastMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  lastMessage.role == ChatRole.user
                      ? '"${lastMessage.text}"'
                      : lastMessage.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: lastMessage.role == ChatRole.user
                        ? Colors.cyanAccent
                        : Colors.white,
                    fontSize: 15,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Spacer(flex: 3),
            GestureDetector(
              onTap: isBusy
                  ? null
                  : () => assistantController.handleVoiceCommand(),
              child: _MicButton(active: isBusy),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

/// The fully animated Iron Man / Jarvis Core replacement for the old avatar
class JarvisArcReactor extends StatefulWidget {
  final AssistantStatus status;
  const JarvisArcReactor({super.key, required this.status});

  @override
  State<JarvisArcReactor> createState() => _JarvisArcReactorState();
}

class _JarvisArcReactorState extends State<JarvisArcReactor> with TickerProviderStateMixin {
  late AnimationController _slowController;
  late AnimationController _fastController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _slowController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fastController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant JarvisArcReactor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dynamically adjust animation speed based on the Jarvis engine status
    if (widget.status == AssistantStatus.thinking) {
      _fastController.duration = const Duration(seconds: 2);
      _fastController.repeat();
    } else if (widget.status == AssistantStatus.executing) {
      _fastController.duration = const Duration(seconds: 4);
      _fastController.repeat();
    } else if (widget.status == AssistantStatus.listening) {
      _fastController.duration = const Duration(seconds: 3);
      _fastController.repeat();
    } else {
      _fastController.duration = const Duration(seconds: 8);
      _fastController.repeat();
    }
  }

  @override
  void dispose() {
    _slowController.dispose();
    _fastController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pick the color accent mapping out the current assistant state
    final Color engineColor = widget.status == AssistantStatus.idle
        ? Colors.blueGrey.withOpacity(0.6)
        : widget.status == AssistantStatus.thinking
        ? const Color(0xff00f2fe)
        : widget.status == AssistantStatus.executing
        ? const Color(0xffa8ff78) // Fresh sci-fi green for executing tasks
        : const Color(0xff4facfe); // Cinematic cyan for listening

    return AnimatedBuilder(
      animation: Listenable.merge([_slowController, _fastController, _pulseController]),
      builder: (context, child) {
        final double pulseVal = widget.status != AssistantStatus.idle ? _pulseController.value : 0.0;

        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: engineColor.withOpacity(0.15 * pulseVal),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Dash Ring (Slow Spin Clockwise)
              RotationTransition(
                turns: _slowController,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ReactorRingPainter(color: engineColor.withOpacity(0.3), dashCount: 24, strokeWidth: 1.5, radiusOffset: 5),
                ),
              ),

              // Intermediate Tech Ring (Fast Spin Counter-Clockwise)
              RotationTransition(
                turns: ReverseAnimation(_fastController),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ReactorRingPainter(color: engineColor.withOpacity(0.5), dashCount: 8, strokeWidth: 3, radiusOffset: 25),
                ),
              ),

              // Target / Core framing Crosshairs Ring (Slow Spin Clockwise)
              RotationTransition(
                turns: _slowController,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ReactorRingPainter(color: engineColor.withOpacity(0.7), dashCount: 4, strokeWidth: 1.5, radiusOffset: 45, gapSize: 0.4),
                ),
              ),

              // Dynamic Breathing Energy Center
              Container(
                width: 65 + (12 * pulseVal),
                height: 65 + (12 * pulseVal),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white, engineColor, Colors.transparent],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: engineColor.withOpacity(0.5),
                      blurRadius: 15 * pulseVal,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Icon(
                  widget.status == AssistantStatus.thinking
                      ? Icons.psychology
                      : widget.status == AssistantStatus.executing
                      ? Icons.code
                      : Icons.blur_on,
                  color: widget.status != AssistantStatus.idle ? Colors.white : Colors.white54,
                  size: 26,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom Segmented Arc Canvas Painter
class _ReactorRingPainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;
  final double radiusOffset;
  final double gapSize;

  _ReactorRingPainter({
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
    required this.radiusOffset,
    this.gapSize = 0.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - radiusOffset;

    final double arcLength = (2 * math.pi / dashCount) * (1 - gapSize);
    final double spaceLength = (2 * math.pi / dashCount) * gapSize;

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = i * (arcLength + spaceLength);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arcLength,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MicButton extends StatelessWidget {
  final bool active;
  const _MicButton({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.cyanAccent.withOpacity(0.15) : Colors.white10,
        border: Border.all(
          color: active ? Colors.cyanAccent : Colors.white24,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.mic,
        size: 36,
        color: active ? Colors.cyanAccent : Colors.white70,
      ),
    );
  }
}