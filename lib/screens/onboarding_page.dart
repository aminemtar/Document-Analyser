import 'package:flutter/material.dart' hide Text;
import '../l10n/tr_text.dart';
import '../theme/app_theme.dart';

class _Slide {
  final IconData icon;
  final String title, body;
  const _Slide(this.icon, this.title, this.body);
}

/// Three-step welcome shown once, the first time the app opens.
class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _slides = [
    _Slide(
        Icons.document_scanner_rounded,
        'Understand any document',
        'Import a PDF, Word, text or RTF file and get a clear summary, key details and risks in seconds.'),
    _Slide(
        Icons.event_available_rounded,
        'Never miss a date',
        'DocuMind finds deadlines and amounts, and shows what needs your attention right on the home screen.'),
    _Slide(
        Icons.lock_outline_rounded,
        'You stay in control',
        'Your files are stored only on this device. Text is sent to the AI model just when you analyze a document or ask a question.'),
  ];

  final controller = PageController();
  int index = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(children: [
            Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                    onPressed: last ? null : widget.onDone,
                    child: Text(last ? '' : 'Skip',
                        style: TextStyle(
                            color: muted, fontWeight: FontWeight.w700)))),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: AppColors.heroGradient),
                                borderRadius: BorderRadius.circular(38),
                                boxShadow: [
                                  BoxShadow(
                                      color: blue.withValues(alpha: .25),
                                      blurRadius: 30,
                                      offset: const Offset(0, 14))
                                ]),
                            child: Icon(slide.icon,
                                color: Colors.white, size: 60)),
                        const SizedBox(height: 40),
                        Text(slide.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: navy,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.6)),
                        const SizedBox(height: 14),
                        Text(slide.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.bodyText,
                                fontSize: 15,
                                height: 1.55)),
                      ]);
                },
              ),
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: i == index ? blue : AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(8))))),
            const SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: last
                        ? widget.onDone
                        : () => controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut),
                    style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(last ? 'Get started' : 'Next',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)))),
          ]),
        ),
      ),
    );
  }
}
