import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  // Analyze APK or PDF File
  Future<Map<String, dynamic>> analyzeFile(File file) async {
    // 1. Pre-validation on Flutter side
    if (!await file.exists()) {
      throw 'Selected file does not exist on your device.';
    }

    final fileLength = await file.length();
    if (fileLength == 0) {
      throw 'Selected file is empty (0 bytes).';
    }

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

      // Send request with explicit timeout for connection & upload
      final streamedResponse = await request.send().timeout(
        AppConstants.apiTimeout,
        onTimeout: () {
          throw TimeoutException('Backend connection timed out. The server took too long to respond.');
        },
      );

      // Read response stream with fallback timeout
      final response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('Timed out waiting for response payload from server.');
        },
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          throw 'Server returned an empty analysis payload.';
        }

        final dynamic decoded = json.decode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw 'Server returned invalid JSON format.';
        }

        decoded['file_type'] = fileType;
        return decoded;
      } else {
        String errorMessage = 'Server responded with error status: ${response.statusCode}';
        try {
          final dynamic errorJson = json.decode(response.body);
          if (errorJson is Map && errorJson.containsKey('error')) {
            errorMessage = errorJson['error'].toString();
          }
        } catch (_) {}
        throw errorMessage;
      }
    } on SocketException catch (e) {
      throw 'Network error: Unable to connect to ScanShield backend (${e.message}). Please check your internet connection.';
    } on TimeoutException catch (e) {
      throw e.message ?? 'Analysis request timed out. Please try scanning again.';
    } on FormatException {
      throw 'Invalid response received from server. Please try again.';
    } catch (e) {
      rethrow;
    }
  }

  // Check if server is online (Health Check)
  Future<bool> checkServerStatus() async {
    try {
      final response = await http
          .get(Uri.parse(AppConstants.apiBaseUrl + AppConstants.apiHealthEndpoint))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Asynchronous non-blocking backend warm-up
  void warmUpBackend() {
    checkServerStatus().catchError((_) => false);
  }
}
