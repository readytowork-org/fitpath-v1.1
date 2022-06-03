import 'package:fitpath/app/modules/home/views/pedometer_screen.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeView'),
        centerTitle: true,
      ),
      body: Center(
          child: ElevatedButton(
              onPressed: () => Get.to(() => PedometerScreen()),
              child: const Text('GO TO Pedometer'))),
    );
  }
}
