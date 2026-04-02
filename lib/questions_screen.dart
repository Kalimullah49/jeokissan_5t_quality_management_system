import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'app_localizations.dart';
import 'locale_provider.dart';

class QuestionsScreen extends StatefulWidget {
  final String commodity;
  final String preliminaryAssessment;
  final List<Map<String, dynamic>> questions;
  final List<XFile> imageFiles;
  final List<Uint8List> imageBytesList;
  final List<String> fileNames;
  final Future<void> Function(List<Map<String, String>> questionsAndAnswers) onSubmit;

  const QuestionsScreen({
    super.key,
    required this.commodity,
    required this.preliminaryAssessment,
    required this.questions,
    required this.imageFiles,
    required this.imageBytesList,
    required this.fileNames,
    required this.onSubmit,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  late List<String?> _selectedAnswers;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List.generate(
      widget.questions.length,
      (_) => null,
    );
  }

  Future<void> _handleSubmit() async {
    final loc = AppLocalizations.of(context);
    // Check if at least one answer is provided
    final hasAnswer = _selectedAnswers.any((a) => a != null);
    if (!hasAnswer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.answerAtLeastOne),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final questionsAndAnswers = <Map<String, String>>[];
    for (int i = 0; i < widget.questions.length; i++) {
      final answer = _selectedAnswers[i];
      if (answer != null) {
        questionsAndAnswers.add({
          'question': widget.questions[i]['question'] as String,
          'answer': answer,
        });
      }
    }

    await widget.onSubmit(questionsAndAnswers);

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildImageWidget() {
    if (widget.imageFiles.isEmpty) return _buildPlaceholder();
    
    if (widget.imageFiles.length == 1) {
      return _buildSingleImage(widget.imageFiles[0]);
    }
    
    // Multiple images: horizontal scroll
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: widget.imageFiles.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildSingleImage(widget.imageFiles[index]),
          ),
        );
      },
    );
  }

  Widget _buildSingleImage(XFile file) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
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
          loc.qualityAssessment,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Commodity Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Image preview - full size
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      width: double.infinity,
                      height: 350,
                      child: _buildImageWidget(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.preliminaryAssessment,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.6,
                  fontFamily: context.watch<LocaleProvider>().fontFamily,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Questions header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Color(0xFF4285F4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.followUpQuestions,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: context.watch<LocaleProvider>().fontFamily,
                        ),
                      ),
                      Text(
                        loc.helpAIClassify,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: context.watch<LocaleProvider>().fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Questions list
            ...widget.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final options = List<String>.from(question['options'] ?? []);
              return _buildQuestionCard(
                index: index,
                question: question['question'] as String,
                options: options,
              );
            }),

            const SizedBox(height: 8),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[400], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.answerInfoText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        height: 1.4,
                        fontFamily: context.watch<LocaleProvider>().fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search, color: Colors.white),
                label: Text(
                  _isSubmitting ? loc.classifying : loc.getFinalClassification,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  disabledBackgroundColor: const Color(0xFF4285F4).withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required int index,
    required String question,
    required List<String> options,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selectedAnswers[index] != null
              ? const Color(0xFF4285F4).withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _selectedAnswers[index] != null
                      ? const Color(0xFF34A853)
                      : const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _selectedAnswers[index] != null
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                    fontFamily: context.watch<LocaleProvider>().fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedAnswers[index] != null
                    ? const Color(0xFF4285F4).withOpacity(0.4)
                    : Colors.grey[300]!,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAnswers[index],
                hint: Text(
                  AppLocalizations.of(context).selectAnAnswer,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontFamily: context.watch<LocaleProvider>().fontFamily,
                  ),
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _selectedAnswers[index] != null
                      ? const Color(0xFF4285F4)
                      : Colors.grey[400],
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: context.watch<LocaleProvider>().fontFamily,
                ),
                borderRadius: BorderRadius.circular(12),
                items: options.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        fontFamily: context.watch<LocaleProvider>().fontFamily,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAnswers[index] = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
