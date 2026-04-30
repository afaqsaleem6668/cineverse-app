import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'services/app_settings.dart';

class WatchProvidersScreen extends StatefulWidget {
  const WatchProvidersScreen({super.key});

  @override
  State<WatchProvidersScreen> createState() => _WatchProvidersScreenState();
}

class _WatchProvidersScreenState extends State<WatchProvidersScreen>
    with SingleTickerProviderStateMixin {
  static const String _apiKey = 'e850641520c5c6eacf9b2f679e373ff4';
  static const String _base = 'https://api.themoviedb.org/3';

  late TabController _tabController;
  List<Map<String, dynamic>> _movieProviders = [];
  List<Map<String, dynamic>> _tvProviders = [];
  List<Map<String, dynamic>> _regions = [];
  String _selectedRegion = 'PK';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initRegionAndFetch();
  }

  /// Load default region from settings, then fetch providers
  Future<void> _initRegionAndFetch() async {
    final savedRegion = await AppSettings.defaultRegion();
    if (mounted) {
      setState(() => _selectedRegion = savedRegion);
    }
    await _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse(
            '$_base/watch/providers/regions?api_key=$_apiKey')),
        http.get(Uri.parse(
            '$_base/watch/providers/movie?api_key=$_apiKey&watch_region=$_selectedRegion')),
        http.get(Uri.parse(
            '$_base/watch/providers/tv?api_key=$_apiKey&watch_region=$_selectedRegion')),
      ]);

      if (!mounted) return;

      setState(() {
        if (results[0].statusCode == 200) {
          _regions = (jsonDecode(results[0].body)['results'] as List)
              .cast<Map<String, dynamic>>();
        }
        if (results[1].statusCode == 200) {
          _movieProviders = (jsonDecode(results[1].body)['results'] as List)
              .cast<Map<String, dynamic>>();
        }
        if (results[2].statusCode == 200) {
          _tvProviders = (jsonDecode(results[2].body)['results'] as List)
              .cast<Map<String, dynamic>>();
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRegion(String region) async {
    setState(() {
      _selectedRegion = region;
      _loading = true;
    });
    await _fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Streaming Services',
                        style: AppTheme.headingMedium),
                  ),
                  // Region selector
                  GestureDetector(
                    onTap: () => _showRegionPicker(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.accent.withOpacity(0.3),
                            width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.public_rounded,
                              color: AppTheme.accent, size: 14),
                          const SizedBox(width: 5),
                          Text(_selectedRegion,
                              style: GoogleFonts.poppins(
                                  color: AppTheme.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 3),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.accent, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider, width: 0.5),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w400),
                tabs: const [Tab(text: 'Movies'), Tab(text: 'TV Shows')],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accent, strokeWidth: 2))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProviderGrid(_movieProviders),
                        _buildProviderGrid(_tvProviders),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderGrid(List<Map<String, dynamic>> providers) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tv_off_rounded,
                color: AppTheme.textMuted, size: 50),
            const SizedBox(height: 10),
            Text('No providers for $_selectedRegion',
                style: AppTheme.bodyText),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final p = providers[index];
        final logo = p['logo_path'] ?? '';
        final name = p['provider_name'] ?? '';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: logo.isNotEmpty
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w92$logo',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _providerPlaceholder(),
                    )
                  : _providerPlaceholder(),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _providerPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.play_circle_rounded,
          color: AppTheme.textMuted, size: 28),
    );
  }

  void _showRegionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Select Region', style: AppTheme.headingMedium),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _regions.length,
              itemBuilder: (context, index) {
                final r = _regions[index];
                final code = r['iso_3166_1'] ?? '';
                final name = r['english_name'] ?? code;
                final isSelected = code == _selectedRegion;

                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _changeRegion(code);
                  },
                  title: Text(name,
                      style: GoogleFonts.poppins(
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      )),
                  trailing: Text(code,
                      style: GoogleFonts.poppins(
                          color: AppTheme.textMuted, fontSize: 12)),
                  selected: isSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
