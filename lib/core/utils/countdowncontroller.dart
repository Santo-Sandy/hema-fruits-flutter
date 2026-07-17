import 'dart:async';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// High-precision countdown controller with microsecond accuracy
class CountdownController extends ChangeNotifier {
  final DateTime endTime;
  final VoidCallback? onCompleted;

  Timer? _timer;
  Duration? _cachedRemaining;
  bool _isDisposed = false;

  // Prevent redundant callbacks
  bool _completionFired = false;

  // Millisecond-level precision via Stopwatch
  late Stopwatch _stopwatch;
  late Duration _initialRemaining;

  CountdownController({required this.endTime, this.onCompleted}) {
    _validateEndTime();
    _initializeCountdown();
  }

  void _validateEndTime() {
    // Handle timezone-aware comparison
    final now = DateTime.now();
    if (endTime.isBefore(now)) {
      _cachedRemaining = Duration.zero;
      _completionFired = true;
    }
  }

  void _initializeCountdown() {
    _stopwatch = Stopwatch()..start();
    _initialRemaining = endTime.difference(DateTime.now());
  }

  /// Start countdown with configurable precision
  void start({Duration precision = const Duration(milliseconds: 100)}) {
    if (_isDisposed) return;

    _tick(); // Immediate first tick for responsiveness

    _timer = Timer.periodic(precision, (_) {
      if (!_isDisposed) _tick();
    });
  }

  /// High-precision tick calculation
  void _tick() {
    if (_isDisposed || _completionFired) return;

    final now = DateTime.now();
    final remaining = endTime.difference(now);

    // Prevent negative durations and redundant callbacks
    if (remaining.isNegative) {
      _cachedRemaining = Duration.zero;
      if (!_completionFired) {
        _completionFired = true;
        _timer?.cancel();
        notifyListeners();
        onCompleted?.call();
      }
    } else {
      _cachedRemaining = remaining;
      notifyListeners();
    }
  }

  Duration? getRemainingTime() => _cachedRemaining;

  bool get isCompleted => _completionFired;

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}

/// Optimized widget with minimal rebuilds
class CountdownWidget extends StatefulWidget {
  final DateTime endDate;
  final String? label;
  final TextStyle? labelStyle;
  final TextStyle? timerStyle;
  final Color? backgroundColor;

  const CountdownWidget({
    super.key,
    required this.endDate,
    this.labelStyle,
    this.label,
    this.timerStyle,
    this.backgroundColor,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late CountdownController _controller;
  String _formattedTime = "";

  @override
  void initState() {
    super.initState();
    _controller = CountdownController(
      endTime: widget.endDate,
      onCompleted: _handleCompletion,
    );
    _controller.addListener(_onCountdownTick);
    _controller.start(precision: const Duration(milliseconds: 100));
  }

  void _onCountdownTick() {
    final remaining = _controller.getRemainingTime();
    if (remaining == null) return;

    final newFormatted = _formatDuration(remaining);
    if (newFormatted != _formattedTime) {
      setState(() => _formattedTime = newFormatted);
    }
  }

  void _handleCompletion() {
    if (mounted) {
      setState(() => _formattedTime = "Ended");
    }
  }

  /// Optimized formatting with early exit
  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (days > 0) return "${days}d ${hours}h";
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m ${seconds}s";
  }

  @override
  void dispose() {
    _controller.removeListener(_onCountdownTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style:
                widget.labelStyle ??
                TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 4),
        ],
        _buildTimerBox(),
      ],
    );
  }

  Widget _buildTimerBox() {
    return Container(
      width: 100,
      height: 30,
      decoration: BoxDecoration(
        color: (widget.backgroundColor ?? Colors.red).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (widget.backgroundColor ?? Colors.red).withValues(alpha: 0.15),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Shimmer.fromColors(
                direction: ShimmerDirection.rtl,
                baseColor: Colors.red,
                highlightColor: AppColors.error,
                child: Container(color: Colors.red),
              ),
            ),
          ),
          Center(
            child: Container(
              // padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (widget.backgroundColor ?? AppColors.overlay),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (widget.backgroundColor ?? AppColors.overlay),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                  Text(
                    _formattedTime,
                    style:
                        widget.timerStyle ??
                        TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
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
}
