import 'package:flutter/material.dart';

class ContextManager {
  static final ContextManager _instance = ContextManager._internal();

  factory ContextManager() {
    return _instance;
  }

  ContextManager._internal();

  BuildContext? _currentContext;
  String _currentPage = 'homepage';
  final Map<String, BuildContext> _screenContexts = {};

  /// Get the current global context
  BuildContext? get currentContext => _currentContext;

  /// Get the current page name
  String get currentPage => _currentPage;

  /// Set the current global context
  void setCurrentContext(BuildContext context) {
    _currentContext = context;
  }

  /// Save current page context
  void saveCurrentPage(String pageName, BuildContext context) {
    _currentPage = pageName;
    _currentContext = context;
    _screenContexts[pageName] = context;
  }

  /// Get current page name
  String getCurrentPage() => _currentPage;

  /// Save context for a specific screen
  void saveScreenContext(String screenName, BuildContext context) {
    _screenContexts[screenName] = context;
  }

  /// Get context for a specific screen
  BuildContext? getScreenContext(String screenName) {
    return _screenContexts[screenName];
  }

  /// Remove context for a specific screen
  void removeScreenContext(String screenName) {
    _screenContexts.remove(screenName);
  }

  /// Clear all saved contexts
  void clearAllContexts() {
    _currentContext = null;
    _currentPage = 'homepage';
    _screenContexts.clear();
  }

  /// Get all saved screen contexts
  Map<String, BuildContext> getAllScreenContexts() {
    return Map.unmodifiable(_screenContexts);
  }
}
