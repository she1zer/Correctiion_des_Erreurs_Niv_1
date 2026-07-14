import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  String? _token;
  UserModel? currentUser;

  String? get token => _token;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userJson = prefs.getString('user');
    if (userJson != null) {
      currentUser = UserModel.fromJson(jsonDecode(userJson));
    }
  }

  Future<void> _saveSession(String token, UserModel user) async {
    _token = token;
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode({
      'id': user.id,
      'email': user.email,
      'nom': user.nom,
      'prenom': user.prenom,
      'telephone': user.telephone,
      'poste': user.poste,
      'latitude': user.latitude,
      'longitude': user.longitude,
      'role': user.role,
      'is_active': user.isActive,
      'can_create_affaire': user.canCreateAffaire,
      'can_create_devis': user.canCreateDevis,
      'can_create_rapport': user.canCreateRapport,
      'can_manage_actions_internes': user.canManageActionsInternes,
      'can_access_caisse': user.canAccessCaisse,
      'can_caisse_controle': user.canCaisseControle,
      'can_caisse_livre': user.canCaisseLivre,
    }));
  }

  Future<void> logout() async {
    _token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static const Duration _timeout = Duration(seconds: 20);

  Future<dynamic> _request(Future<http.Response> Function() call, {Duration? timeout}) async {
    try {
      final response = await call().timeout(timeout ?? _timeout);
      return await _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Serveur inaccessible (${ApiConfig.baseUrl}). '
        'Vérifiez : API démarrée, même Wi-Fi, IP PC dans api_config.dart',
      );
    } on TimeoutException {
      throw ApiException('Délai dépassé — le serveur ne répond pas.');
    }
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(response.body);
    }
    String message = 'Erreur serveur';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) {
        message = body['detail'] is String
            ? body['detail']
            : body['detail'].toString();
      }
    } catch (_) {}
    throw ApiException(message, response.statusCode);
  }

  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user']);
    await _saveSession(data['access_token'] as String, user);
    return user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
    String? poste,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'role': role,
        if (poste != null) 'poste': poste,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      }),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateProfile({
    required String nom,
    required String prenom,
    required String telephone,
    String? password,
    double? latitude,
    double? longitude,
  }) async {
    final response = await patch('/api/users/me', {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      if (password != null && password.isNotEmpty) 'password': password,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    final user = UserModel.fromJson(response);
    if (_token != null) {
      await _saveSession(_token!, user);
    }
    return user;
  }

  Future<List<UserModel>> listUsers() async {
    final data = await get('/api/users/');
    return data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> updateUser(int userId, Map<String, dynamic> body) async {
    final response = await patch('/api/users/$userId', body);
    return UserModel.fromJson(response);
  }

  Future<void> deleteUser(int userId) async {
    await delete('/api/users/$userId');
  }

  Future<List<dynamic>> listAuthorizedPhones() async {
    return await get('/api/authorized-phones/');
  }

  Future<Map<String, dynamic>> createAuthorizedPhone({
    required String telephone,
    String? label,
  }) async {
    return await post('/api/authorized-phones/', {
      'telephone': telephone,
      if (label != null && label.isNotEmpty) 'label': label,
    });
  }

  Future<void> deleteAuthorizedPhone(int id) async {
    await delete('/api/authorized-phones/$id');
  }

  Future<Map<String, dynamic>> updateAuthorizedPhone(
    int id,
    Map<String, dynamic> body,
  ) async {
    return await patch('/api/authorized-phones/$id', body);
  }

  Future<List<dynamic>> get(String path) async {
    return await _request(() => http.get(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers,
        )) as List<dynamic>;
  }

  Future<Map<String, dynamic>> getOne(String path, {Duration? timeout}) async {
    return await _request(() => http.get(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers,
        ), timeout: timeout) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {Duration? timeout}) async {
    final data = await _request(() => http.post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers,
          body: jsonEncode(body),
        ), timeout: timeout);
    return data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    return await _request(() => http.patch(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers,
          body: jsonEncode(body),
        )) as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    await _request(() => http.delete(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers,
        ));
  }

  Future<String> uploadFile(String path, File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}$path'),
    );
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    final data = await _handleResponse(response) as Map<String, dynamic>;
    final url = data['url'] as String;
    return '${ApiConfig.baseUrl}$url';
  }

  Future<Uint8List> downloadPdf(String path) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Uint8List.fromList(response.bodyBytes);
    }
    throw ApiException('Erreur téléchargement PDF', response.statusCode);
  }

  Future<Uint8List> downloadBytesPost(String path, Map<String, dynamic> body, {Duration? timeout}) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(timeout ?? const Duration(minutes: 3));
    if (response.statusCode == 200) {
      return Uint8List.fromList(response.bodyBytes);
    }
    String message = 'Erreur téléchargement fichier';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {}
    throw ApiException(message, response.statusCode);
  }
}
