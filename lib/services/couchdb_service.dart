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
  /// CouchDB exige autenticación en TODAS las peticiones a la base de datos.
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
  // READ — Obtener todos los mancos.
  // GET /mancos_ragequits/_all_docs?include_docs=true
  // ---------------------------------------------------------------------------
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

    // Filtramos los documentos de diseño internos de CouchDB (_design/...)
    return rows
        .where((row) => !(row['id'] as String).startsWith('_design/'))
        .map((row) => Manco.fromJson(row['doc'] as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // CREATE — Insertar un nuevo manco.
  // POST /mancos_ragequits  (CouchDB genera el _id y el _rev automáticamente)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // UPDATE — Modificar un manco existente.
  // PUT /mancos_ragequits/{_id}  con el _rev actual en el body.
  //
  // CouchDB exige el _rev para evitar sobreescrituras concurrentes (MVCC).
  // Si el _rev enviado no coincide con el último, CouchDB devuelve 409 Conflict.
  // ---------------------------------------------------------------------------
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
    // CouchDB devuelve un nuevo _rev tras cada actualización: lo guardamos.
    return manco.copyWith(rev: body['rev'] as String);
  }

  // ---------------------------------------------------------------------------
  // DELETE — Eliminar un manco.
  // DELETE /mancos_ragequits/{_id}?rev={_rev}
  //
  // OJO: en CouchDB el rev NO va en el body para DELETE, va en la query string.
  // ---------------------------------------------------------------------------
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
