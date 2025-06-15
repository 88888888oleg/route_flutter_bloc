import 'package:flutter/material.dart';
import 'package:route_flutter_bloc/route_flutter_bloc.dart';

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
          home: RootPage(),
        ),
      ),
    );
  }
}

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Root')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(context, FirstPage.route());
          },
          child: const Text('Start'),
        ),
      ),
    );
  }
}

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  static MaterialPageRoute route() {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return FirstPage();
      },
      settings: RouteSettings(name: '/first'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RouteBlocListener<CounterCubit, int>(
      triggerOnResumed: true,
      didPopNext: () {
        print('Safe didPopNext when use popUntilGuarded on page 1');
      },
      listener: (context, state) {
        print('LISTENER TRIGGERED on page 1: $state');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listener on page 1: $state')),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Page 1 - Home')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SecondPage()));
            },
            child: const Text('Go to Page 2'),
          ),
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteBlocListener<CounterCubit, int>(
      triggerOnResumed: true,
      didPopNext: () {
        print('Safe didPopNext, not triggered when use popUntilGuarded');
      },
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listener on page 2: $state')),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Page 2 - Listener ON')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RouteBlocBuilder<CounterCubit, int>(
                rebuildOnResume: true,
                builder: (_, state) => Text('State: $state'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThirdPage()),
                  );
                },
                child: const Text('Go to Page 3'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Page 1'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThirdPage extends StatelessWidget {
  const ThirdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page 3 - Trigger Reset')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(
              'Navigator.of(context).popUntilGuarded',
              style: TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 10),
            Text(
              'works only if the route in the predicate has a name. - ',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            Text(
              'route.settings.name',
              style: TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 10),
            RouteBlocBuilder<CounterCubit, int>(
              rebuildOnResume: true,
              builder: (_, state) => Text('State: $state'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('❌ Reset with popUntil (unsafe)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntilGuarded('/first');
              },
              child: const Text(
                  '✅ Reset with popUntilGuarded (safe) and route.settings.name in predicate'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('✅ Back to previous page'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                context.read<CounterCubit>().increment();
              },
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
