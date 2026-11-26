import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/runtime_config.dart';
import '../../shared/services/firebase_service.dart';
import '../../core/security/order_policy.dart';
import '../../shared/widgets/widgets.dart';

class _GCtx {
  final String title, icon, origin, dest;
  final List<String> steps;
  final Color color;
  const _GCtx(
      {required this.title,
      required this.icon,
      required this.origin,
      required this.dest,
      required this.steps,
      required this.color});
}

const _ctxMap = {
  'servico': _GCtx(
      title: 'Profissional a caminho',
      icon: '🔧',
      origin: 'Profissional',
      dest: 'Sua localização',
      steps: ['Confirmado', 'A caminho', 'Chegando', 'Concluído'],
      color: AppColors.primary),
  'saude': _GCtx(
      title: 'Profissional de Saúde',
      icon: '🩺',
      origin: 'Profissional de saúde',
      dest: 'Sua casa',
      steps: ['Agendado', 'A caminho', 'Chegando', 'Atendendo'],
      color: AppColors.health),
  'mercado': _GCtx(
      title: 'Entrega a caminho',
      icon: '🛵',
      origin: 'Loja',
      dest: 'Seu endereço',
      steps: ['Preparando', 'Coletado', 'A caminho', 'Entregue'],
      color: AppColors.secondary),
  'aluguel': _GCtx(
      title: 'Rastreamento ativo',
      icon: '📍',
      origin: 'Item retirado',
      dest: 'Sua localização',
      steps: ['Reservado', 'Retirado', 'Em uso', 'Devolvido'],
      color: AppColors.navy),
};

class GpsScreen extends StatefulWidget {
  final String ctxKey;
  final String? deliveryId;
  final String? orderId;
  const GpsScreen(
      {super.key, this.ctxKey = 'servico', this.deliveryId, this.orderId});
  @override
  State<GpsScreen> createState() => _GpsState();
}

class _GpsState extends State<GpsScreen> with TickerProviderStateMixin {
  GoogleMapController? _map;
  StreamSubscription? _gpsSub;
  late AnimationController _pulse;
  Timer? _sim;

  static const _fallbackOrigin = LatLng(-23.5505, -46.6333);
  LatLng _origin = _fallbackOrigin;
  LatLng _dest = const LatLng(-23.5450, -46.6250);

  double _prog = 0;
  int _eta = 18, _step = 1, _etaOriginal = 18;
  bool _arrived = false, _locating = true;
  LatLng _pos = _fallbackOrigin;
  List<LatLng> _routePoints = [];
  double _routeKm = 2.4;

  _GCtx get _ctx => _ctxMap[widget.ctxKey] ?? _ctxMap['servico']!;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _resolveUserLocation();

    if (widget.deliveryId != null) {
      _gpsSub = FS.gpsStream(widget.deliveryId!).listen((data) {
        if (data != null && mounted) {
          setState(() => _pos = LatLng((data['lat'] as num).toDouble(),
              (data['lng'] as num).toDouble()));
          _map?.animateCamera(CameraUpdate.newLatLng(_pos));
        }
      });
    } else {
      _sim = Timer.periodic(const Duration(milliseconds: 280), (_) {
        if (!mounted) return;
        setState(() {
          _prog = min(1.0, _prog + 0.014);
          _eta = max(1, (_etaOriginal * (1 - _prog)).round());
          _step = _prog < 0.33
              ? 1
              : _prog < 0.66
                  ? 2
                  : 3;
          _pos = LatLng(
              _origin.latitude + (_dest.latitude - _origin.latitude) * _prog,
              _origin.longitude +
                  (_dest.longitude - _origin.longitude) * _prog);
          if (_prog >= 1.0) {
            _arrived = true;
            _sim?.cancel();
          }
          _map?.animateCamera(CameraUpdate.newLatLng(_pos));
        });
      });
    }
  }

  // Usa a localização real do usuário (destino do serviço/entrega) quando
  // disponível; caso a permissão seja negada, mantém as coordenadas de
  // demonstração para não travar o fluxo.
  Future<void> _resolveUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _dest = LatLng(pos.latitude, pos.longitude);
        // Origem simulada a ~2km de distância do usuário, para a rota ter sentido visual
        _origin = LatLng(pos.latitude + 0.015, pos.longitude - 0.012);
        _pos = _origin;
        _locating = false;
      });
      _map?.animateCamera(CameraUpdate.newLatLngZoom(_dest, 14.5));
      await _fetchRoute();
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  // Rota real via Google Directions API (Vol.7: GPS — rota, tempo
  // estimado). Usa a mesma API key pública já configurada para o
  // Google Maps no app (AndroidManifest.xml/AppDelegate.swift) — não
  // precisa de Cloud Function porque essa key já fica exposta no
  // client, como é o padrão do próprio SDK do Google Maps.
  // Se a chamada falhar por qualquer motivo (sem internet, key não
  // configurada ainda, cota excedida), mantém a linha reta como
  // fallback — a tela nunca quebra por causa disso.
  Future<void> _fetchRoute() async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_origin.latitude},${_origin.longitude}'
        '&destination=${_dest.latitude},${_dest.longitude}'
        '&key=${RuntimeConfig.googleMapsApiKey}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return;
      final route = (data['routes'] as List).first;
      final leg = (route['legs'] as List).first;
      final points =
          _decodePolyline(route['overview_polyline']['points'] as String);
      final durationMin = ((leg['duration']['value'] as num) / 60).round();
      final distanceKm = (leg['distance']['value'] as num) / 1000;
      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _eta = durationMin > 0 ? durationMin : _eta;
        _etaOriginal = _eta;
        _routeKm = distanceKm > 0 ? distanceKm : _routeKm;
      });
    } catch (e) {
      debugPrint('Directions API indisponível, usando rota em linha reta: $e');
    }
  }

  // Decodifica o polyline codificado que a Directions API retorna
  // (algoritmo padrão do Google, formato "encoded polyline algorithm").
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  @override
  void dispose() {
    _pulse.dispose();
    _sim?.cancel();
    _gpsSub?.cancel();
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _fallbackOrigin, zoom: 14.5),
            onMapCreated: (c) => _map = c,
            markers: {
              Marker(
                  markerId: const MarkerId('origin'),
                  position: _origin,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure)),
              Marker(
                  markerId: const MarkerId('dest'),
                  position: _dest,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed)),
              Marker(
                  markerId: const MarkerId('mover'),
                  position: _pos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange)),
            },
            polylines: {
              Polyline(
                  polylineId: const PolylineId('route'),
                  points:
                      _routePoints.isNotEmpty ? _routePoints : [_origin, _dest],
                  color: _ctx.color,
                  width: 4)
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          if (_locating)
            const Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(child: _LocatingBadge())),
          SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4))
                            ]),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: AppColors.textDark)),
                  ))),
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 32,
                          offset: Offset(0, -8))
                    ]),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
                child: _arrived ? _done() : _tracking(),
              )),
        ]),
      );

  Widget _tracking() => Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetHandle(),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tempo estimado',
                style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            Text('$_eta',
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
            const Text('minutos',
                style: TextStyle(fontSize: 14, color: AppColors.textLight)),
          ]),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: _ctx.color, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Text(_ctx.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('A caminho',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('${(_prog * _routeKm).toStringAsFixed(1)} km',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13))
                ]),
              ])),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
                value: _prog,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(_ctx.color),
                minHeight: 8)),
        const SizedBox(height: 16),
        Row(
            children: List.generate(_ctx.steps.length, (i) {
          final done = i < _step, active = i == _step;
          return Expanded(
              child: Column(children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                    color: done || active ? _ctx.color : AppColors.border,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: _ctx.color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2)
                          ]
                        : []),
                alignment: Alignment.center,
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                active ? Colors.white : AppColors.textLight))),
            const SizedBox(height: 4),
            Text(_ctx.steps[i],
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: done || active ? _ctx.color : AppColors.textLight),
                textAlign: TextAlign.center),
          ]));
        })),
        const SizedBox(height: 14),
        Container(
            decoration: AppDecorations.card(r: 16, elevated: false),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: _ctx.color,
                      borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(_ctx.icon, style: const TextStyle(fontSize: 22))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_ctx.origin,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textDark)),
                    Text('→ ${_ctx.dest}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textLight))
                  ])),
              Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8)
                      ]),
                  child: IconButton(
                      icon: const Icon(Icons.phone_rounded,
                          color: AppColors.primary),
                      onPressed: () => showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                                title: const Text('Ligar'),
                                content:
                                    Text('Deseja ligar para ${_ctx.origin}?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar')),
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Ligar')),
                                ],
                              )))),
            ])),
      ]);

  Widget _done() => Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetHandle(),
        const SizedBox(height: 20),
        const Text('🎉', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        const Text('Chegou!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary)),
        const SizedBox(height: 8),
        const Text('O profissional chegou ao seu endereço.',
            style: TextStyle(color: AppColors.textLight, fontSize: 14)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: () async {
                    try {
                      if (widget.orderId != null) {
                        await FS.completeOrder(widget.orderId!);
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        snack(context, '✅ Serviço concluído!',
                            bg: AppColors.secondary);
                      }
                    } on CloudCallException catch (e) {
                      if (mounted) snack(context, e.message, bg: AppColors.error);
                    } catch (e) {
                      if (mounted) {
                        snack(context, 'Não foi possível concluir o pedido.',
                            bg: AppColors.error);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('✓ Confirmar chegada',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white)))),
          const SizedBox(width: 12),
          Expanded(
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Routes.reviews,
                        arguments: {'orderId': widget.orderId ?? 'demo'});
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Avaliar ⭐',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textDark)))),
        ]),
      ]);
}

class _LocatingBadge extends StatelessWidget {
  const _LocatingBadge();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary)),
          const SizedBox(width: 8),
          const Text('Obtendo sua localização...',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ]),
      );
}
