import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/etat_lieux_row.dart';
import '../models/rapport_data.dart';
import '../models/rapport_photo.dart';
import '../services/rapport_api_service.dart';
import '../services/rapport_mapper.dart';
import '../theme/app_theme.dart';
import '../widgets/etat_lieux_row_card.dart';
import '../widgets/photo_grid_card.dart';
import '../widgets/section_card.dart';
import 'preview_screen.dart';

class RapportFormScreen extends StatefulWidget {
  final int? rapportId;

  const RapportFormScreen({super.key, this.rapportId});

  @override
  State<RapportFormScreen> createState() => _RapportFormScreenState();
}

class _RapportFormScreenState extends State<RapportFormScreen> {
  final RapportData _data = RapportData();
  final ImagePicker _picker = ImagePicker();

  final _clientCtrl = TextEditingController();
  final _correspondantCtrl = TextEditingController();
  final _typePrestationCtrl = TextEditingController();
  final _typeBatimentCtrl = TextEditingController();
  final _nbCtrl = TextEditingController();
  final _intervenantCtrl = TextEditingController();

  int? _rapportId;
  String? _numeroRapport;
  bool _loading = false;
  bool _saving = false;

  static const List<String> _prestationsSuggestions = [
    'Maintenance préventive',
    'Maintenance curative',
    'Audit technique',
    'Inspection',
    'Dépannage',
    'Mise en service',
  ];

  @override
  void initState() {
    super.initState();
    _rapportId = widget.rapportId;
    if (_rapportId != null) {
      _loadRapport();
    }
  }

  Future<void> _loadRapport() async {
    setState(() => _loading = true);
    try {
      final json = await RapportApiService.instance.get(_rapportId!);
      final data = RapportMapper.fromApi(json);
      _numeroRapport = json['numero_rapport'] as String?;
      _data.date = data.date;
      _data.lignes = data.lignes;
      _data.photos = data.photos;
      _clientCtrl.text = data.client;
      _correspondantCtrl.text = data.correspondantTechnique;
      _typePrestationCtrl.text = data.typePrestation;
      _typeBatimentCtrl.text = data.typeBatiment;
      _nbCtrl.text = data.noteNB;
      _intervenantCtrl.text = data.nomIntervenant;
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chargement : $e'), backgroundColor: AppColors.danger),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _correspondantCtrl.dispose();
    _typePrestationCtrl.dispose();
    _typeBatimentCtrl.dispose();
    _nbCtrl.dispose();
    _intervenantCtrl.dispose();
    super.dispose();
  }

  void _syncControllersToData() {
    _data.client = _clientCtrl.text;
    _data.correspondantTechnique = _correspondantCtrl.text;
    _data.typePrestation = _typePrestationCtrl.text;
    _data.typeBatiment = _typeBatimentCtrl.text;
    _data.noteNB = _nbCtrl.text;
    _data.nomIntervenant = _intervenantCtrl.text;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data.date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _data.date = picked);
    }
  }

  void _addRow() {
    setState(() => _data.lignes.add(EtatLieuxRow()));
  }

  void _removeRow(int index) {
    setState(() => _data.lignes.removeAt(index));
  }

  Future<void> _addPhotos() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGreen),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryGreen),
                title: const Text('Choisir depuis la galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    if (source == ImageSource.gallery) {
      final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        setState(() {
          _data.photos.addAll(picked.map((x) => RapportPhoto.fromLocal(File(x.path))));
        });
      }
    } else {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _data.photos.add(RapportPhoto.fromLocal(File(picked.path)));
        });
      }
    }
  }

  void _removePhoto(int index) {
    setState(() => _data.photos.removeAt(index));
  }

  Future<bool> _saveToDatabase({bool silent = false}) async {
    _syncControllersToData();
    final error = _data.validate();
    if (error != null) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
      return false;
    }

    setState(() => _saving = true);
    try {
      final body = RapportMapper.toApiBody(_data);
      Map<String, dynamic> result;

      if (_rapportId == null) {
        result = await RapportApiService.instance.create(body);
        _rapportId = result['id'] as int;
        _numeroRapport = result['numero_rapport'] as String?;
      } else {
        final updateBody = Map<String, dynamic>.from(body);
        updateBody['photos'] = RapportMapper.remotePhotosPayload(_data.photos);
        result = await RapportApiService.instance.update(_rapportId!, updateBody);
        _numeroRapport = result['numero_rapport'] as String?;
      }

      final newPhotos = _data.photos.where((p) => p.needsUpload).toList();
      for (final photo in newPhotos) {
        if (photo.file == null || _rapportId == null) continue;
        final uploaded = await RapportApiService.instance.uploadPhoto(
          _rapportId!,
          photo.file!,
          photo.legende,
        );
        final serverPhotos = (uploaded['photos'] as List?) ?? [];
        final last = serverPhotos.isNotEmpty ? serverPhotos.last as Map : null;
        if (last != null) {
          photo.remotePath = last['path'] as String?;
          photo.file = null;
        }
      }

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport enregistré (${_numeroRapport ?? ''})'),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enregistrement : $e'), backgroundColor: AppColors.danger),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _goToPreview() async {
    _syncControllersToData();
    final error = _data.validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final saved = await _saveToDatabase(silent: true);
    if (!saved || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          data: _data,
          numeroRapport: _numeroRapport,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _rapportId != null;
    final title = isEdit
        ? 'Modifier rapport${_numeroRapport != null ? ' · $_numeroRapport' : ''}'
        : 'Nouveau rapport';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              tooltip: 'Enregistrer',
              onPressed: _saveToDatabase,
              icon: const Icon(Icons.save_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 110),
        children: [
          SectionCard(
            title: 'Informations générales',
            icon: Icons.info_outline,
            child: Column(
              children: [
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de la visite',
                      isDense: true,
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryGreen),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_data.date),
                      style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clientCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Client *',
                    hintText: "Nom de l'entreprise ou du client",
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _correspondantCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correspondant technique *',
                    hintText: 'Nom de votre interlocuteur sur place',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _typePrestationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Type de prestation *',
                    hintText: 'Ex: Maintenance curative, Audit...',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _prestationsSuggestions.map((s) {
                    return ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 11.5)),
                      backgroundColor: AppColors.lightGreen,
                      side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.25)),
                      onPressed: () {
                        _typePrestationCtrl.text = s;
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _typeBatimentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Type de bâtiment / Ouvrage',
                    hintText: 'Ex: Poste de transformation, TGBT...',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'État des lieux',
            icon: Icons.fact_check_outlined,
            child: Column(
              children: [
                ...List.generate(_data.lignes.length, (index) {
                  return EtatLieuxRowCard(
                    key: ValueKey(_data.lignes[index].id),
                    row: _data.lignes[index],
                    index: index,
                    canDelete: _data.lignes.length > 1,
                    onDelete: () => _removeRow(index),
                    onChanged: () {},
                  );
                }),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter une ligne'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Remarque (NB)',
            icon: Icons.priority_high_rounded,
            child: TextField(
              controller: _nbCtrl,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Saisissez ici une remarque générale (apparaîtra sous le tableau, précédée de "NB :")',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Photos',
            icon: Icons.photo_camera_outlined,
            trailing: Text(
              '${_data.photos.length}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
            child: Column(
              children: [
                if (_data.photos.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _data.photos.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, index) {
                      final photo = _data.photos[index];
                      return PhotoGridCard(
                        key: ValueKey(photo.id),
                        photo: photo,
                        onDelete: () => _removePhoto(index),
                        onLegendeChanged: (v) => photo.legende = v,
                      );
                    },
                  ),
                if (_data.photos.isNotEmpty) const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addPhotos,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Ajouter des photos'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Signature',
            icon: Icons.edit_outlined,
            child: TextField(
              controller: _intervenantCtrl,
              decoration: const InputDecoration(
                labelText: "Nom de l'intervenant",
                hintText: 'Apparaîtra sous "SERVICE COMMERCIAL" (aligné à droite)',
                isDense: true,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _saveToDatabase,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Enregistrer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _goToPreview,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 19),
                  label: const Text('Aperçu PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
