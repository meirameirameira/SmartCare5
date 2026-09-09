import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/map_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapCtrl = MapController();

  static const _initialZoom = 14.5;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MapProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa SmartCare'),
        actions: [
          IconButton(
            tooltip: 'Buscar atendimento nesta área',
            icon: const Icon(Icons.refresh),
            onPressed: p.isLoading ? null : p.retrySearch,
          ),
          IconButton(
            tooltip: 'Centralizar na minha posição',
            icon: const Icon(Icons.my_location),
            onPressed: () => _mapCtrl.move(
              LatLng(p.centerLat, p.centerLng),
              _initialZoom,
            ),
          ),
        ],
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: LatLng(p.centerLat, p.centerLng),
                    initialZoom: _initialZoom,
                    onTap: (_, __) => p.selectDevice(null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      // Exigido pela politica de uso dos tiles do OpenStreetMap.
                      userAgentPackageName: 'com.smarthas.smartcare_flutter',
                    ),
                    MarkerLayer(markers: _buildMarkers(p)),
                    const _OsmAttribution(),
                  ],
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
                // A busca depende de rede: sem ela o mapa fica sem marcadores,
                // entao o motivo e a acao de repetir precisam ficar visiveis.
                if (p.searchFailure != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 96,
                    child: _SearchFailureBanner(
                      message: p.searchFailure!.message,
                      onRetry: p.retrySearch,
                    ),
                  ),
              ],
            ),
    );
  }

  List<Marker> _buildMarkers(MapProvider p) {
    return p.devices.map((device) {
      final color = switch (device.type) {
        DeviceType.pharmacy => Colors.orange,
        DeviceType.hospital => Colors.red,
        DeviceType.user     => Colors.cyan,
      };

      return Marker(
        key: ValueKey(device.id),
        point: LatLng(device.lat, device.lng),
        width: 36,
        height: 36,
        child: Tooltip(
          message: device.status == null
              ? device.name
              : '${device.name} - ${device.status}',
          child: GestureDetector(
            onTap: () => p.selectDevice(device),
            child: Icon(
              Icons.location_on,
              color: color,
              size: 36,
              shadows: const [
                Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Credito ao OpenStreetMap — obrigatorio pela licenca ODbL dos dados.
class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: ColoredBox(
          color: Color(0xCCFFFFFF),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  final SmartDevice device;
  final VoidCallback onClose;
  const _DeviceInfoCard({required this.device, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (device.type) {
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
            color: Colors.black.withValues(alpha: 0.15),
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
              color: color.withValues(alpha: 0.1),
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

class _SearchFailureBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _SearchFailureBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Não foi possível buscar atendimento por perto. $message',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
          ],
        ),
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
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
