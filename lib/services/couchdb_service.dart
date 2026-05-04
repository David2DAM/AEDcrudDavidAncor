import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manco.dart';

/// Servicio responsable EXCLUSIVAMENTE de la comunicación con CouchDB.
///
/// No depende de Flutter. Todas las operaciones devuelven datos del dominio
/// (Manco) o lanzan [CouchDbException] si CouchDB responde con un error.
class CouchDbService {
  final String baseUrl;
  final String dbName;
  final String username;
  final String password;

  CouchDbService({
    this.baseUrl = 'http://127.0.0.1:5984',
    this.dbName = 'mancos_ragequits',
    this.username = 'admin',
    this.password = 'tu_password',
  });

  /// Cabecera de Autorización Básica HTTP.
  Map<String, String> get _headers {
    final credenciales = base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': 'Basic $credenciales',
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl/$dbName$path').replace(queryParameters: query);
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// READ — Obtener todos los mancos.
  Future<List<Manco>> obtenerTodos() async {
    final response = await http.get(
      _uri('/_all_docs', {'include_docs': 'true'}),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw CouchDbException(
        'Error al listar mancos',
        response.statusCode,
        response.body,
      );
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final List rows = body['rows'] ?? [];

    return rows
        .where((row) => !(row['id'] as String).startsWith('_design/'))
        .map((row) => Manco.fromJson(row['doc'] as Map<String, dynamic>))
        .toList();
  }

  /// CREATE — Insertar un nuevo manco.
  Future<Manco> crear(Manco manco) async {
    final response = await http.post(
      _uri(''),
      headers: _headers,
      body: jsonEncode(manco.toJson()),
    );

    if (response.statusCode != 201) {
      throw CouchDbException(
        'Error al crear el manco',
        response.statusCode,
        response.body,
      );
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return manco.copyWith(id: body['id'] as String, rev: body['rev'] as String);
  }

  /// UPDATE — Modificar un manco existente.
  Future<Manco> actualizar(Manco manco) async {
    if (manco.id == null || manco.rev == null) {
      throw ArgumentError('Para actualizar, el Manco debe tener _id y _rev.');
    }

    final response = await http.put(
      _uri('/${manco.id}'),
      headers: _headers,
      body: jsonEncode(manco.toJson(includeRev: true)),
    );

    if (response.statusCode != 201) {
      throw CouchDbException(
        'Error al actualizar el manco',
        response.statusCode,
        response.body,
      );
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return manco.copyWith(rev: body['rev'] as String);
  }

  /// DELETE — Eliminar un manco.
  Future<void> eliminar(String id, String rev) async {
    final response = await http.delete(
      _uri('/$id', {'rev': rev}),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw CouchDbException(
        'Error al eliminar el manco',
        response.statusCode,
        response.body,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CONSULTAS ESTRELLA — agregaciones y filtros avanzados
  // ---------------------------------------------------------------------------

  /// Crea o ACTUALIZA el design document con las vistas necesarias.
  ///
  /// Comportamiento:
  /// - Si el design doc no existe: lo crea con todas las vistas requeridas.
  /// - Si existe pero le falta alguna vista: la añade conservando las
  ///   existentes y respetando el _rev actual.
  /// - Si ya tiene todas las vistas: no hace nada.
  Future<void> _asegurarDesignDocs() async {
    const designId = '_design/estadisticas';

    // Vistas que SIEMPRE deben existir en el design document.
    final Map<String, dynamic> viewsRequeridas = {
      'por_juego': {
        'map': '''
          function (doc) {
            if (doc.juego_jugado && doc.nivel_de_rageo !== undefined) {
              emit(doc.juego_jugado, {
                incidentes: 1,
                coste: doc.coste_estimado_destrozos_eur || 0,
                rageo_total: doc.nivel_de_rageo,
                rageo_max: doc.nivel_de_rageo
              });
            }
          }
        ''',
        'reduce': '''
          function (keys, values, rereduce) {
            var resultado = {
              incidentes: 0, coste_total: 0,
              rageo_total: 0, rageo_max: 0
            };
            values.forEach(function (v) {
              resultado.incidentes  += v.incidentes;
              resultado.coste_total += v.coste;
              resultado.rageo_total += v.rageo_total;
              if (v.rageo_max > resultado.rageo_max) {
                resultado.rageo_max = v.rageo_max;
              }
            });
            resultado.coste_medio = +(resultado.coste_total / resultado.incidentes).toFixed(2);
            resultado.rageo_medio = +(resultado.rageo_total / resultado.incidentes).toFixed(2);
            return resultado;
          }
        ''',
      },
      'coste_global': {
        'map': '''
          function (doc) {
            if (doc.coste_estimado_destrozos_eur !== undefined) {
              emit(null, doc.coste_estimado_destrozos_eur);
            }
          }
        ''',
        'reduce': '_stats',
      },
    };

    // Comprobamos el estado actual en el servidor
    final getResp = await http.get(_uri('/$designId'), headers: _headers);

    Map<String, dynamic> designDoc;

    if (getResp.statusCode == 200) {
      // El design doc YA existe. Vemos si le faltan vistas.
      final existing =
          jsonDecode(utf8.decode(getResp.bodyBytes)) as Map<String, dynamic>;
      final Map<String, dynamic> existingViews = Map<String, dynamic>.from(
        existing['views'] ?? {},
      );

      final tieneTodas = viewsRequeridas.keys.every(existingViews.containsKey);

      if (tieneTodas) {
        // Está al día, no hace falta hacer nada.
        return;
      }

      // Mezcla: lo nuevo sobrescribe a lo viejo si comparten nombre.
      final viewsMezcladas = {...existingViews, ...viewsRequeridas};

      designDoc = {
        '_rev': existing['_rev'],
        'language': 'javascript',
        'views': viewsMezcladas,
      };
    } else if (getResp.statusCode == 404) {
      // El design doc no existe todavía: lo creamos desde cero.
      designDoc = {'language': 'javascript', 'views': viewsRequeridas};
    } else {
      throw CouchDbException(
        'Error al consultar el design document',
        getResp.statusCode,
        getResp.body,
      );
    }

    // PUT — crea o actualiza
    final putResp = await http.put(
      _uri('/$designId'),
      headers: _headers,
      body: jsonEncode(designDoc),
    );

    if (putResp.statusCode != 201) {
      throw CouchDbException(
        'Error al crear o actualizar el design document',
        putResp.statusCode,
        putResp.body,
      );
    }
  }

  /// Devuelve estadísticas globales del coste de destrozos
  /// usando la vista `coste_global` con el built-in `_stats`.
  ///
  /// El resultado contiene: sum, count, min, max, sumsqr.
  /// La media se calcula como sum / count.
  Future<Map<String, dynamic>> obtenerEstadisticasCoste() async {
    await _asegurarDesignDocs();

    final resp = await http.get(
      _uri('/_design/estadisticas/_view/coste_global', {
        'reduce': 'true',
        'group': 'false',
      }),
      headers: _headers,
    );

    if (resp.statusCode != 200) {
      throw CouchDbException(
        'Error al obtener estadísticas',
        resp.statusCode,
        resp.body,
      );
    }

    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    final rows = body['rows'] as List;
    if (rows.isEmpty) return {};
    return Map<String, dynamic>.from(rows[0]['value']);
  }

  /// Devuelve el ranking de juegos agrupado, usando la vista MapReduce
  /// `por_juego`. Cada elemento del resultado contiene:
  /// juego, incidentes, coste_total, coste_medio, rageo_medio, rageo_max.
  Future<List<Map<String, dynamic>>> obtenerRankingPorJuego() async {
    await _asegurarDesignDocs();

    final resp = await http.get(
      _uri('/_design/estadisticas/_view/por_juego', {
        'reduce': 'true',
        'group': 'true',
      }),
      headers: _headers,
    );

    if (resp.statusCode != 200) {
      throw CouchDbException(
        'Error al obtener ranking',
        resp.statusCode,
        resp.body,
      );
    }

    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    final rows = body['rows'] as List;
    return rows.map<Map<String, dynamic>>((r) {
      return {'juego': r['key'], ...Map<String, dynamic>.from(r['value'])};
    }).toList();
  }

  /// Ejecuta una Mango Query para localizar mancos peligrosos:
  /// reincidentes, con rageo alto o muchos abandonos, que mienten sobre
  /// el ping y han destrozado mando o teclado.
  Future<List<Manco>> obtenerMancosPeligrosos() async {
    final body = {
      'selector': {
        r'$and': [
          {
            'reincidente': {r'$eq': true},
          },
          {
            r'$or': [
              {
                'nivel_de_rageo': {r'$gte': 8},
              },
              {
                'partidas_abandonadas_ultimo_mes': {r'$gt': 10},
              },
            ],
          },
          {
            'ping_falso_alegado': {r'$gte': 100},
          },
          {
            'perifericos_destruidos': {
              r'$elemMatch': {r'$regex': '(?i)mando|teclado'},
            },
          },
        ],
      },
    };

    final resp = await http.post(
      _uri('/_find'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw CouchDbException(
        'Error en la consulta Mango',
        resp.statusCode,
        resp.body,
      );
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    final docs = data['docs'] as List;
    return docs.map((d) => Manco.fromJson(d as Map<String, dynamic>)).toList();
  }
}

/// Excepción específica para errores devueltos por CouchDB.
class CouchDbException implements Exception {
  final String mensaje;
  final int codigoHttp;
  final String cuerpoRespuesta;

  CouchDbException(this.mensaje, this.codigoHttp, this.cuerpoRespuesta);

  @override
  String toString() =>
      'CouchDbException($codigoHttp): $mensaje\n$cuerpoRespuesta';
}
