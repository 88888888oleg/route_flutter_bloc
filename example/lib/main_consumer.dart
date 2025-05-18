import 'package:flutter/material.dart';
import 'package:route_flutter_bloc/route_flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:route_flutter_bloc/src/route_bloc_consumer.dart';
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
  bool rebuildOnResume = false;
  bool triggerListenerOnResume = false;
  bool classicBehavior = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RouteBlocConsumer Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RouteBlocConsumer<CounterCubit, int>(
              rebuildOnResume: rebuildOnResume,
              triggerListenerOnResume: triggerListenerOnResume,
              forceClassicListener: classicBehavior,
              forceClassicBuilder: classicBehavior,
              buildWhen: (prev, curr) => prev != curr,
              listenWhen: (prev, curr) => prev != curr,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Listener: $state')),
                );
              },
              builder: (context, state) {
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
                  value: rebuildOnResume,
                  onChanged: (v) =>
                      setState(() => rebuildOnResume = v ?? false),
                ),
                const Text('Rebuild on resume'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: triggerListenerOnResume,
                  onChanged: (v) =>
                      setState(() => triggerListenerOnResume = v ?? false),
                ),
                const Text('Trigger listener on resume'),
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
      appBar: AppBar(title: const Text('Page 2')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RouteBlocBuilder<CounterCubit, int>(
              builder: (context, state) =>
                  Text('State: $state', style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<CounterCubit>().increment(),
              child: const Text('Increment'),
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
