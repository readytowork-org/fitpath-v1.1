import 'package:fitpath/app/utils/api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PoinstsController extends GetxController {
  //add Points
  var lastTime;

  addPoints(String points) async {
    //allow only in 30 seconds
    if (lastTime == null || DateTime.now().difference(lastTime).inSeconds > 5) {
      lastTime = DateTime.now();

      final response = await http.post(Uri.parse(ADD_POINTS), body: {
        'points': points,
        'user_id': '1',
      });
      print(response.body);
    }
  }
}
