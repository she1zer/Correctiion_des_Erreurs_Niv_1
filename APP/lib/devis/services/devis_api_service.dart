import 'dart:typed_data';

import '../../services/api_service.dart';

class DevisApiService {
  static final DevisApiService instance = DevisApiService._();
  DevisApiService._();

  Future<List<dynamic>> fetchEmails({int limit = 20}) async {
    return ApiService.instance.get('/api/devis/emails?limit=$limit');
  }

  Future<Map<String, dynamic>> analyzeEmail({
    String? messageId,
    String? rawText,
    String? subject,
    String? fromAddress,
  }) async {
    return ApiService.instance.post('/api/devis/emails/analyze', {
      if (messageId != null) 'message_id': messageId,
      if (rawText != null) 'raw_text': rawText,
      if (subject != null) 'subject': subject,
      if (fromAddress != null) 'from_address': fromAddress,
    });
  }

  Future<Map<String, dynamic>> searchReference(String reference) async {
    final encoded = Uri.encodeComponent(reference);
    return ApiService.instance.getOne('/api/devis/search/$encoded');
  }

  Future<String> nextDevisNumber() async {
    final data = await ApiService.instance.getOne('/api/devis/next-number');
    return data['numero_devis'] as String;
  }

  Future<Map<String, dynamic>> saveDevis(Map<String, dynamic> body) async {
    return ApiService.instance.post('/api/devis/', body);
  }

  Future<Map<String, dynamic>> updateDevis(int id, Map<String, dynamic> body) async {
    return ApiService.instance.patch('/api/devis/$id', body);
  }

  Future<Map<String, dynamic>> getDevis(int id) async {
    return ApiService.instance.getOne('/api/devis/$id');
  }

  Future<void> deleteDevis(int id) async {
    await ApiService.instance.delete('/api/devis/$id');
  }

  Future<List<dynamic>> listShares(int devisId) async {
    return ApiService.instance.get('/api/devis/$devisId/shares');
  }

  Future<Map<String, dynamic>> shareDevis(int devisId, int userId, {bool canEdit = true}) async {
    return ApiService.instance.post('/api/devis/$devisId/share', {
      'user_id': userId,
      'can_edit': canEdit,
    });
  }

  Future<void> unshareDevis(int devisId, int userId) async {
    await ApiService.instance.delete('/api/devis/$devisId/share/$userId');
  }

  Future<Map<String, dynamic>> createAffaireFromDevis(int devisId) async {
    return ApiService.instance.post('/api/devis/$devisId/create-affaire', {
      'creer_etapes_standard': true,
    });
  }

  Future<List<dynamic>> listDevis() async {
    return ApiService.instance.get('/api/devis/');
  }

  Future<Uint8List> renderPdf(Map<String, dynamic> body) async {
    return ApiService.instance.downloadBytesPost('/api/devis/render-pdf', body);
  }

  Future<Uint8List> renderExcel(Map<String, dynamic> body) async {
    return ApiService.instance.downloadBytesPost('/api/devis/render-excel', body);
  }

  Future<Uint8List> downloadPdf(int devisId) async {
    return ApiService.instance.downloadPdf('/api/devis/$devisId/pdf');
  }
}
