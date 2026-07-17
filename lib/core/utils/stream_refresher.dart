import 'dart:async';

class AppEvents {
  static final StreamController<void> postRefreshController =
      StreamController.broadcast();
}
