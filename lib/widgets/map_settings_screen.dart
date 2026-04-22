import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSettingsScreen extends StatefulWidget {
  final String uid;
  final double? initialLat;
  final double? initialLng;
  final double initialRadiusKm;

  const MapSettingsScreen({
    super.key,
    required this.uid,
    this.initialLat,
    this.initialLng,
    this.initialRadiusKm = 15,
  });

  @override
  State<MapSettingsScreen> createState() => _MapSettingsScreenState();
}

class _MapSettingsScreenState extends State<MapSettingsScreen> {
  GoogleMapController? _mapController;
  LatLng? _center;
  LatLng? _cameraTarget;
  double _radiusKm = 15;
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _radiusKm = widget.initialRadiusKm <= 0 ? 15 : widget.initialRadiusKm;
    if (widget.initialLat != null && widget.initialLng != null) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      _useLiveLocation(silent: true);
    }
  }

  Future<void> _useLiveLocation({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!silent && mounted) _show('Locatieservices staan uit.');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!silent && mounted) _show('Locatietoegang werd geweigerd.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final next = LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() => _center = next);

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: next, zoom: 12)),
      );
    } catch (_) {
      if (!silent && mounted) _show('Live locatie ophalen mislukt.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_center == null) {
      _show('Kies eerst een locatie.');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'locationLat': _center!.latitude,
        'locationLng': _center!.longitude,
        'searchRadiusKm': _radiusKm,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) _show('Opslaan mislukt.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFF3B30)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _center ?? const LatLng(51.2194, 4.4025);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Kaartselectie werkt het best op Android/iOS. '
                'Je kan wel je bereik opslaan.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4F46E5)),
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: ClipOval(
              child: SizedBox(
                width: 320,
                height: 320,
                child: kIsWeb
                    ? Container(
                        color: const Color(0xFFEDEDED),
                        child: const Center(
                          child: Icon(
                            Icons.map_outlined,
                            size: 42,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      )
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: center,
                          zoom: 12,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        markers: {
                          Marker(
                            markerId: const MarkerId('center'),
                            position: center,
                          ),
                        },
                        circles: {
                          Circle(
                            circleId: const CircleId('range'),
                            center: center,
                            radius: _radiusKm * 1000,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF4F46E5),
                            fillColor: const Color(0x224F46E5),
                          ),
                        },
                        onMapCreated: (c) => _mapController = c,
                        onCameraMove: (pos) => _cameraTarget = pos.target,
                        onCameraIdle: () {
                          if (_cameraTarget == null || !mounted) return;
                          setState(() => _center = _cameraTarget);
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sleep de kaart om het middenpunt te kiezen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _locating ? null : () => _useLiveLocation(),
            icon: const Icon(Icons.my_location),
            label: Text(_locating ? 'Bezig...' : 'Gebruik live locatie'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bereik: ${_radiusKm.toStringAsFixed(0)} km',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _radiusKm,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: const Color(0xFF4F46E5),
            label: '${_radiusKm.toStringAsFixed(0)} km',
            onChanged: (v) => setState(() => _radiusKm = v),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Opslaan'),
          ),
        ],
      ),
    );
  }
}
