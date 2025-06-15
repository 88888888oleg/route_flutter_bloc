class RouteNavigationBlocker {
  bool _isBlocked = false;

  final List<String? Function(String? route)> _listeners = [];

  void addTriggerCallback(String? Function(String? route) callback) {
    _listeners.add(callback);
  }

  void removeTriggerCallback(String? Function(String? route) callback) {
    _listeners.remove(callback);
  }

  String? triggerListener(String? route) {
    for (var i = 0; i < _listeners.length; i++) {
      final value = _listeners[i](route);
      if (value != null) return value;
    }
    return null;
  }

  void lock() => _isBlocked = true;

  void unlock() => _isBlocked = false;

  bool get isAllowed => !_isBlocked;
}
