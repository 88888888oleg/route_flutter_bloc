import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:route_flutter_bloc/src/route_bloc_builder.dart';
import 'package:route_flutter_bloc/src/route_bloc_listener.dart';
import 'package:route_flutter_bloc/src/route_observer_provider.dart';

/// {@template route_bloc_widget_listener}
/// Signature for the `listener` function used in [RouteBlocConsumer] and [RouteBlocListener].
///
/// Takes the `BuildContext` and the current `state`, and is responsible for
/// handling side effects in response to state changes, such as navigation,
/// showing a dialog, or triggering animations.
///
/// ```dart
/// RouteBlocWidgetListener<MyState>(
///   (context, state) {
///     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
///       content: Text('State changed: $state'),
///     ));
///   },
/// );
/// ```
/// {@endtemplate}
typedef RouteBlocWidgetListener<S> = void Function(
  BuildContext context,
  S state,
);

/// {@template route_bloc_listener_condition}
/// Signature for the optional `listenWhen` function used in [RouteBlocConsumer] and [RouteBlocListener].
///
/// Takes the previous and current `state` and returns a [bool] indicating
/// whether the `listener` should be called for the current `state`.
///
/// Can be used to control which state transitions should trigger side effects.
///
/// ```dart
/// RouteBlocListenerCondition<MyState>(
///   (previous, current) => current.isError,
/// );
/// ```
/// {@endtemplate}
typedef RouteBlocListenerCondition<S> = bool Function(S previous, S current);

/// {@template route_bloc_consumer}
/// [RouteBlocConsumer] combines a [RouteBlocListener] and [RouteBlocBuilder] in one widget,
/// allowing to both rebuild the UI and perform side effects in response to state changes
/// while also handling route lifecycle awareness via [RouteObserver].
///
/// It reduces boilerplate compared to nesting [RouteBlocListener] and [RouteBlocBuilder].
/// It is particularly useful when both UI updates and reactions to state are needed,
/// and when those reactions should respect the route's visibility.
///
/// If [bloc] is omitted, [RouteBlocConsumer] will perform a lookup using [BlocProvider]
/// and the current [BuildContext].
///
/// ```dart
/// RouteBlocConsumer<MyBloc, MyState>(
///   observer: routeObserver,
///   listener: (context, state) {
///     // do something in response to state changes
///   },
///   builder: (context, state) {
///     // return widget based on state
///   },
/// )
/// ```
///
/// Optional [buildWhen] and [listenWhen] can be used to control whether the
/// `builder` or `listener` should be called on a given state change.
///
/// You can also enable [rebuildOnResume] to trigger a rebuild when the route resumes,
/// and [triggerListenerOnResume] to re-fire the listener with the last state
/// after returning to the screen.
///
/// ```dart
/// RouteBlocConsumer<MyBloc, MyState>(
///   observer: routeObserver,
///   buildWhen: (previous, current) => current.shouldRebuild,
///   listenWhen: (previous, current) => current.shouldNotify,
///   rebuildOnResume: true,
///   triggerListenerOnResume: true,
///   listener: (context, state) {
///     // handle state change
///   },
///   builder: (context, state) {
///     // build based on state
///   },
/// )
/// ```
/// {@endtemplate}
class RouteBlocConsumer<B extends StateStreamable<S>, S>
    extends StatefulWidget {
  /// {@macro route_bloc_consumer}
  const RouteBlocConsumer({
    required this.builder,
    required this.listener,
    this.observer,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
    this.rebuildOnResume = false,
    this.triggerListenerOnResume = false,
    this.forceClassicListener = false,
    this.forceClassicBuilder = false,

    Key? key,
  }) : super(key: key);

  /// The [RouteObserver] used to track route changes and trigger rebuilds or listener calls accordingly.
  final RouteObserver<Route<dynamic>>? observer;

  /// The [bloc] that this widget interacts with.
  /// If null, it will be inferred using [BlocProvider.of].
  final B? bloc;

  /// The [builder] function which is called to build the UI based on the current [state].
  final RouteBlocWidgetBuilder<S> builder;

  /// The [listener] function that performs side effects in response to state changes.
  final RouteBlocWidgetListener<S> listener;

  /// Optional condition that determines whether [builder] should be called.
  final RouteBlocBuilderCondition<S>? buildWhen;

  /// Optional condition that determines whether [listener] should be called.
  final RouteBlocListenerCondition<S>? listenWhen;

  /// Whether the [builder] should be triggered again when the route is resumed.
  final bool rebuildOnResume;

  /// Whether the [listener] should be triggered again when the route is resumed
  /// with the last deferred state that occurred while the screen was inactive.
  final bool triggerListenerOnResume;

  /// If `true`, the route lifecycle is ignored, and listener behaves like standard [BlocListener].
  ///
  /// This disables [RouteObserver]-based behavior.
  final bool forceClassicListener;

  /// If `true`, the route lifecycle is ignored, and RouteBlocBuilder behaves like standard [BlocBuilder].
  ///
  /// This disables [RouteObserver]-based behavior.
  final bool forceClassicBuilder;

  @override
  State<RouteBlocConsumer<B, S>> createState() =>
      _RouteBlocConsumerState<B, S>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<B?>('bloc', bloc))
      ..add(
        DiagnosticsProperty<RouteObserver<Route<dynamic>>>(
          'observer',
          observer,
        ),
      )
      ..add(
        ObjectFlagProperty<RouteBlocWidgetBuilder<S>>.has('builder', builder),
      )
      ..add(
        ObjectFlagProperty<RouteBlocWidgetListener<S>>.has(
          'listener',
          listener,
        ),
      )
      ..add(
        FlagProperty(
          'rebuildOnResume',
          value: rebuildOnResume,
          ifTrue: 'rebuildOnResume: true',
        ),
      )
      ..add(
        FlagProperty(
          'triggerListenerOnResume',
          value: triggerListenerOnResume,
          ifTrue: 'triggerListenerOnResume: true',
        ),
      )
      ..add(
        ObjectFlagProperty<RouteBlocBuilderCondition<S>?>.has(
          'buildWhen',
          buildWhen,
        ),
      )
      ..add(
        ObjectFlagProperty<RouteBlocListenerCondition<S>?>.has(
          'listenWhen',
          listenWhen,
        ),
      );
  }
}

class _RouteBlocConsumerState<B extends StateStreamable<S>, S>
    extends State<RouteBlocConsumer<B, S>> {
  /// Internal reference to the currently used bloc.
  late B _bloc;
  late RouteObserver<Route<dynamic>> _observer;

  @override
  void initState() {
    super.initState();
    _observer =
        _observer = widget.observer ??
        RouteObserverProvider.of(context, widgetName: 'RouteBlocConsumer');
    _bloc = widget.bloc ?? context.read<B>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      _bloc = bloc;
    }
  }

  @override
  void didUpdateWidget(covariant RouteBlocConsumer<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<B>();
    final newBloc = widget.bloc ?? oldBloc;
    if (oldBloc != newBloc) {
      _bloc = newBloc;
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
      triggerOnResumed: widget.triggerListenerOnResume,
      forceClassicListener: widget.forceClassicListener,
      listenWhen: widget.listenWhen,
      listener: widget.listener,
      child: RouteBlocBuilder<B, S>(
        bloc: _bloc,
        observer: _observer,
        rebuildOnResume: widget.rebuildOnResume,
        forceClassicBuilder: widget.forceClassicBuilder,
        buildWhen: widget.buildWhen,
        builder: widget.builder,
      ),
    );
  }
}
