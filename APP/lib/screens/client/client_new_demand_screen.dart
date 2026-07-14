import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/demande_service.dart';
import '../../main.dart' show IsitekColors;
import '../../navigation/root_navigator.dart';
import '../../widgets/map_picker_widget.dart';

class ClientNewDemandScreen extends StatefulWidget {
  final String? initialDomain;
  const ClientNewDemandScreen({super.key, this.initialDomain});

  @override
  State<ClientNewDemandScreen> createState() => _ClientNewDemandScreenState();
}

class _ClientNewDemandScreenState extends State<ClientNewDemandScreen> {
  int _currentStep = 1; // 1: Domaine, 2: Prestation, 3: Success

  // Form states
  String _selectedDomain = 'Électricité générale';
  String _selectedPrestation = 'Dépannage';
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();
  final List<File> _photos = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  double? _latitude;
  double? _longitude;

  final List<String> _domains = [
    'Électricité générale',
    'Électronique',
    'Informatique',
    'Plomberie',
    'Menuiserie',
  ];

  final List<String> _prestations = [
    'Dépannage',
    'Devis',
    'Travaux',
    'Vente mat.',
    'Assistance',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDomain != null) {
      // Map to exact list domain if match
      final match = _domains.firstWhere(
        (d) => d.toLowerCase().contains(widget.initialDomain!.toLowerCase()) || widget.initialDomain!.toLowerCase().contains(d.toLowerCase()),
        orElse: () => _domains.first,
      );
      _selectedDomain = match;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _photos.add(File(pickedFile.path));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo ajoutée avec succès'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de la photo: $e')),
      );
    }
  }

  Future<void> _submitDemand() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez fournir une description de votre besoin.')),
      );
      return;
    }
    if (_adresseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer une adresse d\'intervention.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await DemandeService.instance.addDemande(
        domaine: _selectedDomain,
        typePrestation: _selectedPrestation,
        description: _descriptionController.text.trim(),
        adresse: _adresseController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        photoFiles: _photos,
      );
      if (!mounted) return;
      setState(() => _currentStep = 3);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi : $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _currentStep == 3
              ? 'Succès'
              : (_currentStep == 2 ? 'Détails de la demande' : 'Nouvelle demande'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: IsitekColors.textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Domaine();
      case 2:
        return _buildStep2Prestation();
      case 3:
      default:
        return _buildStep3Success();
    }
  }

  // STEP 1 : Sélection du domaine (Écran 2)
  Widget _buildStep1Domaine() {
    return Column(
      key: const ValueKey('step1'),
      children: [
        // Stepper Badge
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: IsitekColors.greenSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Étape 1 / 3 — Domaine',
              style: TextStyle(
                color: IsitekColors.greenDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        
        // Subtitle
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sélectionnez votre domaine :',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: IsitekColors.textDark,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Domains list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _domains.length,
            itemBuilder: (context, index) {
              final domain = _domains[index];
              final isSelected = _selectedDomain == domain;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? IsitekColors.green : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Icon(
                    _getDomainIcon(domain),
                    color: isSelected ? IsitekColors.green : IsitekColors.textSoft,
                  ),
                  title: Text(
                    domain,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? IsitekColors.greenDark : IsitekColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: IsitekColors.green)
                      : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    setState(() {
                      _selectedDomain = domain;
                    });
                  },
                ),
              );
            },
          ),
        ),

        // Bottom Action Button
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: IsitekColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                setState(() => _currentStep = 2);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Suivant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2 : Prestation et détails (Écran 3)
  Widget _buildStep2Prestation() {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stepper Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: IsitekColors.greenSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Étape 2 / 3 — Prestation',
                style: TextStyle(
                  color: IsitekColors.greenDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle Type de prestation
          const Text(
            'Type de prestation :',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
          ),
          const SizedBox(height: 10),

          // Horizontal Tags selection
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _prestations.length,
              itemBuilder: (context, index) {
                final prest = _prestations[index];
                final isSelected = _selectedPrestation == prest;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: FilterChip(
                    label: Text(prest),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPrestation = prest;
                      });
                    },
                    selectedColor: IsitekColors.green,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : IsitekColors.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Description input
          const Text(
            'Description :',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Panne électrique dans le salon, disjoncteur qui saute...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Adresse input
          const Text(
            'Adresse :',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _adresseController,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cocody, Riviera 3, Abidjan',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.location_on_outlined, color: IsitekColors.green, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.map_outlined, color: IsitekColors.green),
                tooltip: 'Choisir sur la carte',
                onPressed: () async {
                  final result = await Navigator.push<MapPickerResult>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapPickerWidget(
                        initialLatitude: _latitude,
                        initialLongitude: _longitude,
                        initialAddress: _adresseController.text,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _latitude = result.latitude;
                      _longitude = result.longitude;
                      if (_adresseController.text.trim().isEmpty) {
                        _adresseController.text = result.address;
                      }
                    });
                  }
                },
              ),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          if (_latitude != null && _longitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 14, color: IsitekColors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Position GPS : ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Photos input mockup
          const Text(
            'Ajouter une ou des images descriptifs de la situation :',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Camera Button
              GestureDetector(
                onTap: () => _pickPhoto(ImageSource.camera),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: IsitekColors.textSoft, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              // Plus Button
              GestureDetector(
                onTap: () => _pickPhoto(ImageSource.gallery),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: const Icon(Icons.add_rounded, color: IsitekColors.green, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              // Display real photos
              Expanded(
                child: SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: IsitekColors.greenSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: IsitekColors.green.withOpacity(0.3)),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _photos[index],
                                  fit: BoxFit.cover,
                                  width: 70,
                                  height: 70,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Icon(Icons.image_outlined, color: IsitekColors.green));
                                  },
                                ),
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _photos.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.close_rounded, size: 12, color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Send button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: IsitekColors.greenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _isSubmitting ? null : _submitDemand,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Envoyer la demande', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3 : Succès (Écran de transition)
  Widget _buildStep3Success() {
    return Center(
      key: const ValueKey('step3'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Checkmark Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: IsitekColors.greenSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: IsitekColors.green,
                size: 80,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.bounceOut),
            const SizedBox(height: 32),

            // Titles
            const Text(
              'Demande envoyée !',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Votre demande a été enregistrée avec succès. Notre équipe va étudier votre besoin et vous soumettre un devis d\'ici quelques instants.',
              style: TextStyle(fontSize: 14, color: IsitekColors.textSoft, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Button to follow demands
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: IsitekColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  // Switch RootNavigator to index 1 (Demandes)
                  final rootNav = context.findAncestorStateOfType<RootNavigatorState>();
                  if (rootNav != null) {
                    rootNav.setIndex(1);
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Suivre ma demande', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDomainIcon(String domain) {
    switch (domain) {
      case 'Électricité générale':
        return Icons.bolt_rounded;
      case 'Électronique':
        return Icons.memory_rounded;
      case 'Informatique':
        return Icons.computer_rounded;
      case 'Plomberie':
        return Icons.build_rounded;
      case 'Menuiserie':
      default:
        return Icons.handyman_rounded;
    }
  }
}
