import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'models.dart';
import 'store.dart';

// Position de repli (Montréal) si la localisation est refusée.
const double _fallbackLat = 45.5017;
const double _fallbackLng = -73.5673;

class SearchPage extends StatefulWidget {
  final AppStore store;
  const SearchPage({super.key, required this.store});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  String? _category;
  double? _lat;
  double? _lng;
  bool _loading = false;
  String? _locMessage;

  @override
  void initState() {
    super.initState();
    _locate();
    _refresh();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _loading = true;
      _locMessage = null;
    });
    try {
      final p = await getPosition();
      _lat = p.latitude;
      _lng = p.longitude;
    } catch (e) {
      _locMessage = '$e Résultats affichés autour de Montréal.';
      _lat = _fallbackLat;
      _lng = _fallbackLng;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    try {
      await widget.store.loadPros();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  List<_Result> _results() {
    if (_lat == null || _lng == null) return [];
    final all = <Pro>[
      ...widget.store.pros,
      if (kShowDemo) ...demoPros(_lat!, _lng!),
    ];
    final q = _query.text.trim().toLowerCase();
    final out = <_Result>[];
    for (final p in all) {
      if (_category != null && p.trade != _category) continue;
      if (q.isNotEmpty &&
          !('${p.name} ${p.trade} ${p.description}'.toLowerCase().contains(q))) {
        continue;
      }
      out.add(_Result(p, distanceKm(_lat!, _lng!, p.lat, p.lng)));
    }
    out.sort((a, b) => a.km.compareTo(b.km));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Plombier, électricien, déménageur…',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Actualiser ma position',
                  icon: const Icon(Icons.my_location),
                  onPressed: () {
                    _locate();
                    _refresh();
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final c in kCategories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (s) => setState(() => _category = s ? c : null),
                    ),
                  ),
              ],
            ),
          ),
          if (_locMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_locMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: results.isEmpty && !_loading
                ? const Center(child: Text('Aucun professionnel trouvé.'))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final r = results[i];
                      return _ProTile(result: r);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Result {
  final Pro pro;
  final double km;
  _Result(this.pro, this.km);
}

class _Avatar extends StatelessWidget {
  final Pro pro;
  final double radius;
  const _Avatar({required this.pro, required this.radius});

  @override
  Widget build(BuildContext context) {
    final img = imageOf(pro.photoPath);
    return CircleAvatar(
      radius: radius,
      backgroundImage: img,
      child: img == null
          ? Icon(pro.isCompany ? Icons.business : Icons.person, size: radius)
          : null,
    );
  }
}

class _ProTile extends StatelessWidget {
  final _Result result;
  const _ProTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final p = result.pro;
    return ListTile(
      leading: _Avatar(pro: p, radius: 26),
      title: Text(p.name),
      subtitle: Text(
          '${p.trade} • ${p.isCompany ? 'Entreprise' : 'Particulier'}'
          '${p.demo ? ' • démo' : ''}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(formatKm(result.km),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const Icon(Icons.verified, size: 18, color: Colors.green),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProDetailPage(pro: p, km: result.km)),
      ),
    );
  }
}

class ProDetailPage extends StatelessWidget {
  final Pro pro;
  final double km;
  const ProDetailPage({super.key, required this.pro, required this.km});

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir cette action.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = imageOf(pro.photoPath);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(pro.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: img != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image(
                        image: img, width: 180, height: 180, fit: BoxFit.cover),
                  )
                : _Avatar(pro: pro, radius: 70),
          ),
          const SizedBox(height: 16),
          Text(pro.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          Text('${pro.trade} • ${pro.isCompany ? 'Entreprise' : 'Particulier'}',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: Chip(
              avatar: const Icon(Icons.verified, color: Colors.green),
              label: Text(pro.isCompany
                  ? 'Entreprise vérifiée (nom, photo, numéro, adresse)'
                  : 'Identité vérifiée (pièce d’identité, photo, numéro)'),
            ),
          ),
          if (pro.demo)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Profil de démonstration (version de test).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.outline)),
            ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.near_me),
            title: Text('À ${formatKm(km)} de vous'),
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: Text(pro.phone),
            trailing: FilledButton(
              onPressed: () => _open(
                  context, Uri(scheme: 'tel', path: pro.phone)),
              child: const Text('Appeler'),
            ),
          ),
          if (pro.address.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(pro.address),
              trailing: OutlinedButton(
                onPressed: () => _open(
                    context,
                    Uri.parse(
                        'geo:${pro.lat},${pro.lng}?q=${pro.lat},${pro.lng}(${Uri.encodeComponent(pro.name)})')),
                child: const Text('Carte'),
              ),
            ),
          if (pro.description.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(pro.description),
            ),
        ],
      ),
    );
  }
}
