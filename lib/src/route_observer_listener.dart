import 'package:flutter/widgets.dart';
import 'package:route_flutter_bloc/src/route_navigation_blocker.dart';
import 'package:route_flutter_bloc/src/route_observer_provider.dart';

/// A widget that hooks into [RouteObserver] and triggers route lifecycle callbacks.
///
/// Use this when you need to respond to navigator events (e.g. didPopNext, didPush)
/// without relying on any BLoC or state management.
///
/// Example:
/// ```dart
/// RouteObserverListener(
///   didPopNext: () => print('Returned to this route'),
///   child: MyPage(),
/// )
/// ```
class RouteObserverListener extends StatefulWidget {

  /// The widget below this listener in the widget tree.
  ///
  /// Typically the UI that reacts to state changes or builds
  /// child widgets that may depend on them.
  final Widget child;

  /// Optional [RouteObserver] for listening to route changes.
  ///
  /// If not provided, will be resolved via [RouteObserverProvider].
  final RouteObserver<Route<dynamic>>? observer;

  /// Called when the current route has been pushed onto the navigator.
  ///
  /// This is equivalent to `RouteAware.didPush`. Useful for triggering side effects
  /// when the screen becomes visible for the first time.
  final VoidCallback? didPush;

  /// Called when a new route has been pushed on top of the current one.
  ///
  /// This is equivalent to `RouteAware.didPushNext`. Useful for pausing or hiding
  /// UI elements when the current screen is no longer on top.
  final VoidCallback? didPushNext;

  /// Called when the current route has been popped and removed from the navigator.
  ///
  /// This is equivalent to `RouteAware.didPop`. Useful for cleanup or analytics.
  final VoidCallback? didPop;

  /// Called when a top route has been popped and the current route is again visible.
  ///
  /// This is equivalent to `RouteAware.didPopNext`. Useful for resuming listeners,
  /// refreshing UI, or processing deferred state updates.
  final VoidCallback? didPopNext;
  const RouteObserverListener({
    Key? key,
    required this.child,
    this.observer,
    this.didPush,
    this.didPushNext,
    this.didPop,
    this.didPopNext,
  }) : super(key: key);

  @override
  State<RouteObserverListener> createState() => _RouteObserverListenerState();
}

class _RouteObserverListenerState extends State<RouteObserverListener>
    with RouteAware {
  RouteObserver<Route<dynamic>>? _observer;
  String? _routeName;
  late final String? Function(String? route) _selfTriggerCallback;
  RouteNavigationBlocker? _blocker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route is! PageRoute) return;

      _observer = widget.observer ??
          RouteObserverProvider.of(context,
              widgetName: 'RouteObserverListener');

      _observer?.subscribe(this, route);
      _routeName = route.settings.name;

      _blocker = RouteObserverProvider.blockerOf(context);
      _selfTriggerCallback = (String? incomingRoute) {
        final allowTrigger = incomingRoute == _routeName;
        if (widget.didPopNext != null && allowTrigger) {
          widget.didPopNext!();
        }
        return _routeName;
      };
      _blocker?.addTriggerCallback(_selfTriggerCallback);
    });
  }

  @override
  void didUpdateWidget(RouteObserverListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldObserver = oldWidget.observer ??
        RouteObserverProvider.of(context, widgetName: 'RouteObserverListener');
    final currentObserver = widget.observer ?? oldObserver;
    if (oldObserver != currentObserver) {
      _observer = currentObserver;
    }
  }

  @override
  void dispose() {
    _observer?.unsubscribe(this);
    _blocker?.removeTriggerCallback(_selfTriggerCallback);
    super.dispose();
  }

  @override
  void didPush() {
    widget.didPush?.call();
  }

  @override
  void didPushNext() {
    widget.didPushNext?.call();
  }

  @override
  void didPop() {
    widget.didPop?.call();
  }

  @override
  void didPopNext() {
    final allowTrigger =
        RouteObserverProvider.blockerOf(context)?.isAllowed ?? true;
    if (widget.didPopNext != null && allowTrigger) {
      widget.didPopNext!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
