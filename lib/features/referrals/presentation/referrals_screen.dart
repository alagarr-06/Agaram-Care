import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_state.dart';

class ReferralsScreen extends ConsumerWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final locale = ref.watch(selectedLocaleProvider);
    final language = locale.languageCode;

    final isTamil = language == 'ta';
    final isHindi = language == 'hi';

    String text({
      required String english,
      required String tamil,
      required String hindi,
    }) {
      if (isTamil) return tamil;
      if (isHindi) return hindi;
      return english;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          text(
            english: 'My Referrals',
            tamil: 'எனது பரிந்துரைகள்',
            hindi: 'मेरे रेफरल',
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ============================================================
            // REFERRAL SUMMARY
            // ============================================================
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.assignment_outlined,
                            size: 34,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            text(
                              english: 'My Referrals',
                              tamil: 'எனது\nபரிந்துரைகள்',
                              hindi: 'मेरे\nरेफरल',
                            ),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Text(
                      text(
                        english: 'District Government Hospital',
                        tamil: 'மாவட்ட அரசு மருத்துவமனை',
                        hindi: 'जिला सरकारी अस्पताल',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      text(
                        english: 'General Medicine',
                        tamil: 'பொது மருத்துவம்',
                        hindi: 'सामान्य चिकित्सा',
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoChip(
                          icon: Icons.tag_outlined,
                          label: 'AC-2026-0017',
                        ),
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: text(
                            english: '13 September 2026',
                            tamil: '13 செப்டம்பர் 2026',
                            hindi: '13 सितंबर 2026',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ============================================================
            // CURRENT STATUS
            // ============================================================
            Text(
              text(
                english: 'Current status',
                tamil: 'தற்போதைய நிலை',
                hindi: 'वर्तमान स्थिति',
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 30,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text(
                              english: 'Referral accepted',
                              tamil: 'பரிந்துரை ஏற்கப்பட்டது',
                              hindi: 'रेफरल स्वीकार किया गया',
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            text(
                              english:
                                  'The facility has accepted your referral.',
                              tamil:
                                  'மருத்துவமனை உங்கள் பரிந்துரையை ஏற்றுக்கொண்டுள்ளது.',
                              hindi:
                                  'अस्पताल ने आपका रेफरल स्वीकार कर लिया है।',
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ============================================================
            // CARE JOURNEY
            // ============================================================
            Text(
              text(
                english: 'Care journey stages',
                tamil: 'சிகிச்சைப் பயணத்தின் நிலைகள்',
                hindi: 'देखभाल यात्रा के चरण',
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 20),

            _TimelineItem(
              completed: true,
              showLine: true,
              title: text(
                english: 'Referral created',
                tamil: 'பரிந்துரை உருவாக்கப்பட்டது',
                hindi: 'रेफरल बनाया गया',
              ),
              description: text(
                english:
                    'Referral was created based on the care need.',
                tamil:
                    'மருத்துவ தேவையின் அடிப்படையில் பரிந்துரை உருவாக்கப்பட்டது.',
                hindi:
                    'देखभाल की आवश्यकता के आधार पर रेफरल बनाया गया।',
              ),
              date: text(
                english: '13 September',
                tamil: '13 செப்டம்பர்',
                hindi: '13 सितंबर',
              ),
            ),

            _TimelineItem(
              completed: true,
              showLine: true,
              title: text(
                english: 'Referral accepted',
                tamil: 'பரிந்துரை ஏற்கப்பட்டது',
                hindi: 'रेफरल स्वीकार किया गया',
              ),
              description: text(
                english:
                    'The facility confirmed the referral.',
                tamil:
                    'மருத்துவ நிலையம் பரிந்துரையை உறுதிப்படுத்தியது.',
                hindi:
                    'अस्पताल ने रेफरल की पुष्टि की।',
              ),
              date: text(
                english: 'Today',
                tamil: 'இன்று',
                hindi: 'आज',
              ),
            ),

            _TimelineItem(
              completed: false,
              showLine: true,
              title: text(
                english: 'Reach the healthcare facility',
                tamil: 'மருத்துவ நிலையத்தை அடையவும்',
                hindi: 'स्वास्थ्य केंद्र तक पहुंचें',
              ),
              description: text(
                english:
                    'Visit the facility as the next step.',
                tamil:
                    'அடுத்த கட்டமாக மருத்துவமனைக்குச் செல்லவும்.',
                hindi:
                    'अगले चरण के रूप में अस्पताल पहुंचें।',
              ),
            ),

            _TimelineItem(
              completed: false,
              showLine: true,
              title: text(
                english: 'Care initiated',
                tamil: 'சிகிச்சை தொடங்கப்பட்டது',
                hindi: 'देखभाल शुरू हुई',
              ),
              description: text(
                english:
                    'This stage will update when care begins.',
                tamil:
                    'சிகிச்சை தொடங்கியதும் இந்த நிலை புதுப்பிக்கப்படும்.',
                hindi:
                    'देखभाल शुरू होने पर यह स्थिति अपडेट होगी।',
              ),
            ),

            _TimelineItem(
              completed: false,
              showLine: false,
              title: text(
                english: 'Referral completed',
                tamil: 'பரிந்துரை முடிக்கப்பட்டது',
                hindi: 'रेफरल पूरा हुआ',
              ),
              description: text(
                english:
                    'The referral closes after care and follow-up are completed.',
                tamil:
                    'சிகிச்சை மற்றும் தொடர்ச்சியான பராமரிப்பு முடிந்ததும் பரிந்துரை நிறைவடையும்.',
                hindi:
                    'देखभाल और फॉलो-अप पूरा होने के बाद रेफरल बंद होगा।',
              ),
            ),

            const SizedBox(height: 18),

            // ============================================================
            // NEXT ACTION
            // ============================================================
            Card(
              elevation: 0,
              color: colorScheme.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: InkWell(
                onTap: () => context.push('/facilities'),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 36,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text(
                                english: 'Next step',
                                tamil: 'அடுத்த கட்டம்',
                                hindi: 'अगला कदम',
                              ),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              text(
                                english:
                                    'Visit the facility and begin your care.',
                                tamil:
                                    'மருத்துவமனைக்குச் சென்று சிகிச்சையைத் தொடங்கவும்.',
                                hindi:
                                    'अस्पताल पहुंचकर देखभाल शुरू करें।',
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              text(
                english: 'This is synthetic referral data for the demo.',
                tamil: 'இது டெமோவிற்கான மாதிரி பரிந்துரை தரவு.',
                hindi: 'यह डेमो के लिए नमूना रेफरल डेटा है।',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.completed,
    required this.showLine,
    required this.title,
    required this.description,
    this.date,
  });

  final bool completed;
  final bool showLine;
  final String title;
  final String description;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final indicatorColor = completed
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: completed
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerLow,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: indicatorColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    completed
                        ? Icons.check
                        : Icons.circle_outlined,
                    size: 24,
                    color: indicatorColor,
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: completed
                          ? colorScheme.primary.withValues(alpha: 0.55)
                          : colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 2,
                bottom: 26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      date!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}