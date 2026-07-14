import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../main.dart' show IsitekColors;
import '../../services/api_service.dart';
import '../providers/devis_provider.dart';
import 'devis_form_screen.dart';
import 'devis_saved_list_screen.dart';
import 'devis_workflow_screens.dart';
import '../../screens/shared/easy_chat_tab.dart';

class DevisHubScreen extends StatefulWidget {
  final int initialTabIndex;

  const DevisHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DevisHubScreen> createState() => _DevisHubScreenState();
}

class _DevisHubScreenState extends State<DevisHubScreen> with SingleTickerProviderStateMixin {
  bool? _apiOk;
  String? _apiError;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 4));
    _checkApi();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkApi() async {
    try {
      await ApiService.instance.getOne('/health');
      if (mounted) setState(() { _apiOk = true; _apiError = null; });
    } catch (e) {
      if (mounted) setState(() { _apiOk = false; _apiError = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DevisProvider()..ajouterProduit(),
      child: Scaffold(
          backgroundColor: IsitekColors.bg,
          appBar: AppBar(
            title: const Text('Devis ISITEK Proforma'),
            backgroundColor: IsitekColors.green,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Vérifier connexion API',
                icon: const Icon(Icons.wifi_find),
                onPressed: _checkApi,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.mail_outline), text: 'Emails'),
                Tab(icon: Icon(Icons.search), text: 'Recherche'),
                Tab(icon: Icon(Icons.description_outlined), text: 'Devis'),
                Tab(icon: Icon(Icons.folder_copy_outlined), text: 'Mes devis'),
                Tab(icon: Icon(Icons.smart_toy_outlined), text: 'Easy'),
              ],
            ),
          ),
          body: Column(
            children: [
              if (_apiOk == false)
                Material(
                  color: Colors.orange.shade100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'API inaccessible (${ApiConfig.baseUrl})\n'
                            'Lancez python run.py sur le PC. Même Wi-Fi. IP correcte dans api_config.dart.\n'
                            '${_apiError ?? ''}',
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                          ),
                        ),
                        TextButton(onPressed: _checkApi, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              if (_apiOk == true)
                const Material(
                  color: Color(0xFFE6F4EC),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: IsitekColors.green, size: 16),
                        SizedBox(width: 8),
                        Text('API connectée', style: TextStyle(fontSize: 11, color: IsitekColors.greenDark)),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const DevisEmailInboxScreen(),
                    const DevisReferenceSearchScreen(),
                    const DevisFormScreen(),
                    DevisSavedListScreen(
                      onOpenInForm: (tab) => _tabController.animateTo(tab),
                    ),
                    const EasyChatTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}
