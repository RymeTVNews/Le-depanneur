import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

const List<String> kCategories = [
  'Plombier',
  'Électricien',
  'Mécanicien',
  'Serrurier',
  'Déménageur',
  'Peintre',
  'Menuisier',
  'Jardinier',
  'Nettoyage',
  'Coiffeur',
  'Informatique',
  'Autre',
];

/// Un professionnel (personne physique) ou une entreprise.
class Pro {
  final String id;
  final String ownerId;
  final String type; // 'person' ou 'company'
  final String name;
  final String trade;
  final String phone;
  final String address;
  final String description;
  final String photoPath;
  final String idDocPath; // pièce d'identité (jamais montrée aux clients)
  final double lat;
  final double lng;
  final bool demo;
  final bool web; // trouvé sur Internet, non inscrit dans l'app
  final String website;

  const Pro({
    required this.id,
    this.ownerId = '',
    required this.type,
    required this.name,
    required this.trade,
    required this.phone,
    required this.address,
    required this.description,
    required this.photoPath,
    required this.idDocPath,
    required this.lat,
    required this.lng,
    this.demo = false,
    this.web = false,
    this.website = '',
  });

  bool get isCompany => type == 'company';

  /// Ligne à envoyer à la table `pros` (owner_id et id sont remplis par le serveur).
  Map<String, dynamic> toRow() => {
        'type': type,
        'name': name,
        'trade': trade,
        'phone': phone,
        'address': address,
        'description': description,
        'photo_url': photoPath,
        'id_doc_path': idDocPath,
        'lat': lat,
        'lng': lng,
      };

  factory Pro.fromRow(Map<String, dynamic> j) => Pro(
        id: j['id'] as String,
        ownerId: (j['owner_id'] ?? '') as String,
        type: j['type'] as String,
        name: j['name'] as String,
        trade: j['trade'] as String,
        phone: j['phone'] as String,
        address: (j['address'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        photoPath: (j['photo_url'] ?? '') as String,
        idDocPath: (j['id_doc_path'] ?? '') as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}

ImageProvider? imageOf(String path) {
  if (path.isEmpty) return null;
  if (path.startsWith('http')) return NetworkImage(path);
  final f = File(path);
  return f.existsSync() ? FileImage(f) : null;
}

/// Distance en km (formule de haversine).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = pow(sin(dLat / 2), 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLng / 2), 2);
  return 2 * r * asin(sqrt(a));
}

String formatKm(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

/// Profils de démonstration générés autour de la position de l'utilisateur,
/// pour pouvoir tester la recherche sans autres inscrits.
List<Pro> demoPros(double lat, double lng) {
  const data = <List<dynamic>>[
    ['Marc Tremblay', 'person', 'Plombier', 'Fuites, chauffe-eau, débouchage. Urgences 24 h.', 0.012, 0.010],
    ['Plomberie Express inc.', 'company', 'Plombier', 'Équipe de 6 plombiers certifiés.', -0.020, 0.015],
    ['Sophie Gagnon', 'person', 'Électricien', 'Maître électricienne, panneaux et bornes de recharge.', 0.018, -0.012],
    ['Voltage Plus inc.', 'company', 'Électricien', 'Résidentiel et commercial, soumission gratuite.', -0.008, -0.025],
    ['Karim Benali', 'person', 'Mécanicien', 'Mécanique générale à domicile, diagnostic sur place.', 0.030, 0.020],
    ['Garage Du Coin', 'company', 'Mécanicien', 'Pneus, freins, vidange, inspection.', -0.035, 0.008],
    ['Luc Pelletier', 'person', 'Serrurier', 'Ouverture de portes, changement de serrures.', 0.006, 0.030],
    ['Déménagement Rapido', 'company', 'Déménageur', 'Camion + 3 déménageurs, tarif à l’heure.', -0.015, -0.010],
    ['Julie Roy', 'person', 'Peintre', 'Peinture intérieure et extérieure, finition soignée.', 0.022, 0.026],
    ['Jardins Verdure', 'company', 'Jardinier', 'Entretien de pelouse, taille, aménagement.', -0.028, -0.020],
    ['Nadia Lopez', 'person', 'Nettoyage', 'Ménage résidentiel, après rénovation.', 0.010, -0.018],
    ['Dépannage Info 24', 'company', 'Informatique', 'Réparation d’ordinateurs et réseaux, sur place.', 0.040, -0.005],
  ];
  final out = <Pro>[];
  for (var i = 0; i < data.length; i++) {
    final d = data[i];
    out.add(Pro(
      id: 'demo-$i',
      type: d[1] as String,
      name: d[0] as String,
      trade: d[2] as String,
      phone: '514-555-01${(10 + i).toString()}',
      address: d[1] == 'company' ? 'Adresse de démonstration ${i + 1}' : '',
      description: d[3] as String,
      photoPath: '',
      idDocPath: '',
      lat: lat + (d[4] as double),
      lng: lng + (d[5] as double),
      demo: true,
    ));
  }
  return out;
}
