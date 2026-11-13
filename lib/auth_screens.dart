import 'package:flutter/material.dart';

import 'store.dart';

final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

class SignUpScreen extends StatefulWidget {
  final AppStore store;
  const SignUpScreen({super.key, required this.store});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendCode() async {
    if (!_form.currentState!.validate()) return;
    await _run(() async {
      await widget.store.sendCode(_email.text);
      if (mounted && !widget.store.signedIn) setState(() => _sent = true);
    });
  }

  Future<void> _verify() async {
    if (_code.text.trim().length < 6) {
      setState(() => _error = 'Entrez le code reçu par courriel.');
      return;
    }
    await _run(() => widget.store.verifyCode(_code.text));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.build_circle, size: 88, color: cs.primary),
                  const SizedBox(height: 12),
                  Text('Le Dépanneur',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Trouvez rapidement un professionnel qualifié près de chez vous.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    enabled: !_sent,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Votre courriel',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _emailRe.hasMatch((v ?? '').trim())
                        ? null
                        : 'Entrez un courriel valide',
                  ),
                  if (_sent) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Code reçu par courriel',
                        prefixIcon: Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: TextStyle(color: cs.error)),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: Icon(_sent
                        ? Icons.check_circle_outline
                        : Icons.rocket_launch_outlined),
                    label: Text(_sent
                        ? 'Valider le code'
                        : 'Commencer l’essai gratuit de 7 jours'),
                    onPressed: _busy ? null : (_sent ? _verify : _sendCode),
                  ),
                  if (_sent)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _sent = false;
                                _code.clear();
                                _error = null;
                              }),
                      child: const Text('Changer de courriel'),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Ensuite ${AppStore.priceLabel}. Aucun paiement pendant l’essai.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
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

class PaywallScreen extends StatelessWidget {
  final AppStore store;
  const PaywallScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_clock, size: 80, color: cs.primary),
                const SizedBox(height: 16),
                Text('Votre essai gratuit est terminé',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  'Abonnez-vous pour ${AppStore.priceLabel} et continuer à '
                  'trouver des professionnels ou à offrir vos services.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: store.simulatePayment,
                  child: const Text('S’abonner — 5 \$ / an (paiement simulé)'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: store.signOut,
                  child: const Text('Changer de courriel'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version de test : aucun vrai paiement n’est effectué.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
