import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models.dart';
import 'store.dart';

class RegisterPage extends StatefulWidget {
  final AppStore store;
  final VoidCallback onDone;
  const RegisterPage({super.key, required this.store, required this.onDone});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _desc = TextEditingController();
  final _picker = ImagePicker();

  String _type = 'person';
  String _trade = kCategories.first;
  String _photo = '';
  String _idDoc = '';
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _saving = false;
  String? _error;

  bool get _isCompany => _type == 'company';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<String> _pick(bool camera) async {
    final f = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 80,
    );
    return f?.path ?? '';
  }

  Future<void> _choose(void Function(String) assign) async {
    final camera = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      ),
    );
    if (camera == null) return;
    try {
      final path = await _pick(camera);
      if (path.isNotEmpty && mounted) setState(() => assign(path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impossible d’accéder à la caméra ou aux photos.')));
      }
    }
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final p = await getPosition();
      _lat = p.latitude;
      _lng = p.longitude;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (_photo.isEmpty) {
      setState(() => _error = _isCompany
          ? 'Ajoutez une photo de l’entreprise.'
          : 'Ajoutez votre photo d’identité.');
      return;
    }
    if (!_isCompany && _idDoc.isEmpty) {
      setState(() => _error = 'Ajoutez une photo de votre pièce d’identité.');
      return;
    }
    if (_lat == null || _lng == null) {
      setState(() => _error = 'Définissez votre position avec le bouton prévu.');
      return;
    }
    setState(() => _saving = true);
    try {
      final pro = Pro(
        id: '',
        type: _type,
        name: _name.text.trim(),
        trade: _trade,
        phone: _phone.text.trim(),
        address: _isCompany ? _address.text.trim() : '',
        description: _desc.text.trim(),
        photoPath: '',
        idDocPath: '',
        lat: _lat!,
        lng: _lng!,
      );
      await widget.store.addPro(pro, photoFile: _photo, idFile: _idDoc);
      _name.clear();
      _phone.clear();
      _address.clear();
      _desc.clear();
      setState(() {
        _photo = '';
        _idDoc = '';
        _lat = null;
        _lng = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Inscription enregistrée. Vous apparaissez dans les recherches.')));
        widget.onDone();
      }
    } catch (e) {
      setState(() => _error = 'Échec de l’enregistrement : $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _imageTile(String label, String path, void Function(String) assign,
      {String? hint}) {
    final img = imageOf(path);
    return Card(
      child: ListTile(
        leading: img != null
            ? CircleAvatar(backgroundImage: img)
            : const CircleAvatar(child: Icon(Icons.add_a_photo)),
        title: Text(label),
        subtitle: Text(path.isEmpty ? (hint ?? 'Obligatoire') : 'Ajoutée ✓'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _choose(assign),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Offrir mes services',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            const Text(
                'Pour la sécurité des clients, votre dossier est vérifié. '
                'Votre pièce d’identité n’est jamais affichée aux clients.'),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'person',
                    icon: Icon(Icons.person),
                    label: Text('Personne')),
                ButtonSegment(
                    value: 'company',
                    icon: Icon(Icons.business),
                    label: Text('Entreprise')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _isCompany ? 'Nom de l’entreprise' : 'Nom complet',
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().length < 2 ? 'Champ obligatoire' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _trade,
              decoration: const InputDecoration(
                  labelText: 'Métier ou service',
                  border: OutlineInputBorder()),
              items: [
                for (final c in kCategories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _trade = v ?? _trade),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder()),
              validator: (v) =>
                  (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10
                      ? 'Numéro invalide (10 chiffres minimum)'
                      : null,
            ),
            if (_isCompany) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Adresse géographique',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v ?? '').trim().length < 6 ? 'Adresse obligatoire' : null,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description des services (facultatif)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            _imageTile(
                _isCompany ? 'Photo de l’entreprise' : 'Photo d’identité',
                _photo,
                (p) => _photo = p),
            if (!_isCompany)
              _imageTile('Pièce d’identité (permis, passeport…)', _idDoc,
                  (p) => _idDoc = p),
            Card(
              child: ListTile(
                leading: const Icon(Icons.my_location),
                title: Text(_lat == null
                    ? 'Définir ma position'
                    : 'Position enregistrée ✓'),
                subtitle: const Text(
                    'Sert à vous proposer aux clients proches de vous'),
                trailing: _locating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chevron_right),
                onTap: _locating ? null : _locate,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Enregistrement…' : 'M’inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}
