import 'package:flutter/material.dart';
import '../../main.dart' show IsitekColors;
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import 'admin_authorized_phones_tab.dart';
import '../../utils/role_labels.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await ApiService.instance.listUsers();
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  List<UserModel> _filter(String role) {
    return _users.where((u) {
      if (u.role != role) return false;
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          (u.telephone ?? '').contains(q) ||
          (u.poste ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _toggleActive(UserModel user) async {
    try {
      await ApiService.instance.updateUser(user.id, {'is_active': !user.isActive});
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(user.isActive ? 'Compte désactivé' : 'Compte réactivé')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Text('Supprimer définitivement ${user.fullName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.deleteUser(user.id);
      await _loadUsers();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte supprimé')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _editUser(UserModel user) async {
    final nomCtrl = TextEditingController(text: user.nom);
    final prenomCtrl = TextEditingController(text: user.prenom);
    final phoneCtrl = TextEditingController(text: user.telephone ?? '');
    final posteCtrl = TextEditingController(text: user.poste ?? '');
    final emailCtrl = TextEditingController(text: user.email);
    String role = user.role;
    bool canCreateAffaire = user.canCreateAffaire;
    bool canCreateDevis = user.canCreateDevis;
    bool canCreateRapport = user.canCreateRapport;
    bool canManageActionsInternes = user.canManageActionsInternes;
    bool canAccessCaisse = user.canAccessCaisse;
    bool canCaisseControle = user.canCaisseControle;
    bool canCaisseLivre = user.canCaisseLivre;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: Text('Modifier ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: prenomCtrl, decoration: const InputDecoration(labelText: 'Prénom')),
              TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Téléphone')),
              TextField(controller: emailCtrl, enabled: false, decoration: const InputDecoration(labelText: 'Email')),
              if (user.role != 'client') ...[
                TextField(controller: posteCtrl, decoration: const InputDecoration(labelText: 'Rôle dans l\'entreprise')),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Type de compte'),
                  items: const [
                    DropdownMenuItem(value: 'technicien', child: Text('Employé')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v ?? role),
                ),
                const Divider(height: 24),
                const Text('Autorisations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SwitchListTile(
                  title: const Text('Créer des dossiers d\'affaire'),
                  value: canCreateAffaire,
                  activeColor: IsitekColors.green,
                  onChanged: (v) => setDialogState(() => canCreateAffaire = v),
                ),
                SwitchListTile(
                  title: const Text('Créer des devis proforma'),
                  value: canCreateDevis,
                  activeColor: IsitekColors.green,
                  onChanged: (v) => setDialogState(() => canCreateDevis = v),
                ),
                SwitchListTile(
                  title: const Text('Générer des rapports de visite'),
                  value: canCreateRapport,
                  activeColor: IsitekColors.green,
                  onChanged: (v) => setDialogState(() => canCreateRapport = v),
                ),
                SwitchListTile(
                  title: const Text('Gérer les actions internes'),
                  value: canManageActionsInternes,
                  activeColor: IsitekColors.green,
                  onChanged: (v) => setDialogState(() => canManageActionsInternes = v),
                ),
                const Divider(height: 8),
                const Text('Module Caisse', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SwitchListTile(
                  title: const Text('Accès Caisse (complet)'),
                  subtitle: const Text('Fiche contrôle + livre hebdomadaire'),
                  value: canAccessCaisse,
                  activeColor: IsitekColors.green,
                  onChanged: (v) => setDialogState(() => canAccessCaisse = v),
                ),
                SwitchListTile(
                  title: const Text('Fiche contrôle caisse uniquement'),
                  value: canCaisseControle,
                  activeColor: IsitekColors.green,
                  onChanged: (v) => setDialogState(() => canCaisseControle = v),
                ),
                SwitchListTile(
                  title: const Text('Livre de caisse uniquement'),
                  value: canCaisseLivre,
                  activeColor: IsitekColors.green,
                  onChanged: (v) => setDialogState(() => canCaisseLivre = v),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
      ),
    );

    if (saved != true) return;

    try {
      final body = <String, dynamic>{
        'nom': nomCtrl.text.trim(),
        'prenom': prenomCtrl.text.trim(),
        'telephone': phoneCtrl.text.trim(),
      };
      if (user.role != 'client') {
        body['poste'] = posteCtrl.text.trim();
        body['role'] = role;
        body['can_create_affaire'] = canCreateAffaire;
        body['can_create_devis'] = canCreateDevis;
        body['can_create_rapport'] = canCreateRapport;
        body['can_manage_actions_internes'] = canManageActionsInternes;
        body['can_access_caisse'] = canAccessCaisse;
        body['can_caisse_controle'] = canCaisseControle;
        body['can_caisse_livre'] = canCaisseLivre;
      }
      await ApiService.instance.updateUser(user.id, body);
      await _loadUsers();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur mis à jour')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Employés'),
            Tab(text: 'Clients'),
            Tab(text: 'Admins'),
            Tab(text: 'Téléphones'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_filter('technicien')),
                      _buildList(_filter('client')),
                      _buildList(_filter('admin')),
                      AdminAuthorizedPhonesTab(key: ValueKey('phones')),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text('Aucun utilisateur trouvé'));
    }
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: user.isActive ? IsitekColors.greenSoft : Colors.grey[300],
                child: Text(
                  user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: user.isActive ? IsitekColors.greenDark : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayRole(user.poste, user.role), style: TextStyle(color: IsitekColors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(user.email, style: const TextStyle(fontSize: 12)),
                  if (user.telephone != null) Text(user.telephone!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  if (user.role == 'technicien' && user.canCreateDevis)
                    const Text('✓ Peut créer des devis', style: TextStyle(color: IsitekColors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                  if (user.role == 'technicien' && user.canCreateRapport)
                    const Text('✓ Peut générer des rapports', style: TextStyle(color: IsitekColors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                  if (user.role == 'technicien' && user.canCreateAffaire)
                    const Text('✓ Peut créer des affaires', style: TextStyle(color: IsitekColors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                  if (!user.isActive)
                    const Text('Désactivé', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _editUser(user);
                  if (action == 'toggle') _toggleActive(user);
                  if (action == 'delete') _deleteUser(user);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(user.isActive ? 'Désactiver' : 'Réactiver'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
