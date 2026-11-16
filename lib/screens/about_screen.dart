import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // CHANGE these to your real details
  static const appVersion = '1.0.0';
  static const supportEmail = 'ebrgyconnect.support@gmail.com';
  static const teamFacebook = 'https://www.facebook.com/your.team.page';
  static const hallName = 'Barangay Hall';
  static const hallAddress = 'Brgy. Del Remedio, San Pablo City, Laguna, Philippines';
  static const hallHours = 'Mon-Fri, 8:00 AM - 5:00 PM';
  static const course = 'Platform Technologies';
  static const school = 'Laguna State Polytechnic University - San Pablo City Campus';

  // (name, role, Facebook link or '' for none)
  static const developers = [
    ('John Carlos Ambrocio', 'Mobile App Developer', 'https://www.facebook.com/profile.php?id=61582755621276'),
    ('Stephen Rockwel Banagale', 'Mobile App Developer', 'https://www.facebook.com/profile.php?id=61578231022201'),
    ('John Rhenz Rota', 'Web Developer', 'https://www.facebook.com/JohnRhenz.Rota'),
    ('Gian Marco Valenzuela', 'Mobile App Developer', 'https://www.facebook.com/marukoyuiii'),
  ];

  // Opens a link. If nothing can open it, copies it instead.
  Future<void> _open(BuildContext context, Uri uri, String copyText) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (!opened) {
      await Clipboard.setData(ClipboardData(text: copyText));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied.')),
      );
    }
  }

  Future<void> _email(BuildContext context) => _open(
        context,
        Uri.parse('mailto:$supportEmail?subject=E-BrgyConnect%20Support'),
        supportEmail,
      );

  Future<void> _facebook(BuildContext context, String url) =>
      _open(context, Uri.parse(url), url);

  // Underlined, tappable text
  Widget _link(String text, VoidCallback onTap, {double size = 13}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: size,
            color: AppColors.primary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );

  Widget _text(String text, {bool muted = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: muted ? 12 : 13,
            color: muted ? Colors.black54 : Colors.black87,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About & Support'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 110),
                  const SizedBox(height: 6),
                  const Text(
                    'Version $appVersion',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Request barangay documents online and track them without extra trips to the hall.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),

                  _card('Questions about your documents', [
                    _text(
                      'Fees, requirements, and pickup are handled by the barangay hall.',
                      muted: true,
                    ),
                    const SizedBox(height: 6),
                    _text(hallName),
                    _text(hallAddress),
                    _text(hallHours),
                  ]),

                  _card('App problems', [
                    _text(
                      "Can't log in, something not working, or found a bug? Contact the developers.",
                      muted: true,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Email: ', style: TextStyle(fontSize: 13)),
                        Flexible(
                          child: _link(supportEmail, () => _email(context)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Facebook: ',
                            style: TextStyle(fontSize: 13)),
                        _link('E-BrgyConnect Team',
                            () => _facebook(context, teamFacebook)),
                      ],
                    ),
                  ]),

                  _card('Developers', [
                    for (final d in developers)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            d.$3.isEmpty
                                ? Text(d.$1,
                                    style: const TextStyle(fontSize: 13))
                                : _link(d.$1, () => _facebook(context, d.$3)),
                            Text(
                              '  -  ${d.$2}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    const Text(
                      '$course project, $school',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ]),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Your information is used only to process your barangay document requests.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}