import '../../services/api_service.dart';

class AstuceApiService {
  static final AstuceApiService instance = AstuceApiService._();
  AstuceApiService._();

  Future<List<dynamic>> listActive() => ApiService.instance.get('/api/astuces/');

  Future<List<dynamic>> listAllAdmin() =>
      ApiService.instance.get('/api/astuces/admin/all');

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) =>
      ApiService.instance.post('/api/astuces/', body);

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) =>
      ApiService.instance.patch('/api/astuces/$id', body);

  Future<void> delete(int id) => ApiService.instance.delete('/api/astuces/$id');
}
