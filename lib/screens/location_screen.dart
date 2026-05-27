import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../theme/dark_theme.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with TickerProviderStateMixin {
  Position? _position;
  String? _errorMessage;
  LocationErrorType? _errorType;
  bool _isLoading = false;
  bool _isStreaming = false;
  StreamSubscription<Position>? _positionSubscription;

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorType = null;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      setState(() {
        _position = position;
        _isLoading = false;
      });
    } on LocationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _errorType = e.type;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: ${e.toString()}';
        _errorType = LocationErrorType.unknown;
        _isLoading = false;
      });
    }
  }

  void _toggleStream() {
    if (_isStreaming) {
      _positionSubscription?.cancel();
      setState(() => _isStreaming = false);
    } else {
      setState(() => _isStreaming = true);
      _positionSubscription =
          LocationService.getPositionStream().listen((position) {
        setState(() => _position = position);
      }, onError: (e) {
        setState(() {
          _isStreaming = false;
          _errorMessage = 'Error en stream: ${e.toString()}';
        });
      });
    }
  }

  void _copyCoordinates() {
    if (_position == null) return;
    final text =
        '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Coordenadas copiadas al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(),
              const SizedBox(height: 24),
              if (_isLoading) _buildLoadingCard(),
              if (_errorMessage != null) _buildErrorCard(),
              if (_position != null && !_isLoading) ...[
                _buildCoordinatesCard(),
                const SizedBox(height: 16),
                _buildDetailsCard(),
                const SizedBox(height: 16),
                _buildAccuracyCard(),
              ],
              const SizedBox(height: 24),
              _buildActionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isStreaming ? AppTheme.success : AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isStreaming ? AppTheme.success : AppTheme.primary)
                      .withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Text('GEO TRACKER'),
        ],
      ),
      actions: [
        if (_position != null)
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: AppTheme.primary),
            tooltip: 'Copiar coordenadas',
            onPressed: _copyCoordinates,
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubicación\nen Tiempo Real',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _isStreaming
                    ? 'Transmisión activa • Actualizando cada 5m'
                    : 'Precisión GPS de alta resolución',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        _buildRadarWidget(),
      ],
    );
  }

  Widget _buildRadarWidget() {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _rotateController,
            builder: (_, __) => Transform.rotate(
              angle: _rotateController.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(80, 80),
                painter: _RadarPainter(),
              ),
            ),
          ),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _isStreaming ? AppTheme.success : AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isStreaming ? AppTheme.success : AppTheme.primary)
                        .withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return _GlowCard(
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Obteniendo ubicación...',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('Conectando con GPS',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return _GlowCard(
      glowColor: AppTheme.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gps_off_rounded, color: AppTheme.error, size: 22),
              const SizedBox(width: 10),
              Text('Error de Ubicación',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppTheme.error)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Error desconocido',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_errorType == LocationErrorType.permissionDeniedForever) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: LocationService.openSettings,
              icon: const Icon(Icons.settings_rounded, size: 16),
              label: const Text('Abrir Configuración'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    return _GlowCard(
      glowColor: AppTheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('COORDENADAS',
                  style: Theme.of(context).textTheme.labelLarge),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  _isStreaming ? '● EN VIVO' : '● FIJO',
                  style: TextStyle(
                    color:
                        _isStreaming ? AppTheme.success : AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _CoordRow(
            label: 'LAT',
            value: _position!.latitude.toStringAsFixed(6),
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          _CoordRow(
            label: 'LON',
            value: _position!.longitude.toStringAsFixed(6),
            color: AppTheme.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final speed = _position!.speed >= 0
        ? '${(_position!.speed * 3.6).toStringAsFixed(1)} km/h'
        : 'N/A';
    final altitude = '${_position!.altitude.toStringAsFixed(1)} m';
    final heading = _position!.heading >= 0
        ? '${_position!.heading.toStringAsFixed(1)}°'
        : 'N/A';

    return Row(
      children: [
        Expanded(
            child: _MiniCard(
                icon: Icons.speed_rounded,
                label: 'VELOCIDAD',
                value: speed,
                color: AppTheme.warning)),
        const SizedBox(width: 12),
        Expanded(
            child: _MiniCard(
                icon: Icons.terrain_rounded,
                label: 'ALTITUD',
                value: altitude,
                color: AppTheme.success)),
        const SizedBox(width: 12),
        Expanded(
            child: _MiniCard(
                icon: Icons.explore_rounded,
                label: 'RUMBO',
                value: heading,
                color: AppTheme.accent)),
      ],
    );
  }

  Widget _buildAccuracyCard() {
    final accuracy = _position!.accuracy;
    final qualityColor = accuracy < 10
        ? AppTheme.success
        : accuracy < 50
            ? AppTheme.warning
            : AppTheme.error;
    final qualityLabel = accuracy < 10
        ? 'EXCELENTE'
        : accuracy < 50
            ? 'BUENA'
            : 'BAJA';

    return _GlowCard(
      glowColor: qualityColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PRECISIÓN GPS',
                  style: Theme.of(context).textTheme.labelLarge),
              Text(
                qualityLabel,
                style: TextStyle(
                  color: qualityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.my_location_rounded, color: qualityColor, size: 18),
              const SizedBox(width: 8),
              Text(
                '±${accuracy.toStringAsFixed(1)} metros',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: qualityColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (1 - (accuracy / 100).clamp(0.0, 1.0)),
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(qualityColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchLocation,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('ACTUALIZAR UBICACIÓN'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _toggleStream,
            icon: Icon(
              _isStreaming ? Icons.stop_rounded : Icons.stream_rounded,
              size: 20,
            ),
            label:
                Text(_isStreaming ? 'DETENER STREAM' : 'INICIAR STREAM EN VIVO'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  _isStreaming ? AppTheme.error : AppTheme.success,
              side: BorderSide(
                color: _isStreaming ? AppTheme.error : AppTheme.success,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets auxiliares ───────────────────────────────────────────────────────

class _GlowCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;

  const _GlowCard({
    required this.child,
    this.glowColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: glowColor.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CoordRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CoordRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Radar Painter ────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Círculos concéntricos
    for (int i = 1; i <= 3; i++) {
      final paint = Paint()
        ..color = AppTheme.primary.withOpacity(0.15 * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, radius * (i / 3), paint);
    }

    // Línea de barrido
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primary.withOpacity(0.6),
          AppTheme.primary.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi / 3,
      true,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) => false;
}

