import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'api_service.dart';

class DemandeModel {
  final String id;
  final int? clientId;
  final String domaine;
  final String typePrestation;
  final String description;
  final String adresse;
  String statut;
  int? devisMontant;
  final DateTime dateCreation;
  int? rating;
  String? avis;
  bool isRated;
  List<String> photos;
  int? accomptePourcentage;
  int? garantieMois;
  DateTime? garantieDebut;
  DateTime? garantieFin;
  Set<int> etapesSautees;

  DemandeModel({
    required this.id,
    this.clientId,
    required this.domaine,
    required this.typePrestation,
    required this.description,
    required this.adresse,
    required this.statut,
    this.devisMontant,
    required this.dateCreation,
    this.rating,
    this.avis,
    this.isRated = false,
    this.photos = const [],
    this.accomptePourcentage,
    this.garantieMois,
    this.garantieDebut,
    this.garantieFin,
    this.etapesSautees = const {},
  });
}

class MessageModel {
  final String id;
  final String sender; // 'client' or 'support'
  final String content;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
  });
}

class DemandeService extends ChangeNotifier {
  static final DemandeService instance = DemandeService._();
  DemandeService._() {
    _startPolling();
  }

  List<DemandeModel> _demandes = [];
  List<MessageModel> _messages = [];
  Timer? _pollingTimer;
  bool _isFetching = false;
  int? _activeClientId;

  List<DemandeModel> demandesForClient(int clientId) {
    return _demandes.where((d) => d.clientId == clientId).toList();
  }

  List<DemandeModel> get demandes => _demandes;
  List<MessageModel> get messages => _messages;
  int? get activeClientId => _activeClientId;

  void start() {
    fetchData();
    _startPolling();
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void setActiveClient(int? id) {
    _activeClientId = id;
    _messages = [];
    notifyListeners();
    fetchData();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    final user = ApiService.instance.currentUser;
    if (user == null) return;
    if (_isFetching) return;
    _isFetching = true;

    try {
      // 1. Fetch Demands
      final demData = await ApiService.instance.get('/api/demandes/');
      _demandes = demData.map((e) {
        final photosRaw = e['photos'] as String?;
        final photos = photosRaw != null && photosRaw.isNotEmpty
            ? photosRaw.split('|').where((p) => p.isNotEmpty).toList()
            : <String>[];
        final skippedRaw = e['etapes_sautees'] as String?;
        final skipped = skippedRaw != null && skippedRaw.isNotEmpty
            ? skippedRaw.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toSet()
            : <int>{};
        return DemandeModel(
          id: e['id'].toString(),
          clientId: e['client_id'] as int?,
          domaine: e['domaine'],
          typePrestation: e['type_prestation'],
          description: e['description'],
          adresse: e['adresse'],
          statut: e['statut'],
          devisMontant: e['devis_montant'],
          dateCreation: DateTime.parse(e['created_at']),
          rating: e['rating'],
          avis: e['avis'],
          isRated: e['rating'] != null,
          photos: photos,
          accomptePourcentage: e['accompte_pourcentage'],
          garantieMois: e['garantie_mois'],
          garantieDebut: e['garantie_debut'] != null ? DateTime.tryParse(e['garantie_debut']) : null,
          garantieFin: e['garantie_fin'] != null ? DateTime.tryParse(e['garantie_fin']) : null,
          etapesSautees: skipped,
        );
      }).toList();

      // 2. Fetch Messages
      if (user.role == 'client') {
        final msgData = await ApiService.instance.get('/api/messages/');
        _messages = msgData.map((e) => MessageModel(
          id: e['id'].toString(),
          sender: e['sender_role'],
          content: e['content'],
          timestamp: DateTime.parse(e['created_at']),
        )).toList();
      } else {
        // Admin / support: fetch only if active client is selected
        if (_activeClientId != null) {
          final msgData = await ApiService.instance.get('/api/messages/?client_id=$_activeClientId');
          _messages = msgData.map((e) => MessageModel(
            id: e['id'].toString(),
            sender: e['sender_role'],
            content: e['content'],
            timestamp: DateTime.parse(e['created_at']),
          )).toList();
        }
      }
      notifyListeners();
    } catch (_) {
      // Silently ignore connection errors during background polling
    } finally {
      _isFetching = false;
    }
  }

  Future<void> addDemande({
    required String domaine,
    required String typePrestation,
    required String description,
    required String adresse,
    double? latitude,
    double? longitude,
    List<File> photoFiles = const [],
  }) async {
    final photoUrls = <String>[];
    for (final file in photoFiles) {
      final url = await ApiService.instance.uploadFile('/api/demandes/upload', file);
      photoUrls.add(url);
    }
    await ApiService.instance.post('/api/demandes/', {
      'domaine': domaine,
      'type_prestation': typePrestation,
      'description': description,
      'adresse': adresse,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (photoUrls.isNotEmpty) 'photos': photoUrls.join('|'),
    });
    await fetchData();
  }

  Future<void> acceptDevis(String id) async {
    await ApiService.instance.patch('/api/demandes/$id', {
      'statut': 'reception_bc',
    });
    await fetchData();
  }

  // Refuse a devis via API
  Future<void> refuseDevis(String id) async {
    await ApiService.instance.patch('/api/demandes/$id', {
      'statut': 'annule',
    });
    await fetchData();
  }

  // Submit evaluation via API
  Future<void> evaluateDemande(String id, int rating, String avis) async {
    await ApiService.instance.patch('/api/demandes/$id', {
      'rating': rating,
      'avis': avis,
    });
    await fetchData();
  }

  // Send message from client or support via API
  Future<void> sendClientMessage(String content) async {
    final user = ApiService.instance.currentUser;
    if (user == null) return;

    if (user.role == 'client') {
      await ApiService.instance.post('/api/messages/', {
        'content': content,
      });
    } else {
      if (_activeClientId == null) return;
      await ApiService.instance.post('/api/messages/', {
        'content': content,
        'client_id': _activeClientId,
      });
    }
    await fetchData();
  }
}
