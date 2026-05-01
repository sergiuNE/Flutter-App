import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/device.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = 'Keuken';
  XFile? _pickedFile;
  Uint8List? _webImageBytes;
  bool _loading = false;
  bool _available = true;
  double? _lat, _lng;
  String? _successMessage;

  final _categories = ['Keuken', 'Tuin', 'Schoonmaak', 'Gereedschap', 'Overig'];

  List<AvailabilitySlot> _slots = [];

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _showAddSlotDialog() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (pickedDate == null) return;

    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (end == null) return;

    final startMin = _toMinutes(start);
    final endMin = _toMinutes(end);

    if (endMin <= startMin) {
      _showError('Eindtijd moet na starttijd liggen.');
      return;
    }

    final overlaps = _slots.any(
      (s) =>
          _sameDay(s.date, pickedDate) &&
          !(endMin <= s.startMinutes || startMin >= s.endMinutes),
    );

    if (overlaps) {
      _showError('Deze datum en tijd overlapt met een bestaande periode.');
      return;
    }

    setState(() {
      _slots.add(
        AvailabilitySlot(
          date: DateTime(pickedDate.year, pickedDate.month, pickedDate.day),
          startMinutes: startMin,
          endMinutes: endMin,
        ),
      );
      _slots.sort((a, b) {
        final dateCmp = a.date.compareTo(b.date);
        if (dateCmp != 0) return dateCmp;
        return a.startMinutes.compareTo(b.startMinutes);
      });
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Foto kiezen: galerij of camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _pickedFile = picked;
            _webImageBytes = bytes;
          });
        } else {
          setState(() {
            _pickedFile = picked;
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) _showError('Foto ophalen mislukt: $e');
    }
  }

  void _showFotoKeuze() {
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF4F46E5),
              ),
              title: const Text('Foto nemen'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF4F46E5),
              ),
              title: const Text('Kiezen uit galerij'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Locatieservices zijn uitgeschakeld.');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      _showError('Locatie ophalen mislukt: $e');
    }
  }

  Future<String> _uploadImage() async {
    if (_pickedFile == null) return '';

    const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
    const uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Missing Cloudinary config. '
        'Set --dart-define=CLOUDINARY_CLOUD_NAME and --dart-define=CLOUDINARY_UPLOAD_PRESET',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'devices';

    if (kIsWeb) {
      final bytes = _webImageBytes ?? await _pickedFile!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: _pickedFile!.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('file', _pickedFile!.path),
      );
    }

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return (data['secure_url'] as String?) ?? '';
    } else {
      throw Exception('Cloudinary upload failed: ${streamed.statusCode} $body');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFF3B30)),
    );
  }

  void _resetForm() {
    _nameCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    setState(() {
      _pickedFile = null;
      _webImageBytes = null;
      _lat = null;
      _lng = null;
      _available = true;
      _category = 'Keuken';
      _slots = [];
    });
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Vul een naam in.');
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      _showError('Vul een prijs in.');
      return;
    }
    if (_available && _slots.isEmpty) {
      _showError('Voeg minstens 1 beschikbare datum toe.');
      return;
    }

    setState(() {
      _loading = true;
      _successMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = userDoc.data() ?? {};
      final ownerName = data['name'] ?? 'Onbekend';
      final userLat = (data['locationLat'] as num?)?.toDouble();
      final userLng = (data['locationLng'] as num?)?.toDouble();

      String imageUrl = '';
      try {
        imageUrl = await _uploadImage();
      } catch (_) {
        imageUrl = '';
      }

      await FirebaseFirestore.instance.collection('devices').add({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'imageUrl': imageUrl,
        'pricePerDay': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'isAvailable': _available,
        'ownerId': uid,
        'ownerName': ownerName,
        'lat': _lat ?? userLat ?? 51.2194,
        'lng': _lng ?? userLng ?? 4.4025,
        'availabilitySlots': _slots.map((s) => s.toMap()).toList(),
        'rating': 0.0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _successMessage = '${_nameCtrl.text.trim()} is toegevoegd!';
        });
        _resetForm();
      }
    } catch (e) {
      if (mounted) _showError('Fout bij opslaan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_pickedFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: Color(0xFF4F46E5),
          ),
          SizedBox(height: 8),
          Text(
            'Foto toevoegen',
            style: TextStyle(
              color: Color(0xFF4F46E5),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Galerij of camera',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
          ),
        ],
      );
    }
    if (kIsWeb && _webImageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.memory(_webImageBytes!, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() {
                _pickedFile = null;
                _webImageBytes = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.file(File(_pickedFile!.path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() {
              _pickedFile = null;
            }),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Toestel aanbieden'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Succes banner
            if (_successMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF065F46),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Foto
            GestureDetector(
              onTap: _showFotoKeuze,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _pickedFile != null
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 20),

            _Section(
              title: 'Naam',
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'bv. Robotstofzuiger Roomba',
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Categorie',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Beschrijving',
              child: TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Omschrijf je toestel...',
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Prijs per dag (€)',
              child: TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(hintText: 'bv. 8'),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Locatie',
              child: GestureDetector(
                onTap: kIsWeb ? null : _getLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lat != null
                            ? Icons.check_circle_outline
                            : Icons.my_location,
                        color: _lat != null
                            ? const Color(0xFF34C759)
                            : const Color(0xFF4F46E5),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        kIsWeb
                            ? 'Locatie: standaard Antwerpen (web)'
                            : _lat != null
                            ? 'Locatie opgehaald ✓'
                            : 'Gebruik mijn locatie',
                        style: TextStyle(
                          color: kIsWeb
                              ? const Color(0xFF8E8E93)
                              : _lat != null
                              ? const Color(0xFF34C759)
                              : const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_available) ...[
              const SizedBox(height: 14),
              _Section(
                title: 'Beschikbare datums',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_slots.isEmpty)
                      const Text(
                        'Nog geen datums toegevoegd.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ..._slots.asMap().entries.map((entry) {
                      final i = entry.key;
                      final slot = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                slot.labelNl,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _slots.removeAt(i)),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Color(0xFFFF3B30),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      onPressed: _showAddSlotDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Datum toevoegen'),
                    ),
                  ],
                ),
              ),
            ],
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Toestel plaatsen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3C3C43),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
