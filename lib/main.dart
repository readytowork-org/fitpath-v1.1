import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:background_fetch/background_fetch.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitpath/app/modules/home/bindings/home_binding.dart';
import 'package:fitpath/app/modules/home/controllers/points_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/routes/app_pages.dart';
import 'dart:math' show pi, pow, cos, sin, asin, sqrt;

final PoinstsController pointsController = Get.put(PoinstsController());
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await userPermission();
  await initializeService();
  initPlatformState();
  BackgroundFetch.scheduleTask(TaskConfig(
      taskId: "com.foo.customtask",
      delay: 6000, // milliseconds
      periodic: false));
  runApp(
    GetMaterialApp(
      title: "Application",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      //initial dependencies
      initialBinding: HomeBinding(),
    ),
  );
}

Future<bool> isFirstTime() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs = await SharedPreferences.getInstance();
  var isFirstTime = prefs.getBool('first_time');
  if (isFirstTime != null && !isFirstTime) {
    return false;
  } else {
    return true;
  }
}

userPermission() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var isFirstTimeVal = await isFirstTime();
  print("isFirst Time $isFirstTimeVal");

  var permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    // TODO: make a dialog to open settings
  } else if (permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse) {
    if (isFirstTimeVal) {
      Position myLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      prefs.setBool('first_time', false);
      await prefs.setString('userLatitude', myLocation.latitude.toString());
      await prefs.setString('userLongitude', myLocation.longitude.toString());
    } else {
      var userLatitude = double.parse(prefs.getString('userLatitude') ?? "");
      var userLongitude = double.parse(prefs.getString('userLongitude') ?? "");

      print({userLatitude, userLongitude});
    }
  } else {
    // display info message to user saying this feature is restricted in your device
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will executed when app is in foreground or background in separated isolate
      onStart: onStart,
      // auto start service
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,
      // this will executed when app is in foreground in separated isolate
      onForeground: onStart,
      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
  service.startService();
}

// to ensure this executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  print('FLUTTER BACKGROUND FETCH');
  return true;
}

void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later

  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  SharedPreferences preferences = await SharedPreferences.getInstance();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) async {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  var userLatitude = double.parse(preferences.getString('userLatitude') ?? "0");
  var userLongitude =
      double.parse(preferences.getString('userLongitude') ?? "0");

  late Position currentUserLocation;
  // StreamController<double> controller = StreamController<double>();
  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final hello = preferences.getString("hello");

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "My App Service",
        content: "Updated at ${DateTime.now()}",
      );
    }

    currentUserLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    await preferences.setString(
        'userCurrentLatitude', currentUserLocation.latitude.toString());
    await preferences.setString(
        'userCurrentLongitude', currentUserLocation.longitude.toString());

    double userLatitudeRad = userLatitude * pi / 180;
    double currentUserLatitudeRad = currentUserLocation.latitude * pi / 180;

    double userLongitudeRad = userLongitude * pi / 180;
    double currentUserLongitudeRad = currentUserLocation.longitude * pi / 180;

    // Haversine formula
    double dLongitude = currentUserLongitudeRad - userLongitudeRad;
    double dLatitude = currentUserLatitudeRad - userLatitudeRad;
    double a = pow(sin(dLatitude / 2), 2) +
        cos(userLatitudeRad) *
            cos(currentUserLatitudeRad) *
            pow(sin(dLongitude / 2), 2);

    double c = 2 * asin(sqrt(a));

    // Radius of earth in kilometers. Use 3956 for miles
    int radius = 6371;

    // calculate the result in meters
    double distance = (c * radius * 1000);

    await preferences.setString(
        'distanceTravelled', (distance.floor()).toString());

    pointsController.addPoints('50');
    // test using external plugin
    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }
    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

Future<void> initPlatformState() async {
  // Configure BackgroundFetch.
  int status = await BackgroundFetch.configure(
      BackgroundFetchConfig(
          minimumFetchInterval: 1,
          stopOnTerminate: false,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.ANY), (String taskId) async {
    // <-- Event handler
    // This is the fetch-event callback.

    // IMPORTANT:  You must signal completion of your task or the OS can punish your app
    // for taking too long in the background.
    BackgroundFetch.finish(taskId);
  }, (String taskId) async {
    // <-- Task timeout handler.
    pointsController.addPoints('50');
    // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
    BackgroundFetch.finish(taskId);
  });
  print('[BackgroundFetch] configure success: $status');

  // If the widget was removed from the tree while the asynchronous platform
  // message was in flight, we want to discard the reply rather than calling
  // setState to update our non-existent appearance.
}
