import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:jeokissan_5t_quality_management_system/app_localizations.dart';

class ClassificationResultScreen extends StatelessWidget {
  final String qualityRating; // e.g., "Excellent", "Very Good", "Good", etc.
  final String commodityName;
  final List<String> reasons;
  final List<XFile> imageFiles;
  final VoidCallback onDone;
  final VoidCallback onClassifyAnother;

  const ClassificationResultScreen({
    super.key,
    required this.qualityRating,
    required this.commodityName,
    required this.reasons,
    required this.imageFiles,
    required this.onDone,
    required this.onClassifyAnother,
  });

  // Get color based on quality rating
  Color _getRatingColor() {
    switch (qualityRating.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF2E7D32); // Dark Green
      case 'very good':
        return const Color(0xFF66BB6A); // Light Green
      case 'good':
        return const Color(0xFFFDD835); // Yellow
      case 'satisfactory':
        return const Color(0xFFFFB74D); // Orange
      case 'unsatisfactory':
      case 'rotten':
        return const Color(0xFFEF5350); // Red
      default:
        return const Color(0xFF2E7D32);
    }
  }

  // Get icon color for each reason (alternating greens)
  Color _getReasonIconColor(int index) {
    final colors = [
      const Color(0xFF2E7D32), // Dark Green
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFF66BB6A), // Medium Green
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.classificationResult,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              
              // Header Text
              Text(
                loc.classificationResult,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.psychology_alt, color: Color(0xFF2E7D32), size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'AI Detected: $commodityName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Image with Quality Badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Image Container
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 180,
                      maxHeight: 400,
                    ),
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: _buildImageWidget(),
                      ),
                    ),
                  ),
                  
                  // Quality Rating Badge
                  Positioned(
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _getRatingColor(),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: _getRatingColor().withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            qualityRating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Reasons Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.reasonsForRating(qualityRating),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Reasons List
              ...reasons.asMap().entries.map((entry) {
                int index = entry.key;
                String reason = entry.value;
                return _buildReasonItem(reason, index);
              }),
              
              const SizedBox(height: 30),
              
              // Done Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4), // Google Blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    loc.done,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Classify Another Image Button
              TextButton(
                onPressed: onClassifyAnother,
                child: Text(
                  loc.classifyAnotherImage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonItem(String reason, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getReasonIconColor(index),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (imageFiles.isEmpty) return _buildPlaceholder();
    
    if (imageFiles.length == 1) {
      return _buildSingleImage(imageFiles[0]);
    }

    // Multiple images: horizontal scroll
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: imageFiles.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildSingleImage(imageFiles[index]),
          ),
        );
      },
    );
  }

  Widget _buildSingleImage(XFile file) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else {
      return Image.file(
        File(file.path),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 10),
          Text(
            'No image available',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'کوئی تصویر دستیاب نہیں',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
