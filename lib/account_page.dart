import 'package:flutter/material.dart';

import 'store.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class AccountPage extends StatelessWidget {
  final AppStore store;
  const AccountPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final String status;
        if (store.isPaid) {
          status = 'Abonné jusqu’au ${_fmtDate(store.paidUntil!)}';
        } else {
          status = 'Essai gratuit : ${store.trialDaysLeft} jour(s) restant(s)';
        }
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Mon compte',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(store.email ?? ''),
                    ),
                    ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: Text(status),
                      subtitle: const Text('Abonnement : 5 \$ par an'),
                    ),
                    if (!store.isPaid)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: FilledButton(
                          onPressed: store.simulatePayment,
                          child: const Text('S’abonner — 5 \$ / an (paiement simulé)'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Mes inscriptions',
                  style: Theme.of(context).textTheme.titleMedium),
              if (store.mine.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                      'Aucune. Allez dans « Je suis pro » pour offrir vos services.'),
                ),
              for (final p in store.mine)
                Card(
                  child: ListTile(
                    leading: Icon(p.isCompany ? Icons.business : Icons.person),
                    title: Text(p.name),
                    subtitle: Text(p.trade),
                    trailing: IconButton(
                      tooltip: 'Supprimer',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => store.removePro(p.id),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                onPressed: store.signOut,
              ),
              const SizedBox(height: 12),
              Text(
                'Version de test : les données restent sur ce téléphone et le paiement est simulé.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
