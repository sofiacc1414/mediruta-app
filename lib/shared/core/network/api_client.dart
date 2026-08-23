import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_exception.dart';

/// Wrapper base para hablar con la API de MediRuta.
///
/// La App NUNCA llama a Supabase directamente — ni para datos ni para
/// autenticación (DOCS/context.md, Parte B, secciones 4.1 y 11). Todo pasa
/// por aquí. El token JWT (propio, emitido por la API) se guarda en
/// almacenamiento seguro, nunca en SharedPreferences ni en memoria plana.
///
/// Este cliente es del flujo App: nunca manda el header `X-Client-Type` que
/// usa el Web para pedir el refresh token por cookie HttpOnly — la App
/// recibe el refresh token en el JSON de la respuesta y lo persiste acá.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  }) : _http = httpClient ?? http.Client(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final String baseUrl;
  final http.Client _http;
  final FlutterSecureStorage _secureStorage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// Se conecta desde `auth_session_provider` para renovar la sesión ante
  /// un 401 en un endpoint autenticado. Devuelve `true` si logró renovar
  /// el access token (y por lo tanto vale la pena reintentar el request
  /// original una sola vez).
  Future<bool> Function()? onSesionExpirada;

  Future<String?> get accessToken => _secureStorage.read(key: _accessTokenKey);

  Future<String?> get refreshToken => _secureStorage.read(key: _refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  void close() => _http.close();

  /// GET a `path` (relativo a [baseUrl]). Si `autenticado` es true, adjunta
  /// el access token guardado y reintenta una vez tras renovarlo ante 401.
  Future<dynamic> get(String path, {bool autenticado = false}) {
    return _request('GET', path, autenticado: autenticado);
  }

  /// POST a `path` con `body` como JSON. Si `autenticado` es true, adjunta
  /// el access token guardado y reintenta una vez tras renovarlo ante 401.
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool autenticado = false,
  }) {
    return _request('POST', path, body: body, autenticado: autenticado);
  }

  /// PATCH a `path` con `body` como JSON. Si `autenticado` es true, adjunta
  /// el access token guardado y reintenta una vez tras renovarlo ante 401.
  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool autenticado = false,
  }) {
    return _request('PATCH', path, body: body, autenticado: autenticado);
  }

  /// POST multipart a `path` con un único archivo (campo `archivo`, mismo
  /// nombre que espera `FileInterceptor('archivo')` en la API) y campos de
  /// texto adicionales opcionales (ej. `tipo` para documentos del
  /// Domiciliario). Mismo reintento ante 401 que `_request`.
  Future<dynamic> postMultipart(
    String path, {
    required List<int> bytes,
    required String nombreArchivo,
    required String contentType,
    Map<String, String>? campos,
    bool autenticado = false,
    bool esReintento = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    if (autenticado) {
      final token = await accessToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (campos != null) {
      request.fields.addAll(campos);
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: nombreArchivo,
        contentType: MediaType.parse(contentType),
      ),
    );

    late final http.Response respuesta;
    try {
      respuesta = await http.Response.fromStream(await _http.send(request));
    } on http.ClientException {
      throw const ApiSinConexionException();
    }

    if (respuesta.statusCode == 401 &&
        autenticado &&
        !esReintento &&
        onSesionExpirada != null) {
      final renovada = await onSesionExpirada!();
      if (renovada) {
        return postMultipart(
          path,
          bytes: bytes,
          nombreArchivo: nombreArchivo,
          contentType: contentType,
          campos: campos,
          autenticado: autenticado,
          esReintento: true,
        );
      }
    }

    return _decodificar(respuesta);
  }

  Future<dynamic> _request(
    String metodo,
    String path, {
    Map<String, dynamic>? body,
    required bool autenticado,
    bool esReintento = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};

    if (autenticado) {
      final token = await accessToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    late final http.Response respuesta;
    try {
      respuesta = switch (metodo) {
        'GET' => await _http.get(uri, headers: headers),
        'POST' => await _http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
        'PATCH' => await _http.patch(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
        _ => throw UnsupportedError('Método HTTP no soportado: $metodo'),
      };
    } on http.ClientException {
      throw const ApiSinConexionException();
    }

    if (respuesta.statusCode == 401 &&
        autenticado &&
        !esReintento &&
        onSesionExpirada != null) {
      final renovada = await onSesionExpirada!();
      if (renovada) {
        return _request(
          metodo,
          path,
          body: body,
          autenticado: autenticado,
          esReintento: true,
        );
      }
    }

    return _decodificar(respuesta);
  }

  dynamic _decodificar(http.Response respuesta) {
    final cuerpo = respuesta.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(respuesta.bodyBytes));

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return cuerpo;
    }

    throw ApiException(
      statusCode: respuesta.statusCode,
      message: _extraerMensaje(cuerpo),
    );
  }

  String _extraerMensaje(dynamic cuerpo) {
    if (cuerpo is Map && cuerpo['message'] != null) {
      final mensaje = cuerpo['message'];
      if (mensaje is List) {
        return mensaje.join(' ');
      }
      return mensaje.toString();
    }
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }
}
