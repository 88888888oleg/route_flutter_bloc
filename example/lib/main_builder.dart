import 'package:flutter/material.dart';
import 'package:route_flutter_bloc/route_flutter_bloc.dart';
import 'package:route_flutter_bloc/src/route_bloc_builder.dart';
import 'package:route_flutter_bloc/src/route_observer_provider.dart';

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

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  bool rebuildOnResumed = false;
  bool classicBehavior = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page 1 - Builder ACTIVE')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RouteBlocBuilder<CounterCubit, int>(
              forceClassicBuilder: classicBehavior,
              rebuildOnResume: rebuildOnResumed,
              builder: (_, state) {
                print('BUILDER: $state');
                return Text('State: $state',
                    style: const TextStyle(fontSize: 20));
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<CounterCubit>().increment(),
              child: const Text('Increment'),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: rebuildOnResumed,
                  onChanged: (value) {
                    setState(() => rebuildOnResumed = value ?? false);
                  },
                ),
                const Text('Rebuild on resume'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: classicBehavior,
                  onChanged: (value) {
                    setState(() => classicBehavior = value ?? false);
                  },
                ),
                const Text('Classic behavior'),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<dynamic>(
                      builder: (_) => const SecondPage()),
                );
              },
              child: const Text('Push Page 2'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page 2 - Builder INACTIVE')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RouteBlocBuilder<CounterCubit, int>(
              builder: (_, state) =>
                  Text('State: $state', style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<CounterCubit>().increment(),
              child: const Text('Increment (builder should NOT fire)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Pop Page 2'),
            ),
          ],
        ),
      ),
    );
  }
}
