import '../../services/api_service.dart';

class HubApiService {
  static final HubApiService instance = HubApiService._();
  HubApiService._();

  Future<Map<String, dynamic>> summary() =>
      ApiService.instance.getOne('/api/hub/summary');
}
