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
      child: MultiRouteBlocProvider(
        providers: [
          RouteBlocProvider(create: (_) => CounterCubit()),
        ],
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
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return RouteMultiBlocListener(
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
      child: SizedBox(
        child: Text('$_counter'),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page 2 - Listener INACTIVE')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RouteBlocBuilder<CounterCubit, int>(
              builder: (_, state) => Text('Counter: $state'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.read<CounterCubit>().increment(),
              child: const Text('Increment'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Pop Back'),
            ),
          ],
        ),
      ),
    );
  }
}
