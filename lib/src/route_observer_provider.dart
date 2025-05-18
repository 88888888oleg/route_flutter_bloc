import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// {@template route_observer_provider}
/// Provides a [RouteObserver] to the widget tree using [Provider].
///
/// This is required for widgets like [RouteBlocListener] to access
/// a [RouteObserver] via [RouteObserverProvider.of].
///
/// Example:
/// ```dart
/// RouteObserverProvider(
///   observer: RouteObserver<PageRoute>(),
///   child: MaterialApp(
///     navigatorObservers: [RouteObserverProvider.of(context)],
///     home: HomePage(),
///   ),
/// )
/// ```
/// {@endtemplate}
class RouteObserverProvider extends SingleChildStatelessWidget {
  /// {@macro route_observer_provider}
  const RouteObserverProvider({
    required this.observer,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  /// The [RouteObserver] instance to expose to the widget tree.
  final RouteObserver<Route<dynamic>> observer;

  /// Accesses the nearest [RouteObserver] in the tree.
  static RouteObserver<Route<dynamic>> of(
      BuildContext context, {
        bool listen = false,
        String widgetName = 'Route-aware widget',
      }) {
    try {
      return Provider.of<RouteObserver<Route<dynamic>>>(context, listen: listen);
    } on ProviderNotFoundException {
      throw FlutterError(
        '$widgetName could not find a RouteObserver.\n'
            'Make sure your app is wrapped in a RouteObserverProvider.\n\n'
            'Example:\n'
            'RouteObserverProvider(\n'
            '  observer: RouteObserver<PageRoute>(),\n'
            '  child: MaterialApp(...),\n'
            ')',
      );
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
    child != null,
    '$runtimeType must have a child',
    );

    return Provider<RouteObserver<Route<dynamic>>>.value(
      value: observer,
      child: child!,
    );
  }
}
