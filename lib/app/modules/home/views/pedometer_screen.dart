import 'package:cloud_firestore/cloud_firestore.dart';
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
    FirebaseFirestore.instance
        .collection('data')
        .doc('fitpath')
        .get()
        .then((value) {
      print(value.data());
      setState(() {
        userMainLatitude = value['userLatitude'];
        userMainLongitude = value['userLongitude'];
        userCurrentLatitude = value['userCurrentLatitude'];
        userCurrentLongitude = value['userCurrentLongitude'];
        distanceTravelled = double.parse(value['distanceTravelled'].toString());
      });
      print('called getUserLocationDetails');
    });
  }

  void onStepCount(StepCount event) {
    // print('step taken ${event.steps}');
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    getUserLocationDetails();
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
          body: showData()),
    );
  }

  //show firestore snapshot
  Widget showData() {
    var snapshots = FirebaseFirestore.instance
        .collection('data')
        .doc("fitpath")
        .snapshots();
    return StreamBuilder<DocumentSnapshot>(
      stream: snapshots,
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Text('Loading...');
          default:
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                      "Distance Traveled:'${snapshot.data!['distanceTravelled']}'"),
                ),
                Center(
                  child: Text(
                      "User Current Latitude:'${snapshot.data!['userCurrentLatitude']}'"),
                ),
                Center(
                  child: Text(
                      "User Current Longitude:'${snapshot.data!['userCurrentLongitude']}'"),
                ),
                Center(
                    child: Text(
                        "User Main Latitude:'${snapshot.data!['userLatitude']}'")),
                Center(
                    child: Text(
                        "User Main Longitude:'${snapshot.data!['userLongitude']}'")),
                Center(child: Text("Steps: $_steps")),
              ],
            );
        }
      },
    );
  }
}
