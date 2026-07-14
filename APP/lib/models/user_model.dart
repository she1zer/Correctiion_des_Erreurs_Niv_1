class UserModel {
  final int id;
  final String email;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? poste;
  final double? latitude;
  final double? longitude;
  final String role;
  final bool isActive;
  final bool canCreateAffaire;
  final bool canCreateDevis;
  final bool canCreateRapport;
  final bool canManageActionsInternes;
  final bool canAccessCaisse;
  final bool canCaisseControle;
  final bool canCaisseLivre;

  UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.poste,
    this.latitude,
    this.longitude,
    required this.role,
    required this.isActive,
    this.canCreateAffaire = false,
    this.canCreateDevis = false,
    this.canCreateRapport = false,
    this.canManageActionsInternes = false,
    this.canAccessCaisse = false,
    this.canCaisseControle = false,
    this.canCaisseLivre = false,
  });

  String get fullName => '$prenom $nom';

  bool get isAdmin => role == 'admin';
  bool get isTechnicien => role == 'technicien' || role == 'admin';
  bool get isClient => role == 'client';

  bool get canCreateAffaireEffective => isAdmin || canCreateAffaire;
  bool get canCreateDevisEffective => isAdmin || canCreateDevis;
  bool get canCreateRapportEffective => isAdmin || canCreateRapport;
  bool get canManageActionsInternesEffective => isAdmin || canManageActionsInternes;
  bool get canAccessCaisseEffective => isAdmin || canAccessCaisse || canCaisseControle || canCaisseLivre;
  bool get canCaisseControleEffective => isAdmin || canAccessCaisse || canCaisseControle;
  bool get canCaisseLivreEffective => isAdmin || canAccessCaisse || canCaisseLivre;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: json['email'] as String,
        nom: json['nom'] as String,
        prenom: json['prenom'] as String,
        telephone: json['telephone'] as String?,
        poste: json['poste'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        role: json['role'] as String,
        isActive: json['is_active'] as bool? ?? true,
        canCreateAffaire: json['can_create_affaire'] as bool? ?? false,
        canCreateDevis: json['can_create_devis'] as bool? ?? false,
        canCreateRapport: json['can_create_rapport'] as bool? ?? false,
        canManageActionsInternes: json['can_manage_actions_internes'] as bool? ?? false,
        canAccessCaisse: json['can_access_caisse'] as bool? ?? false,
        canCaisseControle: json['can_caisse_controle'] as bool? ?? false,
        canCaisseLivre: json['can_caisse_livre'] as bool? ?? false,
      );
}
