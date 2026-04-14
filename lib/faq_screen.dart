import 'package:flutter/material.dart';
import 'app_localizations.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final faqs = loc.faqItems;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.faqs,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.faqsFullTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.tapQuestionToSee,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // FAQ Items
          ...List.generate(faqs.length, (index) {
            final faq = faqs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    faq['question']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  iconColor: const Color(0xFF4CAF50),
                  collapsedIconColor: Colors.grey,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      faq['answer']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 10),

          // Footer
          Center(
            child: Text(
              loc.stillHaveQuestions,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
