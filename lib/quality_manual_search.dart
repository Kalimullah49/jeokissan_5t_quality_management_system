import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'quality_manual_service.dart';
import 'locale_provider.dart';
import 'app_localizations.dart';

class QualityManualSearch extends StatefulWidget {
  const QualityManualSearch({super.key});

  @override
  State<QualityManualSearch> createState() => _QualityManualSearchState();
}

class _QualityManualSearchState extends State<QualityManualSearch> {
  late QualityManualService _service;
  final TextEditingController _searchController = TextEditingController();
  CommodityQualityData? _searchResult;
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;
  String _lastLanguage = 'en';

  final List<String> _commonCommodities = [
    'Sindhri',
    'Chaunsa',
    'Anwar Ratol',
    'Dasheri',
    'Langra',
  ];

  @override
  void initState() {
    super.initState();
    _service = QualityManualService();
    _initializeService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeProvider = context.watch<LocaleProvider>();
    final currentLanguage = localeProvider.isUrdu ? 'ur' : 'en';
    
    // Reload if language changed
    if (currentLanguage != _lastLanguage) {
      _lastLanguage = currentLanguage;
      // Create new service instance for new language
      _service = QualityManualService();
      _initializeService();
    }
  }

  Future<void> _initializeService() async {
    try {
      final localeProvider = context.read<LocaleProvider>();
      final language = localeProvider.isUrdu ? 'ur' : 'en';
      
      await _service.initialize(language: language);
      setState(() {
        _initialized = true;
        _searchResult = null; // Clear previous search results
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Quality Manual. Please try again.';
        _initialized = false;
      });
    }
  }

  Future<void> _searchCommodity(String commodityName) async {
    if (commodityName.isEmpty) {
      setState(() {
        _searchResult = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.searchCommodity(commodityName);
      setState(() {
        _searchResult = result;
        _isLoading = false;
        if (result == null) {
          _error = 'Commodity not found. Please try another search.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error searching commodity: $e';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.qualityManual,
          style: TextStyle(
            fontFamily: localeProvider.fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2C5F2D),
        elevation: 0,
      ),
      body: !_initialized
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2C5F2D)),
                  SizedBox(height: 16),
                  Text(
                    'Loading Quality Manual...',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search TextField
                    TextField(
                      controller: _searchController,
                      onChanged: _searchCommodity,
                      decoration: InputDecoration(
                        hintText: loc.searchCommodity,
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontFamily: localeProvider.fontFamily,
                        ),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF2C5F2D)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF2C5F2D), width: 2),
                        ),
                      ),
                      style: TextStyle(fontFamily: localeProvider.fontFamily),
                    ),
                    SizedBox(height: 24),

                    // Quick Search Commodities
                    if (_searchResult == null && _error == null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.quickSearch,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontFamily: localeProvider.fontFamily,
                            ),
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._commonCommodities
                                  .map((commodity) => GestureDetector(
                                        onTap: () {
                                          _searchController.text = commodity;
                                          _searchCommodity(commodity);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF2C5F2D).withValues(alpha: 0.1),
                                            border: Border.all(
                                              color: Color(0xFF2C5F2D),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            commodity,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF2C5F2D),
                                              fontWeight: FontWeight.w500,
                                              fontFamily: localeProvider.fontFamily,
                                            ),
                                          ),
                                        ),
                                      )),
                            ],
                          ),
                          SizedBox(height: 24),
                        ],
                      ),

                    // Loading State
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2C5F2D),
                        ),
                      ),

                    // Error State
                    if (_error != null && !_isLoading)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                            fontFamily: localeProvider.fontFamily,
                          ),
                        ),
                      ),

                    // Search Results
                    if (_searchResult != null && !_isLoading) ...[
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2C5F2D).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF2C5F2D).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _searchResult!.commodityName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C5F2D),
                            fontFamily: localeProvider.fontFamily,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ..._searchResult!.tiers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final tier = entry.value;
                        final tierColors = [
                          Color(0xFF1B5E20), // Excellent - Dark Green
                          Color(0xFF2E7D32), // Very Good - Green
                          Color(0xFF558B2F), // Good - Light Green
                          Color(0xFFF57F17), // Satisfactory - Amber
                          Color(0xFFD32F2F), // Unsatisfactory - Red
                        ];

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border(
                                  left: BorderSide(
                                    color: tierColors[index],
                                    width: 4,
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tierColors[index].withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tier.tier,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: tierColors[index],
                                        fontFamily: localeProvider.fontFamily,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    localeProvider.isUrdu ? 'تفصیلات:' : 'Physical Specifications:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                      fontFamily: localeProvider.fontFamily,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    tier.attributes,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                      height: 1.6,
                                      fontFamily: localeProvider.fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
