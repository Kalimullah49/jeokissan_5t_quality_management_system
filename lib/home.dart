import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:jeokissan_5t_quality_management_system/preview_image.dart';
import 'package:jeokissan_5t_quality_management_system/gemini_service.dart';
import 'package:jeokissan_5t_quality_management_system/questions_screen.dart';
import 'package:jeokissan_5t_quality_management_system/classification_result.dart';
import 'package:jeokissan_5t_quality_management_system/settings_screen.dart';
import 'package:jeokissan_5t_quality_management_system/app_localizations.dart';
import 'package:jeokissan_5t_quality_management_system/locale_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  // Quality image paths
  final List<String> _qualityImages = [
    'assets/images/Excellent.webp',
    'assets/images/Very Good.webp',
    'assets/images/Good.webp',
    'assets/images/Satisfactory.webp',
    'assets/images/Unsatisfactory.webp',
  ];

  // Badge colors
  final List<Color> _qualityColors = [
    const Color(0xFF2E7D32), // Excellent - Dark Green
    const Color(0xFF66BB6A), // Very Good - Green
    const Color(0xFFFDD835), // Good - Yellow
    const Color(0xFFFFB74D), // Satisfactory - Orange
    const Color(0xFFEF5350), // Rotten - Red
  ];

  Future<void> _handleImagePick(ImageSource source) async {
    // [Keep existing logic exactly as provided in your snippet]
    try {
      List<XFile> images = [];
      if (source == ImageSource.gallery) {
        images = await _picker.pickMultiImage();
      } else {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) images = [image];
      }
      
      if (images.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewImageScreen(
              imageFiles: images,
              onClassify: () async {
                final loc = AppLocalizations.of(context);
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFF4CAF50)),
                            const SizedBox(height: 16),
                            Text(loc.analyzingImages, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: loc.fontFamily)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                try {
                  // Read bytes
                  final List<Uint8List> bytesList = [];
                  final List<String> fileNames = [];
                  for (final img in images) {
                    bytesList.add(await img.readAsBytes());
                    fileNames.add(img.name);
                  }

                  if (!mounted) return;

                  // STEP 1
                  final localeProvider = context.read<LocaleProvider>();
                  final languageCode = localeProvider.isUrdu ? 'ur' : 'en';
                  
                  final step1Result = await GeminiClassificationService.analyzeAndAskQuestions(
                    imageBytesList: bytesList,
                    fileNames: fileNames,
                    languageCode: languageCode,
                  );

                  if (!mounted) return;

                  if (context.mounted) Navigator.pop(context);

                  final commodity = step1Result['commodity'] as String? ?? 'Unknown';
                  final assessment = step1Result['preliminary_assessment'] as String? ?? '';
                  final questions = List<Map<String, dynamic>>.from(step1Result['questions'] ?? []);

                  if (context.mounted && questions.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuestionsScreen(
                          commodity: commodity,
                          preliminaryAssessment: assessment,
                          questions: questions,
                          imageFiles: images,
                          imageBytesList: bytesList,
                          fileNames: fileNames,
                          onSubmit: (questionsAndAnswers) async {
                             final loc2 = AppLocalizations.of(context);
                             // Show loading dialog
                             showDialog(
                               context: context,
                               barrierDismissible: false,
                               builder: (ctx) => Center(
                                 child: Card(
                                   child: Padding(
                                     padding: const EdgeInsets.all(32),
                                     child: Column(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         const CircularProgressIndicator(color: Color(0xFF4CAF50)),
                                         const SizedBox(height: 16),
                                         Text(loc2.gettingFinalClassification, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: loc2.fontFamily)),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                             );

                             try {
                               final localeProvider2 = context.read<LocaleProvider>();
                               final languageCode2 = localeProvider2.isUrdu ? 'ur' : 'en';
                               
                               final result = await GeminiClassificationService.classifyWithAnswers(
                                 imageBytesList: bytesList,
                                 fileNames: fileNames,
                                 commodity: commodity,
                                 questionsAndAnswers: questionsAndAnswers,
                                 languageCode: languageCode2,
                               );

                               if (!context.mounted) return;

                               if (context.mounted) Navigator.pop(context); // dismiss loading

                               final tier = result['tier'] as String? ?? 'Unknown';
                               final reasons = List<String>.from(result['reasons'] ?? []);

                               if (context.mounted) {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => ClassificationResultScreen(
                                       qualityRating: tier,
                                       reasons: reasons,
                                       imageFiles: images,
                                       onDone: () {
                                         // Pop all the way back to home
                                         Navigator.of(context).popUntil((route) => route.isFirst);
                                       },
                                       onClassifyAnother: () {
                                         Navigator.of(context).popUntil((route) => route.isFirst);
                                         _showImageSourceDialog();
                                       },
                                     ),
                                   ),
                                 );
                               }
                             } catch (e) {
                               if (context.mounted) Navigator.pop(context); // dismiss loading
                               if (context.mounted) {
                                 final errorMsg = e.toString();
                                 String displayMsg;
                                 if (errorMsg.contains('NOT_AGRICULTURAL') || errorMsg.contains('agricultural commodity')) {
                                   displayMsg = loc2.notAgriculturalImage;
                                 } else {
                                   displayMsg = '${loc2.classificationFailed}: $errorMsg';
                                 }
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                     content: Text(displayMsg),
                                     backgroundColor: Colors.red,
                                     duration: const Duration(seconds: 5),
                                   ),
                                 );
                               }
                             }
                          },
                        ),
                      ),
                    );
                  }
                } catch (e) {
                   if (context.mounted) Navigator.pop(context);
                   if (context.mounted) {
                     final errLoc = AppLocalizations.of(context);
                     final errorMsg = e.toString();
                     String displayMsg;
                     if (errorMsg.contains('NOT_AGRICULTURAL') || errorMsg.contains('agricultural commodity')) {
                       displayMsg = errLoc.notAgriculturalImage;
                     } else {
                       displayMsg = '${errLoc.analysisFailed}: $errorMsg';
                     }
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text(displayMsg),
                         backgroundColor: Colors.red,
                         duration: const Duration(seconds: 5),
                       ),
                     );
                   }
                }
              },
              onRetake: () {
                Navigator.pop(context);
                _handleImagePick(source);
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showImageSourceDialog() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.selectImageSource,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: loc.camera,
                  onTap: () {
                    Navigator.pop(context);
                    _handleImagePick(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: loc.gallery,
                  onTap: () {
                    Navigator.pop(context);
                    _handleImagePick(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Screen Height helper
    final screenHeight = MediaQuery.of(context).size.height;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ============================================
            // 1. Header Bar
            // ============================================
            Container(
              height: 60,
              width: double.infinity,
              color: const Color(0xFF4CAF50), // Jeokissan Green
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    loc.jeokissan,
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.book, color: Colors.white),
                          tooltip: 'Quality Manual',
                          onPressed: () {
                            Navigator.pushNamed(context, '/quality-manual');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ============================================
            // 2. Main Body Content
            // ============================================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    
                    // A. Fruit Image
                    // -------------------------
                    Container(
                      constraints: BoxConstraints(maxHeight: screenHeight * 0.40),
                      child: Image.asset(
                        'assets/images/Fruit.png',
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, _, _) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),

                    // B. Start Inspection Card (The Green Stack)
                    // -------------------------
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: SizedBox(
                        height: 260, // Total height for the stack
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // The Card Background
                            Container(
                              height: 200, // Slightly shorter to let icon float top
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF66BB6A), // Lighter green for card
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    loc.startInspection,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    loc.startInspectionDesc,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // The Floating Camera Icon
                            Positioned(
                              top: 0,
                              child: Container(
                                height: 110,
                                width: 110,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF66BB6A), // Same as card
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // C. Bottom Quality Row
                    // -------------------------
                    SizedBox(
                      height: 110,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) => _buildQualityItem(index, loc)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityItem(int index, AppLocalizations loc) {
    final labels = loc.qualityLabels;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                     BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                child: Stack(
                  children: [
                    // Image
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _qualityImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, _) => Container(color: Colors.grey[200]),
                        ),
                      ),
                    ),
                    // Pill Badge
                    Positioned(
                      bottom: 5,
                      left: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: _qualityColors[index],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              index < 2 ? Icons.check_circle : Icons.cancel,
                              color: Colors.white,
                              size: 8,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                labels[index],
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 6,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}