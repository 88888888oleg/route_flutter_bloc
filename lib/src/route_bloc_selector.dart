import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:route_flutter_bloc/route_flutter_bloc.dart';
import 'package:route_flutter_bloc/src/route_bloc_listener.dart';
import 'package:route_flutter_bloc/src/route_observer_provider.dart';

/// {@template route_bloc_widget_selector}
/// Signature for a function that selects a value of type [T] from a BLoC state [S].
///
/// Used to determine whether a rebuild should occur based on changes
/// to the selected value.
///
/// Example:
/// ```dart
/// (MyState state) => state.title;
/// ```
/// {@endtemplate}
typedef RouteBlocWidgetSelector<S, T> = T Function(S state);

/// {@template route_bloc_selector}
/// [RouteBlocSelector] is a widget that allows you to listen to a specific part
/// of a BLoC state and rebuild only when that selected part changes,
/// with added support for route lifecycle awareness via [RouteObserver].
///
/// This is useful when you want to optimize widget rebuilding based on a
/// derived value from the state rather than the full state object.
///
/// Similar to [BlocSelector], but with route-awareness, making it ideal
/// for apps where you want to defer UI updates until the route becomes active again.
///
/// Example usage:
///
/// ```dart
/// RouteBlocSelector<MyBloc, MyState, String>(
///   observer: routeObserver,
///   selector: (state) => state.title,
///   builder: (context, title) {
///     return Text(title);
///   },
/// )
/// ```
///
/// If [bloc] is not provided, it will be inferred from the context via [BlocProvider].
///
/// Set [rebuildOnResume] to `true` if you want to apply deferred updates when
/// the route becomes visible again.
/// {@endtemplate}
class RouteBlocSelector<B extends StateStreamable<S>, S, T>
    extends StatefulWidget {
  /// {@macro route_bloc_selector}
  const RouteBlocSelector({
    required this.selector,
    required this.builder,
    this.observer,
    this.bloc,
    this.rebuildOnResume = false,
    this.forceClassicSelector = false,
    Key? key,
  }) : super(key: key);

  /// Optional [RouteObserver] for listening to route changes.
  ///
  /// If not provided, will be resolved via [RouteObserverProvider].
  final RouteObserver<Route<dynamic>>? observer;

  /// The BLoC instance to subscribe to.
  ///
  /// If not provided, it will be resolved using [BlocProvider.of].
  final B? bloc;

  /// The [selector] function which will be invoked on each widget build
  /// and is responsible for returning a selected value of type [T] based on
  /// the current state.
  final RouteBlocWidgetSelector<S, T> selector;

  /// The [builder] function which will be invoked
  /// when the selected state changes.
  /// The [builder] takes the [BuildContext] and selected `state` and
  /// must return a widget.
  /// This is analogous to the [builder] function in [BlocBuilder].
  final RouteBlocWidgetBuilder<T> builder;

  /// Whether to rebuild the widget when the current route resumes.
  final bool rebuildOnResume;

  /// If `true`, the route lifecycle is ignored, and RouteBlocSelector behaves like standard [BlocSelector].
  ///
  /// This disables [RouteObserver]-based behavior.
  final bool forceClassicSelector;

  @override
  State<RouteBlocSelector<B, S, T>> createState() =>
      _RouteBlocSelectorState<B, S, T>();
}

class _RouteBlocSelectorState<B extends StateStreamable<S>, S, T>
    extends State<RouteBlocSelector<B, S, T>> with RouteAware {
  late B _bloc;
  late T _selectedState;
  late RouteObserver<Route<dynamic>> _observer;
  bool _isActiveRoute = true;
  T? _deferredSelected;

  @override
  void initState() {
    super.initState();
    _observer = widget.observer ??
        RouteObserverProvider.of(context, widgetName: 'RouteBlocSelector');
    _bloc = widget.bloc ?? context.read<B>();
    _selectedState = widget.selector(_bloc.state);
    _subscribe();
  }

  @override
  void didUpdateWidget(RouteBlocSelector<B, S, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<B>();
    final currentBloc = widget.bloc ?? oldBloc;

    if (oldBloc != currentBloc) {
      _unsubscribe();
      _bloc = currentBloc;
      _selectedState = widget.selector(_bloc.state);
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      _observer.subscribe(this, route);
    }

    final bloc = widget.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      _unsubscribe();
      _bloc = bloc;
      _selectedState = widget.selector(_bloc.state);
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    _observer.unsubscribe(this);
    super.dispose();
  }

  void _subscribe() {
    _bloc.stream.listen((state) {
      final selected = widget.selector(state);
      if (_selectedState == selected) return;

      if (_isActiveRoute) {
        setState(() => _selectedState = selected);
      } else if (widget.rebuildOnResume) {
        _deferredSelected = selected;
      }
    });
  }

  void _unsubscribe() {
    // no-op if we're using listen()
    // could be converted to StreamSubscription if stronger control is needed
  }

  void _applyDeferred() {
    if (_deferredSelected != null) {
      setState(() {
        _selectedState = _deferredSelected!;
        _deferredSelected = null;
      });
    }
  }

  @override
  void didPush() {
    _isActiveRoute = true;
    _applyDeferred();
  }

  @override
  void didPopNext() {
    _isActiveRoute = true;
    _applyDeferred();
  }

  @override
  void didPushNext() {
    _isActiveRoute = false;
  }

  @override
  void didPop() {
    _isActiveRoute = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bloc == null) {
      context.select<B, bool>((bloc) => identical(_bloc, bloc));
    }

    return RouteBlocListener<B, S>(
      bloc: _bloc,
      observer: _observer,
      triggerOnResumed: widget.rebuildOnResume,
      forceClassicListener: widget.forceClassicSelector,
      listenWhen: (prev, curr) {
        final prevSelected = widget.selector(prev);
        final currSelected = widget.selector(curr);
        return prevSelected != currSelected;
      },
      listener: (context, state) {
        final selected = widget.selector(state);
        setState(() => _selectedState = selected);
      },
      child: widget.builder(context, _selectedState),
    );
  }
}
