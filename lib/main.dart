// ignore_for_file: unused_import

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tuparkingpa/firebase_options.dart';
import 'package:tuparkingpa/homes/home_conductores.dart';
import 'package:tuparkingpa/homes/home_estacionamientos.dart';
import 'package:tuparkingpa/logins/login_conductores.dart';
import 'package:tuparkingpa/logins/login_estacionamientos.dart';
import 'package:tuparkingpa/registers/register_conductores.dart';
import 'package:tuparkingpa/registers/register_estacionamientos.dart';
import 'package:tuparkingpa/seleccion_tipo_usuario.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuParking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => UserTypeSelectionScreen(),
        '/driverLogin': (context) => DriverLoginScreen(),
        '/parkingLogin': (context) => ParkingLoginScreen(),
        '/driverRegister': (context) => RegisterDriverScreen(),
        '/parkingRegister': (context) => RegisterParkingScreen(),
        '/DriverHomeScreen': (context) => DriverHomeScreen(),
        '/ParkingHomeScreen': (context) => ParkingHomeScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
