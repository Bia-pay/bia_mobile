import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class ConnectionTest {
  /// Test if the backend server is reachable
  static Future<bool> testServerReachability() async {
    try {
      print('🔍 Testing server reachability...');
      final response = await http.get(
        Uri.parse(AppConstants.baseUrl),
        headers: {'User-Agent': 'BIA-Flutter-App'},
      ).timeout(const Duration(seconds: 10));
      
      print('📡 Server response: ${response.statusCode}');
      return response.statusCode < 500; // Accept any non-server-error response
    } catch (e) {
      print('❌ Server unreachable: $e');
      return false;
    }
  }

  /// Test if Socket.IO endpoint exists
  static Future<bool> testSocketIOEndpoint() async {
    try {
      print('🔍 Testing Socket.IO endpoint...');
      
      // Try to access Socket.IO info endpoint
      final socketUrl = '${AppConstants.baseUrl}/socket.io/';
      final response = await http.get(
        Uri.parse(socketUrl),
        headers: {'User-Agent': 'BIA-Flutter-App'},
      ).timeout(const Duration(seconds: 10));
      
      print('🔌 Socket.IO endpoint response: ${response.statusCode}');
      
      // Socket.IO typically returns 400 for GET requests to the main endpoint
      // or 200 with Socket.IO info
      return response.statusCode == 400 || 
             response.statusCode == 200 ||
             response.body.contains('socket.io');
    } catch (e) {
      print('❌ Socket.IO endpoint test failed: $e');
      return false;
    }
  }

  /// Test authentication endpoint
  static Future<bool> testAuthEndpoint(String token) async {
    try {
      print('🔍 Testing auth with token...');
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/verify'), // Adjust endpoint as needed
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('🔐 Auth test response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Auth test failed: $e');
      return false;
    }
  }

  /// Run all connection tests
  static Future<Map<String, bool>> runAllTests({String? token}) async {
    print('🧪 Running connection tests...');
    
    final results = <String, bool>{};
    
    results['server_reachable'] = await testServerReachability();
    results['socket_io_endpoint'] = await testSocketIOEndpoint();
    
    if (token != null && token.isNotEmpty) {
      results['auth_valid'] = await testAuthEndpoint(token);
    }
    
    print('📊 Test results: $results');
    return results;
  }

  /// Get connection recommendations based on test results
  static List<String> getRecommendations(Map<String, bool> testResults) {
    final recommendations = <String>[];
    
    if (testResults['server_reachable'] == false) {
      recommendations.add('❌ Server is not reachable. Check your internet connection and server status.');
    }
    
    if (testResults['socket_io_endpoint'] == false) {
      recommendations.add('❌ Socket.IO endpoint not found. Ensure backend has Socket.IO server running.');
    }
    
    if (testResults['auth_valid'] == false) {
      recommendations.add('❌ Authentication failed. Check if your token is valid and not expired.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('✅ All tests passed! Connection should work.');
    }
    
    return recommendations;
  }
}