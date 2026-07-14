import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/api_service.dart';

/// API rapports de visite technique (base de données ISITEK).
class RapportApiService {
  static final RapportApiService instance = RapportApiService._();
  RapportApiService._();

  Future<List<dynamic>> list({String? q}) async {
    final path = q != null && q.trim().isNotEmpty
        ? '/api/rapport-visite?q=${Uri.encodeQueryComponent(q.trim())}'
        : '/api/rapport-visite';
    return ApiService.instance.get(path);
  }

  Future<Map<String, dynamic>> get(int id) async {
    return ApiService.instance.getOne('/api/rapport-visite/$id');
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    return ApiService.instance.post('/api/rapport-visite/', body);
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    return ApiService.instance.patch('/api/rapport-visite/$id', body);
  }

  Future<void> delete(int id) async {
    await ApiService.instance.delete('/api/rapport-visite/$id');
  }

  Future<Map<String, dynamic>> uploadPhoto(
    int rapportId,
    File file,
    String legende,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/rapport-visite/$rapportId/photos'),
    );
    final token = ApiService.instance.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['legende'] = legende;
    final streamed = await request.send().timeout(const Duration(minutes: 2));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Upload photo échoué (${response.statusCode})');
  }

  String photoUrl(String relativePath) {
    final p = relativePath.replaceAll('\\', '/');
    if (p.startsWith('http')) return p;
    if (p.startsWith('uploads/')) {
      return '${ApiConfig.baseUrl}/$p';
    }
    return '${ApiConfig.baseUrl}/uploads/$p';
  }
}
