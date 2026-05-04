import 'package:flutter/material.dart';
import '../models/manco.dart';
import '../services/couchdb_service.dart';

/// Pantalla que ejecuta y muestra las dos consultas avanzadas
/// directamente desde la app, sin necesidad de abrir Fauxton.
///
/// 1. Vista MapReduce `por_juego` — ranking agregado por juego.
/// 2. Mango Query — perfil de manco peligroso.
class ConsultaEstrellaScreen extends StatefulWidget {
  final CouchDbService servicio;

  const ConsultaEstrellaScreen({super.key, required this.servicio});

  @override
  State<ConsultaEstrellaScreen> createState() => _ConsultaEstrellaScreenState();
}

class _ConsultaEstrellaScreenState extends State<ConsultaEstrellaScreen> {
  late Future<List<Map<String, dynamic>>> _futureRanking;
  late Future<List<Manco>> _futurePeligrosos;

  @override
  void initState() {
    super.initState();
    _ejecutarConsultas();
  }

  void _ejecutarConsultas() {
    setState(() {
      _futureRanking = widget.servicio.obtenerRankingPorJuego();
      _futurePeligrosos = widget.servicio.obtenerMancosPeligrosos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultas Estrella'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reejecutar consultas',
            onPressed: _ejecutarConsultas,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ───── SECCIÓN 1: VISTA MAPREDUCE ─────
          const _SeccionTitulo(
            titulo: 'Ranking de juegos más tóxicos',
            subtitulo: 'Vista MapReduce — agrupa por juego y agrega métricas',
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureRanking,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('ERROR: ${snap.error}'),
                );
              }
              final ranking = snap.data ?? [];
              if (ranking.isEmpty) {
                return const Text('Sin datos.');
              }
              return Column(
                children: ranking
                    .map((r) => _TarjetaRanking(datos: r))
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 32),

          // ───── SECCIÓN 2: MANGO QUERY ─────
          const _SeccionTitulo(
            titulo: 'Perfil de manco peligroso',
            subtitulo:
                'Mango Query — reincidente + rageo extremo + miente sobre el ping + mando/teclado roto',
          ),
          FutureBuilder<List<Manco>>(
            future: _futurePeligrosos,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('ERROR: ${snap.error}'),
                );
              }
              final peligrosos = snap.data ?? [];
              if (peligrosos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Ningún manco cumple los cuatro filtros.'),
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Detectados ${peligrosos.length} mancos peligrosos:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...peligrosos.map((m) => _TarjetaPeligroso(manco: m)),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares (UI básica, sin maquillaje, como pidió el profesor)
// ─────────────────────────────────────────────────────────────────────────────

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const _SeccionTitulo({required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _TarjetaRanking extends StatelessWidget {
  final Map<String, dynamic> datos;

  const _TarjetaRanking({required this.datos});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              datos['juego']?.toString() ?? '?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Incidentes: ${datos['incidentes']}'),
            Text('Coste total: ${datos['coste_total']} €'),
            Text('Coste medio: ${datos['coste_medio']} €'),
            Text('Rageo medio: ${datos['rageo_medio']}/10'),
            Text('Rageo máximo: ${datos['rageo_max']}/10'),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPeligroso extends StatelessWidget {
  final Manco manco;

  const _TarjetaPeligroso({required this.manco});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${manco.gamertag}  —  Rageo ${manco.nivelDeRageo}/10',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Juego: ${manco.juegoJugado}'),
            Text(
              'Ping declarado: ${manco.pingFalsoAlegado} ms (real: ${manco.pingReal} ms)',
            ),
            Text(
              'Partidas abandonadas (último mes): ${manco.partidasAbandonadasUltimoMes}',
            ),
            Text(
              'Periféricos rotos: ${manco.perifericosDestruidos.join(", ")}',
            ),
            Text('Coste destrozos: ${manco.costeEstimadoDestrozosEur} €'),
          ],
        ),
      ),
    );
  }
}
