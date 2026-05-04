import 'package:flutter/material.dart';
import '../models/manco.dart';
import '../services/couchdb_service.dart';
import 'form_manco_screen.dart';
import 'consulta_estrella_screen.dart';

class ListaMancosScreen extends StatefulWidget {
  const ListaMancosScreen({super.key});

  @override
  State<ListaMancosScreen> createState() => _ListaMancosScreenState();
}

class _ListaMancosScreenState extends State<ListaMancosScreen> {
  final CouchDbService _servicio = CouchDbService();
  late Future<List<Manco>> _futureMancos;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() {
      _futureMancos = _servicio.obtenerTodos();
    });
  }

  Future<void> _abrirFormulario({Manco? manco}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormMancoScreen(manco: manco, servicio: _servicio),
      ),
    );
    if (resultado == true) _recargar();
  }

  Future<void> _abrirConsultaEstrella() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultaEstrellaScreen(servicio: _servicio),
      ),
    );
  }

  Future<void> _confirmarYEliminar(Manco manco) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar manco?'),
        content: Text('Se eliminará a "${manco.gamertag}" del registro.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _servicio.eliminar(manco.id!, manco.rev!);
      _mostrarMensaje('Manco eliminado correctamente.');
      _recargar();
    } catch (e) {
      _mostrarMensaje('Error al eliminar: $e');
    }
  }

  /// Muestra un dialog con la media y estadísticas globales del coste
  /// de destrozos. Internamente consulta la vista MapReduce con _stats.
  Future<void> _mostrarMediaCoste() async {
    // Mensaje de carga mientras CouchDB construye el índice (la primera vez)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Calculando estadísticas...'),
          ],
        ),
      ),
    );

    try {
      final stats = await _servicio.obtenerEstadisticasCoste();
      if (!mounted) return;
      Navigator.pop(context); // cierra el dialog de carga

      final count = (stats['count'] ?? 0) as num;
      final sum = (stats['sum'] ?? 0) as num;
      final media = count > 0 ? (sum / count) : 0;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Estadísticas de destrozos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total de mancos analizados: $count'),
              Text('Coste total acumulado: ${sum.toStringAsFixed(2)} €'),
              Text('Mínimo registrado: ${stats['min']} €'),
              Text('Máximo registrado: ${stats['max']} €'),
              const Divider(height: 24),
              Text(
                'Media: ${media.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Calculado con la vista MapReduce coste_global usando el reducer built-in _stats.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarMensaje('Error al calcular media: $e');
    }
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Mancos y Ragequits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            tooltip: 'Consultas Estrella',
            onPressed: _abrirConsultaEstrella,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar lista',
            onPressed: _recargar,
          ),
        ],
      ),

      // Dos botones flotantes: uno para la media, otro para añadir.
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'media',
            onPressed: _mostrarMediaCoste,
            icon: const Icon(Icons.euro),
            label: const Text('Media destrozos'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _abrirFormulario(),
            tooltip: 'Añadir manco',
            child: const Icon(Icons.add),
          ),
        ],
      ),

      body: FutureBuilder<List<Manco>>(
        future: _futureMancos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('ERROR: ${snapshot.error}'),
            );
          }
          final mancos = snapshot.data ?? [];
          if (mancos.isEmpty) {
            return const Center(child: Text('No hay mancos registrados.'));
          }
          return ListView.separated(
            itemCount: mancos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = mancos[i];
              return ListTile(
                title: Text('${m.gamertag}  —  Rageo: ${m.nivelDeRageo}/10'),
                subtitle: Text('${m.juegoJugado}\n"${m.excusaRidicula}"'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _abrirFormulario(manco: m),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmarYEliminar(m),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
