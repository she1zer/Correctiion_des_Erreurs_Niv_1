import '../../services/api_service.dart';

class CaisseApiService {
  static final CaisseApiService instance = CaisseApiService._();
  CaisseApiService._();

  // ── Fiche contrôle ──
  Future<List<dynamic>> listControle({String? q, int? annee}) async {
    final params = <String, String>{};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (annee != null) params['annee'] = annee.toString();
    final qs = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    return ApiService.instance.get('/api/caisse/controle/$qs');
  }

  Future<Map<String, dynamic>> getControle(int id) =>
      ApiService.instance.getOne('/api/caisse/controle/$id');

  Future<Map<String, dynamic>> getControlePage(int pageId) =>
      ApiService.instance.getOne('/api/caisse/controle/page/$pageId');

  Future<Map<String, dynamic>> createControle(Map<String, dynamic> body) =>
      ApiService.instance.post('/api/caisse/controle/', body);

  Future<Map<String, dynamic>> updateControle(int id, Map<String, dynamic> body) =>
      ApiService.instance.patch('/api/caisse/controle/$id', body);

  Future<void> deleteControle(int id) =>
      ApiService.instance.delete('/api/caisse/controle/$id');

  // ── Livre caisse ──
  Future<List<dynamic>> listLivre({String? q, int? annee}) async {
    final params = <String, String>{};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (annee != null) params['annee'] = annee.toString();
    final qs = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    return ApiService.instance.get('/api/caisse/livre/$qs');
  }

  Future<Map<String, dynamic>> getLivre(int id) =>
      ApiService.instance.getOne('/api/caisse/livre/$id');

  Future<Map<String, dynamic>> createLivre(Map<String, dynamic> body) =>
      ApiService.instance.post('/api/caisse/livre/', body);

  Future<Map<String, dynamic>> updateLivre(int id, Map<String, dynamic> body) =>
      ApiService.instance.patch('/api/caisse/livre/$id', body);

  Future<void> deleteLivre(int id) =>
      ApiService.instance.delete('/api/caisse/livre/$id');

  Future<Map<String, dynamic>> search(String q) =>
      ApiService.instance.getOne('/api/caisse/search?q=${Uri.encodeQueryComponent(q)}');
}
