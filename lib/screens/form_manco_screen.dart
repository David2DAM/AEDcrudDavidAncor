import 'package:flutter/material.dart';
import '../models/manco.dart';
import '../services/couchdb_service.dart';

class FormMancoScreen extends StatefulWidget {
  final Manco? manco;
  final CouchDbService servicio;

  const FormMancoScreen({super.key, this.manco, required this.servicio});

  @override
  State<FormMancoScreen> createState() => _FormMancoScreenState();
}

class _FormMancoScreenState extends State<FormMancoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _gamertag;
  late final TextEditingController _nombreReal;
  late final TextEditingController _edad;
  late final TextEditingController _juego;
  late final TextEditingController _genero;
  late final TextEditingController _plataforma;
  late final TextEditingController _fecha;
  late final TextEditingController _excusa;
  late final TextEditingController _rageo;
  late final TextEditingController _perifericos;
  late final TextEditingController _pingFalso;
  late final TextEditingController _pingReal;
  late final TextEditingController _frase;
  late final TextEditingController _ragequitsPrevios;
  late final TextEditingController _abandonadas;
  late final TextEditingController _culpables;
  late final TextEditingController _rango;
  late final TextEditingController _coste;

  bool _reincidente = false;
  bool _verificado = false;
  bool _guardando = false;

  bool get _esEdicion => widget.manco != null;

  @override
  void initState() {
    super.initState();
    final m = widget.manco;
    _gamertag = TextEditingController(text: m?.gamertag ?? '');
    _nombreReal = TextEditingController(text: m?.nombreReal ?? '');
    _edad = TextEditingController(text: m?.edad.toString() ?? '');
    _juego = TextEditingController(text: m?.juegoJugado ?? '');
    _genero = TextEditingController(text: m?.generoJuego ?? '');
    _plataforma = TextEditingController(text: m?.plataforma ?? '');
    _fecha = TextEditingController(
      text: m?.fechaIncidente ?? DateTime.now().toUtc().toIso8601String(),
    );
    _excusa = TextEditingController(text: m?.excusaRidicula ?? '');
    _rageo = TextEditingController(text: m?.nivelDeRageo.toString() ?? '5');
    _perifericos = TextEditingController(
      text: m?.perifericosDestruidos.join(', ') ?? '',
    );
    _pingFalso = TextEditingController(
      text: m?.pingFalsoAlegado.toString() ?? '0',
    );
    _pingReal = TextEditingController(text: m?.pingReal.toString() ?? '0');
    _frase = TextEditingController(text: m?.fraseCelebre ?? '');
    _ragequitsPrevios = TextEditingController(
      text: m?.numeroRagequitsPrevios.toString() ?? '0',
    );
    _abandonadas = TextEditingController(
      text: m?.partidasAbandonadasUltimoMes.toString() ?? '0',
    );
    _culpables = TextEditingController(
      text: m?.culpablesSegunEl.join(', ') ?? '',
    );
    _rango = TextEditingController(text: m?.rangoOElo ?? '');
    _coste = TextEditingController(
      text: m?.costeEstimadoDestrozosEur.toString() ?? '0',
    );
    _reincidente = m?.reincidente ?? false;
    _verificado = m?.verificadoPorAdmin ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _gamertag,
      _nombreReal,
      _edad,
      _juego,
      _genero,
      _plataforma,
      _fecha,
      _excusa,
      _rageo,
      _perifericos,
      _pingFalso,
      _pingReal,
      _frase,
      _ragequitsPrevios,
      _abandonadas,
      _culpables,
      _rango,
      _coste,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _splitCsv(String texto) {
    return texto
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final actual = widget.manco;
    final mancoAEnviar = Manco(
      id: actual?.id,
      rev: actual?.rev,
      gamertag: _gamertag.text,
      nombreReal: _nombreReal.text,
      edad: int.tryParse(_edad.text) ?? 0,
      juegoJugado: _juego.text,
      generoJuego: _genero.text,
      plataforma: _plataforma.text,
      fechaIncidente: _fecha.text,
      excusaRidicula: _excusa.text,
      nivelDeRageo: int.tryParse(_rageo.text) ?? 0,
      perifericosDestruidos: _splitCsv(_perifericos.text),
      pingFalsoAlegado: int.tryParse(_pingFalso.text) ?? 0,
      pingReal: int.tryParse(_pingReal.text) ?? 0,
      fraseCelebre: _frase.text,
      reincidente: _reincidente,
      numeroRagequitsPrevios: int.tryParse(_ragequitsPrevios.text) ?? 0,
      partidasAbandonadasUltimoMes: int.tryParse(_abandonadas.text) ?? 0,
      culpablesSegunEl: _splitCsv(_culpables.text),
      rangoOElo: _rango.text,
      verificadoPorAdmin: _verificado,
      costeEstimadoDestrozosEur: num.tryParse(_coste.text) ?? 0,
    );

    try {
      if (_esEdicion) {
        await widget.servicio.actualizar(mancoAEnviar);
      } else {
        await widget.servicio.crear(mancoAEnviar);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _campo(
    String label,
    TextEditingController controller, {
    TextInputType? tipo,
    bool requerido = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: tipo,
        maxLines: maxLines,
        validator: requerido
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar Manco' : 'Nuevo Manco')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _campo('Gamertag', _gamertag),
            _campo('Nombre real', _nombreReal),
            _campo('Edad', _edad, tipo: TextInputType.number),
            _campo('Juego jugado', _juego),
            _campo('Género del juego', _genero),
            _campo('Plataforma', _plataforma),
            _campo('Fecha del incidente (ISO-8601)', _fecha),
            _campo('Excusa ridícula', _excusa, maxLines: 3),
            _campo('Nivel de rageo (1-10)', _rageo, tipo: TextInputType.number),
            _campo(
              'Periféricos destruidos (separados por coma)',
              _perifericos,
              requerido: false,
            ),
            _campo(
              'Ping falso alegado (ms)',
              _pingFalso,
              tipo: TextInputType.number,
            ),
            _campo('Ping real (ms)', _pingReal, tipo: TextInputType.number),
            _campo('Frase célebre', _frase, maxLines: 2),
            _campo(
              'Ragequits previos',
              _ragequitsPrevios,
              tipo: TextInputType.number,
            ),
            _campo(
              'Partidas abandonadas último mes',
              _abandonadas,
              tipo: TextInputType.number,
            ),
            _campo(
              'Culpables según él (separados por coma)',
              _culpables,
              requerido: false,
            ),
            _campo('Rango o ELO', _rango, requerido: false),
            _campo(
              'Coste estimado destrozos (EUR)',
              _coste,
              tipo: TextInputType.number,
            ),
            CheckboxListTile(
              title: const Text('Reincidente'),
              value: _reincidente,
              onChanged: (v) => setState(() => _reincidente = v ?? false),
            ),
            CheckboxListTile(
              title: const Text('Verificado por admin'),
              value: _verificado,
              onChanged: (v) => setState(() => _verificado = v ?? false),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(
                _guardando
                    ? 'Guardando...'
                    : (_esEdicion ? 'Actualizar' : 'Crear'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
