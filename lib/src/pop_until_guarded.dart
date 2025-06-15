import 'package:flutter/material.dart';
import 'package:route_flutter_bloc/route_flutter_bloc.dart';

import 'package:flutter/widgets.dart';
import 'package:route_flutter_bloc/src/route_navigation_blocker.dart';
import 'route_observer_provider.dart';

extension NavigatorPopGuardedExtension on NavigatorState {
  void popUntilGuarded(String routeName, [bool waitSecondFrame = false]) {
    final blocker = RouteObserverProvider.blockerOf(context);
    blocker?.lock();

    popUntil((route) => route.settings.name == routeName);

    _unlockAndTrigger(blocker, routeName, waitSecondFrame);
  }

  void _unlockAndTrigger(
    RouteNavigationBlocker? blocker,
    String? name,
    bool waitSecondFrame,
  ) {
    void trigger() {
      blocker?.unlock();
      blocker?.triggerListener(name);
    }

    if (waitSecondFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          trigger();
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        trigger();
      });
    }
  }
}
