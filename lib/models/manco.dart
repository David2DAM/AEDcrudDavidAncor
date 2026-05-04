/// Representa un incidente del Registro Oficial de Mancos y Ragequits.
///
/// Los campos `id` y `rev` se mapean a los campos reservados `_id` y `_rev`
/// que gestiona CouchDB. El resto son campos libres definidos por nosotros.
class Manco {
  final String? id;
  final String? rev;
  final String gamertag;
  final String nombreReal;
  final int edad;
  final String juegoJugado;
  final String generoJuego;
  final String plataforma;
  final String fechaIncidente;
  final String excusaRidicula;
  final int nivelDeRageo;
  final List<String> perifericosDestruidos;
  final int pingFalsoAlegado;
  final int pingReal;
  final String fraseCelebre;
  final bool reincidente;
  final int numeroRagequitsPrevios;
  final int partidasAbandonadasUltimoMes;
  final List<String> culpablesSegunEl;
  final String rangoOElo;
  final bool verificadoPorAdmin;
  final num costeEstimadoDestrozosEur;

  Manco({
    this.id,
    this.rev,
    required this.gamertag,
    required this.nombreReal,
    required this.edad,
    required this.juegoJugado,
    required this.generoJuego,
    required this.plataforma,
    required this.fechaIncidente,
    required this.excusaRidicula,
    required this.nivelDeRageo,
    required this.perifericosDestruidos,
    required this.pingFalsoAlegado,
    required this.pingReal,
    required this.fraseCelebre,
    required this.reincidente,
    required this.numeroRagequitsPrevios,
    required this.partidasAbandonadasUltimoMes,
    required this.culpablesSegunEl,
    required this.rangoOElo,
    required this.verificadoPorAdmin,
    required this.costeEstimadoDestrozosEur,
  });

  /// Construye un Manco desde el JSON que devuelve CouchDB.
  factory Manco.fromJson(Map<String, dynamic> json) {
    return Manco(
      id: json['_id'] as String?,
      rev: json['_rev'] as String?,
      gamertag: json['gamertag'] ?? '',
      nombreReal: json['nombre_real'] ?? '',
      edad: json['edad'] ?? 0,
      juegoJugado: json['juego_jugado'] ?? '',
      generoJuego: json['genero_juego'] ?? '',
      plataforma: json['plataforma'] ?? '',
      fechaIncidente: json['fecha_incidente'] ?? '',
      excusaRidicula: json['excusa_ridicula'] ?? '',
      nivelDeRageo: json['nivel_de_rageo'] ?? 0,
      perifericosDestruidos: List<String>.from(
        json['perifericos_destruidos'] ?? [],
      ),
      pingFalsoAlegado: json['ping_falso_alegado'] ?? 0,
      pingReal: json['ping_real'] ?? 0,
      fraseCelebre: json['frase_celebre'] ?? '',
      reincidente: json['reincidente'] ?? false,
      numeroRagequitsPrevios: json['numero_ragequits_previos'] ?? 0,
      partidasAbandonadasUltimoMes:
          json['partidas_abandonadas_ultimo_mes'] ?? 0,
      culpablesSegunEl: List<String>.from(json['culpables_segun_el'] ?? []),
      rangoOElo: json['rango_o_elo'] ?? '',
      verificadoPorAdmin: json['verificado_por_admin'] ?? false,
      costeEstimadoDestrozosEur: json['coste_estimado_destrozos_eur'] ?? 0,
    );
  }

  /// Convierte el Manco a un mapa JSON listo para enviar a CouchDB.
  /// Si [includeRev] es true, incluye el `_rev` (necesario para UPDATE).
  Map<String, dynamic> toJson({bool includeRev = false}) {
    final map = <String, dynamic>{
      'gamertag': gamertag,
      'nombre_real': nombreReal,
      'edad': edad,
      'juego_jugado': juegoJugado,
      'genero_juego': generoJuego,
      'plataforma': plataforma,
      'fecha_incidente': fechaIncidente,
      'excusa_ridicula': excusaRidicula,
      'nivel_de_rageo': nivelDeRageo,
      'perifericos_destruidos': perifericosDestruidos,
      'ping_falso_alegado': pingFalsoAlegado,
      'ping_real': pingReal,
      'frase_celebre': fraseCelebre,
      'reincidente': reincidente,
      'numero_ragequits_previos': numeroRagequitsPrevios,
      'partidas_abandonadas_ultimo_mes': partidasAbandonadasUltimoMes,
      'culpables_segun_el': culpablesSegunEl,
      'rango_o_elo': rangoOElo,
      'verificado_por_admin': verificadoPorAdmin,
      'coste_estimado_destrozos_eur': costeEstimadoDestrozosEur,
    };
    if (includeRev && rev != null) {
      map['_rev'] = rev;
    }
    return map;
  }

  /// Devuelve una copia del Manco con los campos id/rev actualizados.
  /// Útil tras un POST/PUT, cuando CouchDB nos devuelve un nuevo `_rev`.
  Manco copyWith({String? id, String? rev}) {
    return Manco(
      id: id ?? this.id,
      rev: rev ?? this.rev,
      gamertag: gamertag,
      nombreReal: nombreReal,
      edad: edad,
      juegoJugado: juegoJugado,
      generoJuego: generoJuego,
      plataforma: plataforma,
      fechaIncidente: fechaIncidente,
      excusaRidicula: excusaRidicula,
      nivelDeRageo: nivelDeRageo,
      perifericosDestruidos: perifericosDestruidos,
      pingFalsoAlegado: pingFalsoAlegado,
      pingReal: pingReal,
      fraseCelebre: fraseCelebre,
      reincidente: reincidente,
      numeroRagequitsPrevios: numeroRagequitsPrevios,
      partidasAbandonadasUltimoMes: partidasAbandonadasUltimoMes,
      culpablesSegunEl: culpablesSegunEl,
      rangoOElo: rangoOElo,
      verificadoPorAdmin: verificadoPorAdmin,
      costeEstimadoDestrozosEur: costeEstimadoDestrozosEur,
    );
  }
}
