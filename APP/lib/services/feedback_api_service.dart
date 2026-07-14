import '../../services/api_service.dart';

class FeedbackApiService {
  static final FeedbackApiService instance = FeedbackApiService._();
  FeedbackApiService._();

  Future<Map<String, dynamic>> create({
    required String type,
    required String title,
    required String description,
  }) =>
      ApiService.instance.post('/api/feedback/', {
        'type': type,
        'title': title,
        'description': description,
      });

  Future<List<dynamic>> mine() => ApiService.instance.get('/api/feedback/mine');

  Future<List<dynamic>> listAll({String? status, String? type}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (type != null) params['type'] = type;
    final qs = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    return ApiService.instance.get('/api/feedback/$qs');
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) =>
      ApiService.instance.patch('/api/feedback/$id', body);

  Future<void> delete(int id) => ApiService.instance.delete('/api/feedback/$id');
}
