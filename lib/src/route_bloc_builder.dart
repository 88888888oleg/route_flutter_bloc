import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:route_flutter_bloc/src/route_bloc_listener.dart';
import 'package:route_flutter_bloc/src/route_observer_provider.dart';
import 'package:bloc/bloc.dart';

/// Signature for the `builder` function which takes the `BuildContext` and
/// current `state` and is responsible for returning a widget to render.
/// This is analogous to the `builder` function in [StreamBuilder].
typedef RouteBlocWidgetBuilder<S> = Widget Function(
    BuildContext context, S state);

/// Signature for the `buildWhen` function which takes the previous `state` and
/// the current `state` and returns a [bool] which determines whether to rebuild
/// the [RouteBlocBuilder] with the current `state`.
typedef RouteBlocBuilderCondition<S> = bool Function(S previous, S current);

/// {@template route_bloc_builder}
/// [RouteBlocBuilder] handles building a widget in response to new `states`
/// from the specified [bloc] and also listens to route changes via a
/// [RouteObserver].
///
/// [RouteBlocBuilder] is analogous to [BlocBuilder] but includes additional
/// behavior to rebuild when the current route resumes, which is useful when
/// the UI should reflect state changes that might have occurred while the
/// screen was inactive.
///
/// Please refer to [RouteBlocListener] if you want to react to route or state
/// changes without rebuilding the UI.
///
/// If the [bloc] parameter is omitted, [RouteBlocBuilder] will perform a
/// lookup using [BlocProvider] and the current [BuildContext].
///
/// ```dart
/// RouteBlocBuilder<MyBloc, MyState>(
///   observer: routeObserver,
///   builder: (context, state) {
///     // return widget based on MyBloc's state
///   }
/// )
/// ```
///
/// Only specify the [bloc] if you want to provide a [bloc] that is not
/// accessible via [BlocProvider] and the current context.
///
/// ```dart
/// RouteBlocBuilder<MyBloc, MyState>(
///   bloc: myBloc,
///   observer: routeObserver,
///   builder: (context, state) {
///     // return widget based on MyBloc's state
///   }
/// )
/// ```
/// {@endtemplate}
///
/// {@template route_bloc_builder_build_when}
/// An optional [buildWhen] can be implemented to control how often
/// [RouteBlocBuilder] rebuilds in response to `state` changes.
///
/// It is useful for performance optimizations. [buildWhen] will be invoked on
/// each state change. If it returns `true`, the [builder] function will be
/// called. If it returns `false`, the build will be skipped.
///
/// ```dart
/// RouteBlocBuilder<MyBloc, MyState>(
///   observer: routeObserver,
///   buildWhen: (previous, current) {
///     // return true/false based on custom logic
///   },
///   builder: (context, state) {
///     // return widget based on MyBloc's state
///   }
/// )
/// ```
/// {@endtemplate}
class RouteBlocBuilder<B extends StateStreamable<S>, S>
    extends RouteBlocBuilderBase<B, S> {
  /// {@macro route_bloc_builder}
  /// {@macro route_bloc_builder_build_when}
  RouteBlocBuilder({
    required this.builder,
    RouteObserver<Route<dynamic>>? observer,
    Key? key,
    B? bloc,
    RouteBlocBuilderCondition<S>? buildWhen,
    bool rebuildOnResume = false,
    bool forceClassicBuilder = false,
  }) : super(
          key: key,
          bloc: bloc,
          buildWhen: buildWhen,
          observer: observer,
          rebuildOnResume: rebuildOnResume,
          forceClassicBuilder: forceClassicBuilder,
        );

  /// The [builder] function which is invoked to render the widget
  /// in response to a new state.
  final RouteBlocWidgetBuilder<S> builder;

  @override
  Widget build(BuildContext context, S state) => builder(context, state);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<RouteBlocWidgetBuilder<S>>.has('builder', builder),
    );
  }
}

/// {@template route_bloc_builder_base}
/// Base class for widgets that rebuild in response to both BLoC state changes
/// and navigation (route) events.
///
/// [RouteBlocBuilderBase] is a stateful widget that integrates a
/// [RouteObserver] to listen for route lifecycle changes such as resume and
/// uses a [RouteBlocListener] to trigger rebuilds.
///
/// Subclasses should override [build] to define how the widget responds
/// to the current state.
/// {@endtemplate}
abstract class RouteBlocBuilderBase<B extends StateStreamable<S>, S>
    extends StatefulWidget {
  /// {@macro route_bloc_builder_base}
  const RouteBlocBuilderBase({
    this.observer,
    this.bloc,
    this.buildWhen,
    this.rebuildOnResume = false,
    this.forceClassicBuilder = false,
    Key? key,
  }) : super(key: key);

  /// The BLoC instance whose state changes the widget responds to.
  /// If not provided, it will be inferred from the current [BuildContext].
  final B? bloc;

  /// RouteObserver
  final RouteObserver<Route<dynamic>>? observer;

  /// {@macro route_bloc_builder_build_when}
  final RouteBlocBuilderCondition<S>? buildWhen;

  /// Whether to rebuild the widget when the current route resumes.
  final bool rebuildOnResume;

  /// If `true`, the route lifecycle is ignored, and RouteBlocBuilder behaves like standard [BlocBuilder].
  ///
  /// This disables [RouteObserver]-based behavior.
  final bool forceClassicBuilder;

  /// Builds the widget using the given [context] and current [state].
  Widget build(BuildContext context, S state);

  @override
  State<RouteBlocBuilderBase<B, S>> createState() =>
      _RouteBlocBuilderBaseState<B, S>();
}

class _RouteBlocBuilderBaseState<B extends StateStreamable<S>, S>
    extends State<RouteBlocBuilderBase<B, S>> {
  /// The bloc instance being listened to.
  late B _bloc;

  /// The current state from the bloc.
  late S _state;

  late RouteObserver<Route<dynamic>> _observer;

  @override
  void initState() {
    super.initState();
    _observer = _observer = widget.observer ??
        RouteObserverProvider.of(context, widgetName: 'RouteBlocBuilder');

    _bloc = widget.bloc ?? context.read<B>();
    _state = _bloc.state;
  }

  @override
  void didUpdateWidget(RouteBlocBuilderBase<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<B>();
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      _state = _bloc.state;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      _bloc = bloc;
      _state = _bloc.state;
    }
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
      listenWhen: widget.buildWhen,
      listener: (context, state) => setState(() => _state = state),
      forceClassicListener: widget.forceClassicBuilder,
      child: widget.build(context, _state),
    );
  }
}
