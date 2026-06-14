import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/map_provider.dart';
import '../core/theme.dart';
import '../models/models.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapCtrl;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MapProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa SmartCare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapCtrl?.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(p.centerLat, p.centerLng),
                ),
              );
            },
          ),
        ],
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (ctrl) => _mapCtrl = ctrl,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(p.centerLat, p.centerLng),
                    zoom: 14.5,
                  ),
                  markers: _buildMarkers(p),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  onTap: (_) => p.selectDevice(null),
                ),
                // Device info card
                if (p.selectedDevice != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: _DeviceInfoCard(device: p.selectedDevice!,
                        onClose: () => p.selectDevice(null)),
                  ),
                // Legend
                Positioned(
                  top: 12,
                  right: 12,
                  child: _MapLegend(),
                ),
              ],
            ),
    );
  }

  Set<Marker> _buildMarkers(MapProvider p) {
    return p.devices.map((device) {
      final hue = switch (device.type) {
        DeviceType.sensor   => BitmapDescriptor.hueGreen,
        DeviceType.camera   => BitmapDescriptor.hueBlue,
        DeviceType.pharmacy => BitmapDescriptor.hueOrange,
        DeviceType.hospital => BitmapDescriptor.hueRed,
        DeviceType.user     => BitmapDescriptor.hueCyan,
      };

      return Marker(
        markerId: MarkerId(device.id),
        position: LatLng(device.lat, device.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: device.name,
          snippet: device.status,
        ),
        onTap: () => p.selectDevice(device),
      );
    }).toSet();
  }
}

class _DeviceInfoCard extends StatelessWidget {
  final SmartDevice device;
  final VoidCallback onClose;
  const _DeviceInfoCard({required this.device, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (device.type) {
      DeviceType.sensor   => ('🌡️', SmartCareTheme.primaryGreen),
      DeviceType.camera   => ('📷', SmartCareTheme.accentBlue),
      DeviceType.pharmacy => ('💊', SmartCareTheme.warnAmber),
      DeviceType.hospital => ('🏥', SmartCareTheme.dangerRed),
      DeviceType.user     => ('👤', Colors.purple),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                if (device.status != null)
                  Text(device.status!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: device.active ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(device.active ? 'Online' : 'Offline',
                        style: TextStyle(
                            fontSize: 11,
                            color: device.active ? Colors.green : Colors.red)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: Colors.green, label: 'Sensor'),
          _LegendItem(color: Colors.blue, label: 'Câmera'),
          _LegendItem(color: Colors.orange, label: 'Farmácia'),
          _LegendItem(color: Colors.red, label: 'Hospital'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
