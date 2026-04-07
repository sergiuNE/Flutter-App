import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPreview extends StatelessWidget {
  final double lat;
  final double lng;
  final String label;

  const MapPreview({
    super.key,
    required this.lat,
    required this.lng,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _MapPlaceholder(label: label);
    }

    final position = LatLng(lat, lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 14),
          markers: {
            Marker(
              markerId: const MarkerId('device'),
              position: position,
              infoWindow: InfoWindow(title: label),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          onMapCreated: (_) {},
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final String label;
  const _MapPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, color: Color(0xFF4F46E5), size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4F46E5),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kaart beschikbaar op Android',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
