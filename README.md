# 🚀 Route Flutter Bloc — smart BLoC widgets that understand navigation
Avoid unnecessary rebuilds and side-effects when pages are hidden in the navigation stack.  
React only when needed. Improve performance without changing your app’s architecture. Works with the bloc library — you don’t need to change your development paradigm. You can always add this package without touching your existing code.

## Why use it?
route_flutter_bloc is a collection of enhanced versions of standard flutter_bloc widgets like BlocBuilder, BlocListener, and others.  
These widgets are navigation-aware — they know when your page is on screen or hidden inside the Navigator stack, and behave accordingly.
Will this package work with your navigation system? - If RouteAware works for you, then this package will work too.

In a typical Flutter app using flutter_bloc, your BlocBuilder or BlocListener widgets always work, even when the page is not visible.  
This can lead to:  
• 🔁 Unnecessary rebuilds that waste performance  
• ⚠️ Side-effects from BlocListener firing at the wrong time

## How this package solves it

This package upgrades the default behavior. All widgets behave the same as in flutter_bloc, except when the screen is hidden.

Here’s what you get:  
• ✅ When the page is visible — everything works as usual.  
• 💤 When the page is in the navigator stack but not on screen — widgets do nothing.  
• 🔄 When the page becomes visible again — widgets can:  
• Rebuild (RouteBlocBuilder)  
• React with side-effects (RouteBlocListener)  
• But only if the state changed while the page was hidden.

BY DEFAULT, THESE WIDGETS STAY QUIET WHEN COMING BACK TO THE SCREEN.  
BUT IF YOU WANT THEM TO REACT ON RESUME, JUST ENABLE A FLAG:

• rebuildOnResume: true for RouteBlocBuilder, RouteBlocConsumer, RouteBlocSelector  
• triggerOnResumed: true for RouteBlocListener, RouteBlocConsumer

This ensures the widget reacts once with the latest changed state — only if something really changed.

And yes — even if the final state equals the original, widgets still react if there was a transition.  
For example:  
• loaded → loading → loaded → Triggers ✅  
• loaded → loaded → No trigger ❌

The widgets behave according to the standard BLoC paradigm.

## Want the original behavior?

No problem.  
You can make any widget behave like its flutter_bloc counterpart by enabling:  
• forceClassicBuilder: true  
• forceClassicListener: true  
• forceClassicSelector: true

This disables the route-aware logic and makes widgets work always, regardless of screen visibility.

## 🧭 Route Awareness Setup

This package relies on Flutter's `RouteObserver` (via `RouteAware`) to detect when a page is on screen or hidden in the navigation stack.

You need to pass the RouteObserver instance using the RouteObserverProvider widget.

```dart
final RouteObserver<Route<dynamic>> routeFlutterBlocObserver =
    RouteObserver<Route<dynamic>>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteObserverProvider(
      observer: routeFlutterBlocObserver,
      child: RouteBlocProvider(
        create: (_) => CounterCubit(),
        child: MaterialApp(
          navigatorObservers: [routeFlutterBlocObserver],
          home: const FirstPage(),
        ),
      ),
    );
  }
}
```
You can also pass the observer directly to widgets:
```dart
RouteBlocBuilder<CounterCubit, int>(
  observer: routeFlutterBlocObserver,
  rebuildOnResume: true,
  builder: (_, state) {
    return Text(
      'State: $state',
    );
  },
);
```
## RouteBlocListener behavior

By default, RouteBlocListener fires only when the screen is visible.
If the page is inside the navigator stack — it stays silent.

You can configure its behavior with:
```dart
bool triggerOnResumed = false; // Trigger once when returning to screen, only if state changed - false by default
bool forceClassicListener = false; // Always trigger like in flutter_bloc - false by default
```
**Example usage**
```dart
RouteBlocListener<CounterCubit, int>(
  triggerOnResumed: true,
  forceClassicListener: false,
  listener: (context, state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Listener: $state')),
    );
  },
);
```
**RouteBlocListener now supports additional route lifecycle callbacks based on RouteAware:**
```dart
RouteBlocListener<MyBloc, MyState>(
didPush: () => print('Route was pushed'),
didPushNext: () => print('Another route was pushed on top'),
didPop: () => print('Route was popped'),
didPopNext: () => print('Returned to this route'),
...
)
```

## RouteBlocBuilder behavior

By default, `RouteBlocBuilder` rebuilds only when the screen is visible.  
If the page is hidden inside the navigator stack, it does not rebuild.

You can configure its behavior with:
```dart
bool rebuildOnResume = true; // Rebuild once when returning to screen, only if state changed - true by default
bool forceClassicBuilder = false; // Always rebuild like in flutter_bloc - false by default
```

**Example usage**
```dart
RouteBlocBuilder<CounterCubit, int>(
  rebuildOnResume: false,
  forceClassicBuilder: false,
  builder: (context, state) {
    return Text('State: $state');
  },
);
```

## RouteBlocConsumer behavior

By default, `RouteBlocConsumer` rebuilds and listens only when the screen is visible.  
If the page is hidden inside the navigator stack, neither builder nor listener will be called.

You can configure its behavior with:
```dart
bool rebuildOnResume = true; // Rebuild once when returning to screen, only if state changed - true by default
bool triggerOnResumed = false; // Trigger listener once when returning, only if state changed - false by default
bool forceClassicBuilder = false; // Always rebuild like in flutter_bloc - false by default
bool forceClassicListener = false; // Always listen like in flutter_bloc - false by default
```

**Example usage**
```dart
RouteBlocConsumer<CounterCubit, int>(
  rebuildOnResume: false,
  triggerOnResumed: true,
  forceClassicBuilder: false,
  forceClassicListener: false,
  listener: (context, state) {
    print('Listener: $state');
  },
  builder: (context, state) {
    return Text('State: $state');
  },
);
```

---

## RouteBlocSelector behavior

By default, `RouteBlocSelector` rebuilds only when the screen is visible.  
If the page is hidden inside the navigator stack, it stays inactive.

You can configure its behavior with:
```dart
bool rebuildOnResume = true; // Rebuild once when returning to screen, only if selected value changed - true by default
bool forceClassicSelector = false; // Always rebuild like in flutter_bloc - false by default
```

**Example usage**
```dart
RouteBlocSelector<CounterCubit, int, String>(
  selector: (state) => 'Value: $state',
  rebuildOnResume: false,
  forceClassicSelector: false,
  builder: (context, value) {
    return Text(value);
  },
);
```
## RouteMultiBlocListener behavior

By default, `RouteMultiBlocListener` triggers its listeners only when the screen is visible.  
If the page is hidden inside the navigator stack, the listeners stay silent.

Each listener inside `RouteMultiBlocListener` accepts the same flags as `RouteBlocListener`, giving you full control per-listener.

You can configure each listener with:
```dart
bool triggerOnResumed = false; // Trigger once when returning to screen, only if state changed - false by default
bool forceClassicListener = false; // Always trigger like in flutter_bloc - false by default
```

**Example usage**
```dart

   RouteMultiBlocListener(
    listeners: [
      RouteBlocListener<CounterCubit, int>(
        triggerOnResumed: false,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Counter: $state')),
          );
        },
      ),
      RouteBlocListener<CounterCubit, int>(
        triggerOnResumed: true,
        listener: (context, state) {
          setState(() => _counter = state);
        },
      ),
    ],
    child: SizedBox(),
  );

```
## RouteObserverProvider

`RouteObserverProvider` is a helper widget that provides a `RouteObserver` instance down the widget tree.  
It’s used internally by all `RouteBloc*` widgets to track route visibility and navigation events.

You only need this if you want to **inject your own `RouteObserver`** or use the system manually.

If you're using `route_flutter_bloc` alone, wrap your app once at the top:

**Example usage**
```dart
final RouteObserver<Route<dynamic>> routeObserver = RouteObserver<Route<dynamic>>();

void main() {
  runApp(
    RouteObserverProvider(
      observer: routeObserver,
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        home: MyHomePage(),
      ),
    ),
  );
}
```

If you don’t provide a `RouteObserver`, the system will try to find one from context or fallback to default.

## RouteBlocProvider and MultiRouteBlocProvider
are copies of the standard flutter_bloc widgets.
They are included for convenience in case you’re using this package standalone.
If you’re already using flutter_bloc in your project, you can continue using the original BlocProvider and MultiBlocProvider widgets — they will work just fine.

## popUntilGuarded

**Use Navigator.popUntilGuarded instead of Navigator.popUntil when navigating back through the route stack.**
```dart
Navigator.of(context).popUntilGuarded('/home');
```
**This is a safe alternative to:**
```dart
Navigator.of(context).popUntil((route) => route.settings.name == '/home');
```
**Unlike popUntil, which may skip or break listener logic, popUntilGuarded:**
•	Locks route-aware effects during the transition
•	Delays listener execution until the target route is fully active
•	Prevents premature or duplicated didPopNext calls
When using Navigator.popUntilGuarded('/routeName'), only one route in the stack (the one matched by the name) will receive didPopNext — and only after the first frame.
All intermediate routes will not receive didPopNext.
This is intentional and prevents unexpected re-activation logic.
So, if you use popUntilGuarded — only the final matching route gets didPopNext.
If you use popUntil — all routes below will get didPopNext as usual.

**⚠️ The target route must have a name (RouteSettings.name) assigned when pushed.**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const HomePage(),
    settings: const RouteSettings(name: '/home'),
  ),
);
```
```dart
MaterialApp(
  initialRoute: '/home',
  onGenerateRoute: (settings) {
    if (settings.name == '/home') {
      return MaterialPageRoute(
        builder: (_) => const HomePage(),
        settings: RouteSettings(name: '/home'),
      );
    }
    // ...
  },
)
```

**When to use**

Use Navigator.popUntilGuarded for multi-page back navigation (e.g. from page 3 to page 1) when working with RouteBlocListener and RouteObserverListener.


## RouteObserverListener behavior

By default, RouteObserverListener provides only route lifecycle awareness.
It does not depend on Bloc and is designed for navigation-related side effects only.

You can safely use the following RouteAware callbacks:
```dart
didPush        // called when this route is pushed
didPushNext    // called when another route is pushed on top
didPop         // called when this route is popped
didPopNext     // called when another route above was popped and this route becomes active again
```

**Example usage**

```dart
Navigator.of(context).popUntilGuarded('/first');
```
```dart
static MaterialPageRoute route() {
  return MaterialPageRoute(
  builder: (BuildContext context) {
    return FirstPage();
    },
    settings: RouteSettings(name: '/first'),
  );
}

RouteObserverListener(
  didPopNext: () {
    print('✅ Called ONLY on "/first" after popUntilGuarded');
  },
  child: FirstPage(),
);
```
```dart
static MaterialPageRoute route() {
  return MaterialPageRoute(
  builder: (BuildContext context) {
    return FirstPage();
    },
    settings: RouteSettings(name: '/second'),
  );
}
RouteObserverListener(
  didPopNext: () {
    print('❌ Will NOT be called on this page when using popUntilGuarded');
  },
  child: SecondPage(),
);
```

## 💬 Social

If you like the idea of improving the BLoC pattern and want to connect —  
feel free to add me on [LinkedIn](https://www.linkedin.com/in/olegstepanchenko/).

## ☕ Support

If you find this package useful, you can support the development by buying me a coffee!  
Your support helps keep this project active and maintained.

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/mobile_apps)

