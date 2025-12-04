import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MLService {
  // REPLACE THIS URL with your friend's actual server URL later.
  // For Android Emulator testing, use 'http://10.0.2.2:5000/predict'
  // For Physical Device, use your PC's local IP (e.g. 'http://192.168.1.5:5000/predict')
  final String _apiUrl = "http://172.28.132.195:5000/predict";

  Future<void> initialize() async {
    // No local initialization needed for Cloud API
  }

  Future<String> classifyImage(File image) async {
    try {
      // 1. Create the POST request
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      
      // 2. Attach the image file
      // 'file' is the key name your friend's python script expects
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      // 3. Send and wait for response
      var streamResponse = await request.send();
      var response = await http.Response.fromStream(streamResponse);
      
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        // Expecting JSON like: {"label": "German Shepherd", "confidence": 0.95}
        String label = json['label'];
        double confidence = json['confidence'];
        
        return "$label (${(confidence * 100).toStringAsFixed(1)}%)";
      } else {
        return "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      print("ML Error: $e");
      return "Connection Error. Is the server running?";
    }
  }
}