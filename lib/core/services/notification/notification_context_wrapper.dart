import 'package:flutter/material.dart';
import 'notification_handler.dart';

class NotificationContextWrapper extends StatefulWidget {
  final Widget child;

  const NotificationContextWrapper({super.key, required this.child});

  @override
  State<NotificationContextWrapper> createState() =>
      _NotificationContextWrapperState();
}

class _NotificationContextWrapperState
    extends State<NotificationContextWrapper> {
  @override
  void initState() {
    super.initState();
    // Set the context when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationHandler.setContext(context);
    });
  }

  @override
  void didUpdateWidget(NotificationContextWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update context if widget changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationHandler.setContext(context);
    });
  }

  @override
  void dispose() {
    NotificationHandler.clearContext();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
