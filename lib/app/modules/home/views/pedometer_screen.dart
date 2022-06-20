import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitpath/main.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class PedometerScreen extends StatefulWidget {
  const PedometerScreen({Key? key}) : super(key: key);

  @override
  _PedometerScreenState createState() => _PedometerScreenState();
}

class _PedometerScreenState extends State<PedometerScreen> {
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
    });
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
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              showData(),
              ElevatedButton(
                  onPressed: () {
                    pointsController.addPoints('10');
                  },
                  child: const Text('Add Points')),
            ],
          )),
    );
  }

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
