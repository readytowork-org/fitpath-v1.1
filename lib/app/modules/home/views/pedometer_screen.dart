import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedometerScreen extends StatefulWidget {
  const PedometerScreen({Key? key}) : super(key: key);

  @override
  _PedometerScreenState createState() => _PedometerScreenState();
}

class _PedometerScreenState extends State<PedometerScreen> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  double? userCurrentLatitude;
  double? userCurrentLongitude;
  double? userMainLatitude;
  double? userMainLongitude;
  double? distanceTravelled;
  String _status = '0', _steps = '0';
  final Future<SharedPreferences> preferences = SharedPreferences.getInstance();
  // StreamController<double> controller = StreamController<double>();

  @override
  void initState() {
    initPlatformState();
    getUserLocationDetails();
    super.initState();
  }

  void getUserLocationDetails() async {
    final SharedPreferences prefs = await preferences;
    userMainLatitude = double.parse(prefs.getString('userLatitude') ?? "0");
    userMainLongitude = double.parse(prefs.getString('userLongitude') ?? "0");

    userCurrentLatitude =
        double.parse(prefs.getString('userCurrentLatitude') ?? "0");
    userCurrentLongitude =
        double.parse(prefs.getString('userCurrentLongitude') ?? "0");

    distanceTravelled =
        double.parse(prefs.getString('distanceTravelled') ?? "0");
  }

  void onStepCount(StepCount event) {
    print('step taken ${event.steps}');
    print(event);
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    // controller.stream.listen((value) {
    //   print('Value from controller: $value');
    // });
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('FITPATH'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Distance Travelled: ${distanceTravelled ?? ""}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  'Initial Latitude: ${userMainLatitude ?? ""}, \nInitial Longitude : ${userMainLongitude ?? ""}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  'Current Latitude: ${userCurrentLatitude ?? ""}, \nCurrent Longitude : ${userCurrentLongitude ?? ""}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(
                  height: 15,
                ),
                const Text(
                  'Steps taken:',
                  style: TextStyle(fontSize: 30),
                ),
                Text(
                  _steps,
                  style: const TextStyle(fontSize: 60),
                ),
                const Divider(
                  height: 100,
                  thickness: 0,
                  color: Colors.white,
                ),
                const Text(
                  'Pedestrian status:',
                  style: TextStyle(fontSize: 30),
                ),
                Icon(
                  _status == 'walking'
                      ? Icons.directions_walk
                      : _status == 'stopped'
                          ? Icons.accessibility_new
                          : Icons.error,
                  size: 100,
                ),
                Center(
                  child: Text(
                    _status,
                    style: _status == 'walking' || _status == 'stopped'
                        ? const TextStyle(fontSize: 30)
                        : const TextStyle(fontSize: 20, color: Colors.red),
                  ),
                )
              ],
            ),
          )),
    );
  }
}
