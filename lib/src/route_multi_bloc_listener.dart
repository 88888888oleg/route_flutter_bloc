import 'package:flutter/widgets.dart';
import 'package:route_flutter_bloc/src/route_bloc_listener.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// {@template route_multi_bloc_listener}
/// Merges multiple [RouteBlocListener] widgets into one widget tree.
///
/// [RouteMultiBlocListener] improves readability by reducing nesting of
/// multiple [RouteBlocListener] widgets into a single widget.
///
/// Instead of nesting:
///
/// ```dart
/// RouteBlocListener<A, AState>(
///   listener: (context, state) {},
///   observer: routeObserver,
///   child: RouteBlocListener<B, BState>(
///     listener: (context, state) {},
///     observer: routeObserver,
///     child: RouteBlocListener<C, CState>(
///       listener: (context, state) {},
///       observer: routeObserver,
///       child: ChildWidget(),
///     ),
///   ),
/// )
/// ```
///
/// You can do:
///
/// ```dart
/// RouteMultiBlocListener(
///   listeners: [
///     RouteBlocListener<A, AState>(
///       observer: routeObserver,
///       listener: (context, state) {},
///     ),
///     RouteBlocListener<B, BState>(
///       observer: routeObserver,
///       listener: (context, state) {},
///     ),
///     RouteBlocListener<C, CState>(
///       observer: routeObserver,
///       listener: (context, state) {},
///     ),
///   ],
///   child: ChildWidget(),
/// )
/// ```
///
/// [RouteMultiBlocListener] simply wraps [RouteBlocListener]s using
/// `MultiProvider` as base implementation.
/// {@endtemplate}
class RouteMultiBlocListener extends MultiProvider {
  /// {@macro route_multi_bloc_listener}
  RouteMultiBlocListener({
    required List<SingleChildWidget> listeners,
    required Widget child,
    Key? key,
  }) : super(key: key, providers: listeners, child: child);
}