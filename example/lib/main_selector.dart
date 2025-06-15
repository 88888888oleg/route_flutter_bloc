import 'package:flutter/material.dart';
import 'package:route_flutter_bloc/route_flutter_bloc.dart';

final RouteObserver<Route<dynamic>> routeFlutterBlocObserver =
    RouteObserver<Route<dynamic>>();

void main() {
  runApp(const MyApp());
}

class CubitState {
  const CubitState({this.fieldA = 0, this.fieldB = 0});

  final int fieldA;
  final int fieldB;

  CubitState operator +(int value) {
    return CubitState(fieldA: fieldA + value, fieldB: fieldB + 2*value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CubitState &&
          runtimeType == other.runtimeType &&
          fieldA == other.fieldA &&
          fieldB == other.fieldB;

  @override
  int get hashCode => fieldA.hashCode ^ fieldB.hashCode;
}

class CounterCubit extends Cubit<CubitState> {
  CounterCubit() : super(const CubitState());

  void increment() => emit(state + 1);
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

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  bool rebuildOnResume = false;
  bool classicBehavior = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RouteBlocSelector Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RouteBlocSelector<CounterCubit, CubitState, int>(
              bloc: context.read<CounterCubit>(),
              selector: (state) => state.fieldA,
              rebuildOnResume: rebuildOnResume,
              forceClassicSelector: classicBehavior,
              builder: (context, selected) {
                return Text('Selected fieldA: $selected',
                    style: const TextStyle(fontSize: 24));
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<CounterCubit>().increment(),
              child: const Text('Increment'),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: rebuildOnResume,
                  onChanged: (value) =>
                      setState(() => rebuildOnResume = value ?? false),
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
                  MaterialPageRoute(builder: (_) => const SecondPage()),
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
      appBar: AppBar(title: const Text('Second Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RouteBlocBuilder<CounterCubit, CubitState>(
              builder: (context, state) => Text(
                'fieldB: ${state.fieldB}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<CounterCubit>().increment(),
              child: const Text('Increment'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to First Page'),
            ),
          ],
        ),
      ),
    );
  }
}
