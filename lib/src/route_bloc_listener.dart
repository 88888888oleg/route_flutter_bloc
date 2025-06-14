import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:route_flutter_bloc/src/route_observer_provider.dart';
import 'package:provider/single_child_widget.dart';

/// Signature for the `listener` function which takes the `BuildContext` along
/// with the `state` and is responsible for executing in response to
/// `state` changes.
typedef BlocWidgetListener<S> = void Function(BuildContext context, S state);

/// Signature for the `listenWhen` function which takes the previous `state`
/// and the current `state` and is responsible for returning a [bool] which
/// determines whether or not to call [BlocWidgetListener] of [BlocListener]
/// with the current `state`.
typedef BlocListenerCondition<S> = bool Function(S previous, S current);

/// {@template route_bloc_listener}
/// `RouteBlocListener` is a widget that listens to state changes in a given [bloc]
/// **only when the current [Route] is active**. It integrates with [RouteObserver]
/// to determine whether the screen is currently visible.
///
/// It is typically used for executing side effects such as showing snack bars,
/// dialogs, or triggering navigation in response to state changes.
///
/// By default, the [listener] will only be called if the route is visible (on top).
/// This behavior can be customized using the following flags:
///
/// - Set [forceClassicListener] to `true` to disable route awareness and behave
///   like a classic `BlocListener`, reacting to all state changes regardless of route visibility.
///
/// - Set [triggerOnResumed] to `true` to defer listener calls until the route becomes active again,
///   which is useful if you want to handle state updates that occurred while the screen was inactive.
///
/// ### Example:
/// ```dart
/// RouteBlocListener<MyBloc, MyState>(
///   listener: (context, state) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('State changed: $state')),
///     );
///   },
///   triggerOnResumed: true,
///   child: MyWidget(),
/// )
/// ```
///
/// If [bloc] is not provided, it will be retrieved from the nearest [BlocProvider] ancestor.
///
/// You can use [listenWhen] to control which state changes should trigger the [listener].
///
/// {@endtemplate}
class RouteBlocListener<B extends StateStreamable<S>, S>
    extends RouteBlocListenerBase<B, S> {
  /// {@macro route_bloc_listener}
  const RouteBlocListener({
    required BlocWidgetListener<S> listener,
    Key? key,
    B? bloc,
    BlocListenerCondition<S>? listenWhen,
    Widget? child,
    RouteObserver<Route<dynamic>>? observer,
    bool triggerOnResumed = false,
    bool forceClassicListener = false,
    VoidCallback? didPush,
    VoidCallback? didPushNext,
    VoidCallback? didPop,
    VoidCallback? didPopNext,
  }) : super(
          key: key,
          bloc: bloc,
          child: child,
          listener: listener,
          listenWhen: listenWhen,
          observer: observer,
          triggerOnResumed: triggerOnResumed,
          forceClassicListener: forceClassicListener,
          didPush: didPush,
          didPushNext: didPushNext,
          didPop: didPop,
          didPopNext: didPopNext,
        );

  @override
  State<RouteBlocListenerBase<B, S>> createState() =>
      _RouteBlocListenerState<B, S>();
}

/// {@template route_bloc_listener_base}
/// Base class for widgets that listen to BLoC state changes
/// and are aware of route lifecycle via [RouteObserver].
///
/// This class should not be used directly. Use [RouteBlocListener] instead.
/// {@endtemplate}
abstract class RouteBlocListenerBase<B extends StateStreamable<S>, S>
    extends SingleChildStatefulWidget {
  /// {@macro route_bloc_listener_base}
  const RouteBlocListenerBase({
    required this.listener,
    Key? key,
    this.bloc,
    this.child,
    this.listenWhen,
    this.observer,
    this.triggerOnResumed = false,
    this.forceClassicListener = false,
    this.didPush,
    this.didPushNext,
    this.didPop,
    this.didPopNext,
  }) : super(key: key, child: child);

  /// The widget below this listener in the widget tree.
  ///
  /// Typically the UI that reacts to state changes or builds
  /// child widgets that may depend on them.
  final Widget? child;

  /// The BLoC instance to subscribe to.
  ///
  /// If not provided, it will be resolved using [BlocProvider.of].
  final B? bloc;

  /// Callback that is invoked in response to every new state.
  ///
  /// Called only when the route is active (or immediately if [forceClassicListener] is `true`).
  final BlocWidgetListener<S> listener;

  /// Optional callback to determine whether [listener] should be triggered.
  ///
  /// Receives the previous and current states and must return `true` to allow [listener] execution.
  /// Defaults to always returning `true`.
  final BlocListenerCondition<S>? listenWhen;

  /// Optional [RouteObserver] for listening to route changes.
  ///
  /// If not provided, will be resolved via [RouteObserverProvider].
  final RouteObserver<Route<dynamic>>? observer;

  /// If `true`, the listener will fire with the last state
  /// when the route becomes visible again (e.g., popped back to).
  ///
  /// Useful for re-firing missed effects.
  final bool triggerOnResumed;

  /// If `true`, the route lifecycle is ignored, and listener behaves like standard [BlocListener].
  ///
  /// This disables [RouteObserver]-based behavior.
  final bool forceClassicListener;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<B?>('bloc', bloc))
      ..add(ObjectFlagProperty<BlocWidgetListener<S>>.has('listener', listener))
      ..add(ObjectFlagProperty<BlocListenerCondition<S>?>.has(
          'listenWhen', listenWhen))
      ..add(FlagProperty('triggerOnResumed',
          value: triggerOnResumed, ifTrue: 'deferred mode'))
      ..add(FlagProperty('forceClassicListener',
          value: forceClassicListener, ifTrue: 'classic mode'))
      ..add(DiagnosticsProperty<RouteObserver<Route<dynamic>>>(
          'observer', observer));
  }
}

class _RouteBlocListenerState<B extends StateStreamable<S>, S>
    extends SingleChildState<RouteBlocListenerBase<B, S>> with RouteAware {
  StreamSubscription<S>? _subscription;
  late B _bloc;
  late S _previousState;
  RouteObserver<Route<dynamic>>? _observer;
  S? _deferredState;
  bool _isActiveRoute = true;
  String? _routeName;
  late final String? Function(String? route) _selfTriggerCallback;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _previousState = _bloc.state;
    if (!widget.forceClassicListener) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!widget.forceClassicListener) {
          _observer = widget.observer ??
              RouteObserverProvider.of(context,
                  widgetName: 'RouteBlocListener');

          final route = ModalRoute.of(context);
          if (route is PageRoute) {
            _observer?.subscribe(this, route);
          }

          _routeName = ModalRoute.of(context)?.settings.name;
          final blocker = RouteObserverProvider.blockerOf(context);

          _selfTriggerCallback = (String? incomingRoute) {
            final allowTrigger = incomingRoute == _routeName;
            _maybeDispatchDeferred(allowTrigger: allowTrigger);
            if (widget.didPopNext != null && allowTrigger) {
              widget.didPopNext!();
            }
            return _routeName;
          };

          blocker?.addTriggerCallback(_selfTriggerCallback);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentBloc = widget.bloc ?? context.read<B>();
    _unsubscribe();
    _bloc = currentBloc;
    _previousState = _bloc.state;
    _subscribe();
    final observer = widget.observer ??
        RouteObserverProvider.of(context, widgetName: 'RouteBlocListener');
    if (_observer != observer) {
      _observer = observer;
    }
  }

  @override
  void didUpdateWidget(RouteBlocListenerBase<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<B>();
    final newBloc = widget.bloc ?? oldBloc;

    if (oldBloc != newBloc) {
      _unsubscribe();
      _bloc = newBloc;
      _previousState = _bloc.state;
      _subscribe();
    }
    final oldObserver = oldWidget.observer ??
        RouteObserverProvider.of(context, widgetName: 'RouteBlocListener');
    final currentObserver = widget.observer ?? oldObserver;
    if (oldObserver != currentObserver) {
      _observer = currentObserver;
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    if (!widget.forceClassicListener) {
      _observer?.unsubscribe(this);
    }
    super.dispose();
  }

  void _subscribe() {
    _subscription = _bloc.stream.listen((state) {
      if (!mounted) return;

      final shouldNotify =
          widget.listenWhen?.call(_previousState, state) ?? true;

      if (widget.forceClassicListener || _isActiveRoute) {
        if (shouldNotify) {
          widget.listener(context, state);
        }
      } else if (widget.triggerOnResumed && shouldNotify) {
        _deferredState = state;
      }

      _previousState = state;
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _maybeDispatchDeferred({bool allowTrigger = true}) {
    if (_deferredState != null && allowTrigger) {
      final state = _deferredState!;
      _deferredState = null;
      widget.listener(context, state);
    }
  }

  @override
  void didPush() {
    _isActiveRoute = true;
    _maybeDispatchDeferred();
    if (widget.didPush != null) {
      widget.didPush!();
    }
  }

  @override
  void didPopNext() {
    _isActiveRoute = true;
    final allowTrigger =
        RouteObserverProvider.blockerOf(context)?.isAllowed ?? true;
    _maybeDispatchDeferred(allowTrigger: allowTrigger);
    if (widget.didPopNext != null && allowTrigger) {
      widget.didPopNext!();
    }
  }

  @override
  void didPushNext() {
    _isActiveRoute = false;
    if (widget.didPushNext != null) {
      widget.didPushNext!();
    }
  }

  @override
  void didPop() {
    _isActiveRoute = false;
    if (widget.didPop != null) {
      widget.didPop!();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '${widget.runtimeType} used outside of MultiBlocListener must specify a child',
    );
    if (widget.bloc == null) {
      context.select<B, bool>((bloc) => identical(_bloc, bloc));
    }
    return child!;
  }
}
