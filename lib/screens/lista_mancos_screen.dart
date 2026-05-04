import 'package:flutter/material.dart';
import '../models/manco.dart';
import '../services/couchdb_service.dart';
import 'form_manco_screen.dart';

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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _recargar),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
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
