import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class BiddingTimerCard extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback? onExpired;

  const BiddingTimerCard({
    super.key,
    required this.endTime,
    this.onExpired,
  });

  @override
  State<BiddingTimerCard> createState() => _BiddingTimerCardState();
}

class _BiddingTimerCardState extends State<BiddingTimerCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (widget.endTime.isBefore(now)) {
      setState(() {
        _remaining = Duration.zero;
      });
      _timer?.cancel();
      widget.onExpired?.call();
    } else {
      setState(() {
        _remaining = widget.endTime.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remaining.inMinutes < 15 && _remaining.inSeconds > 0;
    final isExpired = _remaining == Duration.zero;

    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    final color = isExpired
        ? Colors.grey
        : (isUrgent ? const Color(0xFFE53935) : AppColors.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired
                ? 'BID CLOSED'
                : 'ENDS IN $hours:$minutes:$seconds',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
