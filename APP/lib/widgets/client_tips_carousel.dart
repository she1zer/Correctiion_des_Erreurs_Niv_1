import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../main.dart' show IsitekColors;
import '../models/client_tip.dart';
import '../models/astuce_model.dart';
import '../services/astuce_api_service.dart';

class ClientTipsCarousel extends StatefulWidget {
  final bool loadFromApi;
  final bool showHeader;

  const ClientTipsCarousel({
    super.key,
    this.loadFromApi = false,
    this.showHeader = true,
  });

  @override
  State<ClientTipsCarousel> createState() => _ClientTipsCarouselState();
}

class _ClientTipsCarouselState extends State<ClientTipsCarousel> {
  final _pageController = PageController(viewportFraction: 0.88);
  int _activeIndex = 0;
  String? _selectedCategory;
  Timer? _autoPlayTimer;
  bool _autoPlayPaused = false;
  List<ClientTip> _tips = List.from(clientTips);
  bool _loadingApi = false;

  List<ClientTip> get _filteredTips {
    if (_selectedCategory == null) return _tips;
    return _tips.where((t) => t.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.loadFromApi) {
      _loadFromApi();
    } else {
      _startAutoPlay();
    }
  }

  Future<void> _loadFromApi() async {
    setState(() => _loadingApi = true);
    try {
      final list = await AstuceApiService.instance.listActive();
      if (list.isNotEmpty && mounted) {
        setState(() {
          _tips = list
              .map((e) => AstuceModel.fromApi(Map<String, dynamic>.from(e as Map)).toClientTip())
              .toList();
        });
      }
    } catch (_) {
      // Garde le fallback local clientTips
    } finally {
      if (mounted) {
        setState(() => _loadingApi = false);
        _startAutoPlay();
      }
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _autoPlayPaused || _filteredTips.isEmpty) return;
      final next = (_activeIndex + 1) % _filteredTips.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _pauseAutoPlay() {
    setState(() => _autoPlayPaused = true);
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _autoPlayPaused = false);
    });
  }

  void _showTipDetail(ClientTip tip) {
    _pauseAutoPlay();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TipDetailSheet(tip: tip),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tips = _filteredTips;
    final categories = _tips.map((t) => t.category).toSet().toList();

    if (_loadingApi) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: IsitekColors.green)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [IsitekColors.green, IsitekColors.greenDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: IsitekColors.green.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text('💡', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Astuces ISITEK',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: IsitekColors.textDark,
                      ),
                    ),
                    Text(
                      'Conseils pratiques pour votre maison & bureau',
                      style: TextStyle(fontSize: 12, color: IsitekColors.textSoft),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _autoPlayPaused ? 'Reprendre' : 'Pause',
                onPressed: () {
                  setState(() => _autoPlayPaused = !_autoPlayPaused);
                },
                icon: Icon(
                  _autoPlayPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
                  color: IsitekColors.green,
                ),
              ),
            ],
          ),
        ),
        if (widget.showHeader) const SizedBox(height: 14),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _CategoryChip(
                label: 'Tout',
                selected: _selectedCategory == null,
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                    _activeIndex = 0;
                  });
                  _pageController.jumpToPage(0);
                  _startAutoPlay();
                },
              ),
              ...categories.map(
                (cat) => _CategoryChip(
                  label: cat,
                  selected: _selectedCategory == cat,
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                      _activeIndex = 0;
                    });
                    _pageController.jumpToPage(0);
                    _startAutoPlay();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (tips.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Aucune astuce dans cette catégorie')),
          )
        else
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemCount: tips.length,
              onPageChanged: (i) => setState(() => _activeIndex = i),
              itemBuilder: (context, index) {
                final tip = tips[index];
                final isActive = index == _activeIndex;
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.94,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _TipCard(
                    tip: tip,
                    isActive: isActive,
                    onTap: () => _showTipDetail(tip),
                    onLike: () {
                      _pauseAutoPlay();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${tip.emoji} Astuce enregistrée !'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(tips.length, (i) {
            final active = i == _activeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(colors: [IsitekColors.green, IsitekColors.greenDark])
                    : null,
                color: active ? null : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Glissez ou touchez une carte pour en savoir plus',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(colors: [IsitekColors.green, IsitekColors.greenDark])
                  : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? Colors.transparent : Colors.grey.shade200,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: IsitekColors.green.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : IsitekColors.textSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatefulWidget {
  final ClientTip tip;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _TipCard({
    required this.tip,
    required this.isActive,
    required this.onTap,
    required this.onLike,
  });

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: tip.accent.withOpacity(widget.isActive ? 0.22 : 0.08),
              blurRadius: widget.isActive ? 20 : 8,
              offset: Offset(0, widget.isActive ? 8 : 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tip.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      tip.icon,
                      size: 100,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  Positioned(
                    left: -15,
                    bottom: -15,
                    child: Icon(
                      tip.icon,
                      size: 70,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final offset = math.sin(_floatController.value * math.pi * 2) * 6;
                      return Transform.translate(
                        offset: Offset(0, offset),
                        child: child,
                      );
                    },
                    child: Center(
                      child: Text(
                        tip.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        tip.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white.withOpacity(0.2),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          setState(() => _liked = !_liked);
                          widget.onLike();
                        },
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _liked ? Colors.red.shade100 : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: tip.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        tip.summary,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: IsitekColors.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.touch_app_rounded, size: 14, color: tip.accent.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(
                          'Toucher pour détails',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tip.accent.withOpacity(0.8),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: tip.accent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _TipDetailSheet extends StatelessWidget {
  final ClientTip tip;

  const _TipDetailSheet({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: tip.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(tip.icon, size: 120, color: Colors.white.withOpacity(0.15)),
                Text(tip.emoji, style: const TextStyle(fontSize: 72)),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tip.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tip.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tip.accent,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${tip.emoji} ${tip.title}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: tip.accent,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  tip.detail,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: IsitekColors.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Compris !', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tip.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
