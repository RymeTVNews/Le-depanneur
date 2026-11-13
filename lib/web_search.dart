import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Étiquettes OpenStreetMap correspondant à chaque métier.
const Map<String, List<String>> _osmTags = {
  'Plombier': ['craft=plumber'],
  'Électricien': ['craft=electrician'],
  'Mécanicien': ['shop=car_repair', 'craft=car_repair'],
  'Serrurier': ['craft=locksmith', 'shop=locksmith'],
  'Déménageur': ['office=moving_company'],
  'Peintre': ['craft=painter'],
  'Menuisier': ['craft=carpenter'],
  'Jardinier': ['craft=gardener'],
  'Nettoyage': ['craft=cleaning', 'office=cleaning'],
  'Coiffeur': ['shop=hairdresser'],
  'Informatique': ['craft=electronics_repair', 'shop=computer', 'shop=mobile_phone'],
};

const _endpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
];

/// Cherche sur Internet (OpenStreetMap) les entreprises proches.
/// [category] = null : tous les métiers connus.
Future<List<Pro>> searchWeb(double lat, double lng,
    {String? category, int radius = 10000}) async {
  final cats = category == null
      ? _osmTags.keys.toList()
      : (_osmTags.containsKey(category) ? [category] : <String>[]);
  if (cats.isEmpty) return [];

  final b = StringBuffer('[out:json][timeout:25];(');
  for (final c in cats) {
    for (final t in _osmTags[c]!) {
      b.write('nwr(around:$radius,$lat,$lng)[$t][name];');
    }
  }
  b.write(');out center tags 80;');

  http.Response? res;
  Object? lastError;
  for (final url in _endpoints) {
    try {
      res = await http
          .post(Uri.parse(url),
              headers: {'User-Agent': 'LeDepanneur/0.1 (app de test)'},
              body: {'data': b.toString()})
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) break;
      lastError = 'Erreur ${res.statusCode}';
      res = null;
    } catch (e) {
      lastError = e;
      res = null;
    }
  }
  if (res == null) {
    throw Exception('Recherche Internet indisponible ($lastError).');
  }

  final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  final out = <Pro>[];
  for (final e in (data['elements'] as List)) {
    final el = e as Map<String, dynamic>;
    final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? {};
    final center = el['center'] as Map?;
    final plat = (el['lat'] ?? center?['lat']) as num?;
    final plng = (el['lon'] ?? center?['lon']) as num?;
    final name = tags['name'] as String?;
    if (plat == null || plng == null || name == null) continue;

    String trade = category ?? 'Autre';
    if (category == null) {
      for (final c in cats) {
        if (_osmTags[c]!.any((t) {
          final kv = t.split('=');
          return tags[kv[0]] == kv[1];
        })) {
          trade = c;
          break;
        }
      }
    }

    final street = [tags['addr:housenumber'], tags['addr:street']]
        .where((x) => x != null && '$x'.isNotEmpty)
        .join(' ');
    final address = [street, tags['addr:city']]
        .where((x) => x != null && '$x'.isNotEmpty)
        .join(', ');
    final hours = tags['opening_hours'];

    out.add(Pro(
      id: 'web-${el['type']}-${el['id']}',
      type: 'company',
      name: name,
      trade: trade,
      phone: (tags['phone'] ?? tags['contact:phone'] ?? '') as String,
      address: address,
      description: hours == null ? '' : 'Heures : $hours',
      photoPath: '',
      idDocPath: '',
      lat: plat.toDouble(),
      lng: plng.toDouble(),
      web: true,
      website: (tags['website'] ?? tags['contact:website'] ?? '') as String,
    ));
  }
  return out;
}
