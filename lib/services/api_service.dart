import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  // Analyze APK or PDF File
  Future<Map<String, dynamic>> analyzeFile(File file) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiScanEndpoint}');
    final fileExtension = file.path.split('.').last.toLowerCase();
    final String fileType = (fileExtension == 'pdf') ? 'pdf' : 'apk';
    
    try {
      final request = http.MultipartRequest('POST', uri);
      
      // Add the file (field name expected by backend: 'file')
      final multipartFile = await http.MultipartFile.fromPath(
        'file', 
        file.path,
      );
      request.files.add(multipartFile);

      // Send request with timeout
      final streamedResponse = await request.send().timeout(AppConstants.apiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        data['file_type'] = fileType;
        return data;
      } else {
        throw 'Server responded with status code: ${response.statusCode}';
      }
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  // Check if server is online
  Future<bool> checkServerStatus() async {
    try {
      final response = await http
          .get(Uri.parse(AppConstants.apiBaseUrl + AppConstants.apiHealthEndpoint))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
