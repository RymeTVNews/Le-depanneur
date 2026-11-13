import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class LocError implements Exception {
  final String message;
  LocError(this.message);
  @override
  String toString() => message;
}

Future<Position> getPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw LocError('Activez la localisation de votre téléphone.');
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    throw LocError('Autorisation de localisation refusée.');
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ),
  );
}

/// Version de test : toutes les données restent sur ce téléphone.
class AppStore extends ChangeNotifier {
  static const trialDays = 7;
  static const priceLabel = '5 \$ par an';

  late SharedPreferences _p;
  String? email;
  DateTime? trialStart;
  DateTime? paidUntil;
  List<Pro> pros = [];

  bool get configured => true;
  bool get signedIn => email != null;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    email = _p.getString('email');
    trialStart = DateTime.tryParse(_p.getString('trialStart') ?? '');
    paidUntil = DateTime.tryParse(_p.getString('paidUntil') ?? '');
    final raw = _p.getString('pros');
    if (raw != null) {
      pros = (jsonDecode(raw) as List)
          .map((e) => Pro.fromRow({...(e as Map<String, dynamic>)}))
          .toList();
    }
  }

  DateTime? get trialEnd => trialStart?.add(const Duration(days: trialDays));
  bool get isPaid => paidUntil != null && paidUntil!.isAfter(DateTime.now());
  bool get inTrial =>
      !isPaid && trialEnd != null && trialEnd!.isAfter(DateTime.now());

  int get trialDaysLeft {
    if (trialEnd == null) return 0;
    final h = trialEnd!.difference(DateTime.now()).inHours;
    return h <= 0 ? 0 : (h / 24).ceil();
  }

  bool get hasAccess => signedIn && (isPaid || inTrial);
  List<Pro> get mine => pros;

  /// Version locale : aucun code n'est envoyé, la connexion est immédiate.
  Future<void> sendCode(String e) async {
    email = e.trim().toLowerCase();
    // L'essai ne redémarre pas si on se reconnecte.
    trialStart ??= DateTime.now();
    await _p.setString('email', email!);
    await _p.setString('trialStart', trialStart!.toIso8601String());
    notifyListeners();
  }

  Future<void> verifyCode(String code) async {}

  Future<void> signOut() async {
    email = null;
    await _p.remove('email');
    notifyListeners();
  }

  Future<void> simulatePayment() async {
    paidUntil = DateTime.now().add(const Duration(days: 365));
    await _p.setString('paidUntil', paidUntil!.toIso8601String());
    notifyListeners();
  }

  Future<void> loadPros() async {}

  Future<String> _persist(String src, String id, String tag) async {
    if (src.isEmpty) return '';
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/${id}_$tag.jpg';
    await File(src).copy(dest);
    return dest;
  }

  Future<void> addPro(Pro draft,
      {required String photoFile, String idFile = ''}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    pros.add(Pro(
      id: id,
      type: draft.type,
      name: draft.name,
      trade: draft.trade,
      phone: draft.phone,
      address: draft.address,
      description: draft.description,
      photoPath: await _persist(photoFile, id, 'photo'),
      idDocPath: await _persist(idFile, id, 'id'),
      lat: draft.lat,
      lng: draft.lng,
    ));
    await _p.setString('pros', jsonEncode(pros.map((e) => e.toRow()..['id'] = e.id).toList()));
    notifyListeners();
  }

  Future<void> removePro(String id) async {
    pros.removeWhere((e) => e.id == id);
    await _p.setString('pros', jsonEncode(pros.map((e) => e.toRow()..['id'] = e.id).toList()));
    notifyListeners();
  }
}
