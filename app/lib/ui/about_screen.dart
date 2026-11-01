import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _donationAddress = 'bc1q4jp3gvatpmmd8qh6neejay4z05qawuneqrr92t';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'icons/gl_tracker_logo_new.png',
                width: 160,
                height: 160,
              ),
              const SizedBox(height: 28),
              Text(
                'OpenGLTracker',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              // The GPL asks interactive programs to carry a warranty notice.
              Text(
                'Copyright © 2026 The OpenGLTracker contributors.\n'
                'This program comes with ABSOLUTELY NO WARRANTY. It is free '
                'software, and you are welcome to redistribute it under the '
                'terms of the GNU General Public License, version 3 or later.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
              const Divider(height: 48),
              Text(
                'Tired of being ripped off for basic software that should be '
                'free? Send donations to help fund ad-free/subs-free software '
                'for great justice.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('Send Bitcoin:', style: textTheme.bodyMedium),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SelectableText(
                      _donationAddress,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy address',
                    onPressed: () async {
                      await Clipboard.setData(
                          const ClipboardData(text: _donationAddress));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Address copied')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
