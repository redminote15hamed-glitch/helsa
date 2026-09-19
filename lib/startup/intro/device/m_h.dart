import 'package:flutter/material.dart';

class IntroMobileHorizontal extends StatelessWidget {
  final VoidCallback onContinue;

  const IntroMobileHorizontal({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome To Helsa',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your smart health assistant',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 220,
                height: 58,
                child: FilledButton(
                  onPressed: onContinue,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
