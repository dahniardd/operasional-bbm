import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: ApiConfig.defaultHeaders,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await StorageService.clearAll();
          }

          return handler.next(error);
        },
      ),
    );
  }

  // ============================================================
  // AUTH
  // ============================================================

  Future<Response> login(String username, String password) {
    return _dio.post(
      '/login.php',
      data: {
        'username': username,
        'password': password,
      },
    );
  }

  Future<Response> logout() {
    return _dio.post('/logout.php');
  }

  Future<Response> getUser() {
    return _dio.get('/user.php');
  }

  // ============================================================
  // MASTER KENDARAAN
  // ============================================================

  Future<Response> getKendaraan({
    String? search,
    String? jenisKendaraan,
  }) {
    return _dio.get(
      '/kendaraan.php',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (jenisKendaraan != null && jenisKendaraan.isNotEmpty)
          'jenis_kendaraan': jenisKendaraan,
      },
    );
  }

  // ============================================================
  // HARGA BBM
  // ============================================================

  Future<Response> getHargaBbm() {
    return _dio.get('/harga_bbm.php');
  }

  Future<Response> getHargaBerlaku({
    required String tanggal,
    required String jenis,
  }) {
    return _dio.get(
      '/harga_bbm.php',
      queryParameters: {
        'action': 'berlaku',
        'tanggal': tanggal,
        'jenis': jenis,
      },
    );
  }

  Future<Response> storeHargaBbm(
    Map<String, dynamic> payload, {
    int? id,
  }) {
    final query = <String, dynamic>{};

    if (id != null) {
      query['id'] = id;
    }

    return _dio.post(
      '/harga_bbm.php',
      data: payload,
      queryParameters: query,
    );
  }

  Future<Response> deleteHargaBbm(int id) {
    return _dio.delete(
      '/harga_bbm.php',
      queryParameters: {'id': id},
    );
  }

  // ============================================================
  // PEMAKAIAN BBM
  // ============================================================

  Future<Response> getPemakaianBbm({
    String? search,
    String? jenisKendaraan,
    int? kendaraanId,
    String? jenisBbm,
    String? lokasiPembelian,
    String? scope, // 'mine' = milik sendiri, 'others' = driver lain
    int page = 1,
    int perPage = 20,
  }) {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    if (jenisKendaraan != null && jenisKendaraan.isNotEmpty) {
      query['jenis_kendaraan'] = jenisKendaraan;
    }

    if (kendaraanId != null) {
      query['kendaraan_id'] = kendaraanId;
    }

    if (jenisBbm != null && jenisBbm.isNotEmpty) {
      query['jenis_bbm'] = jenisBbm;
    }

    if (lokasiPembelian != null && lokasiPembelian.isNotEmpty) {
      query['lokasi_pembelian'] = lokasiPembelian;
    }

    if (scope != null && scope.isNotEmpty) {
      query['scope'] = scope;
    }

    return _dio.get(
      '/pemakaian_bbm.php',
      queryParameters: query,
    );
  }

  Future<Response> storePemakaianBbm(
    Map<String, dynamic> payload, {
    int? id,
  }) {
    final query = <String, dynamic>{};

    if (id != null) {
      query['id'] = id;
    }

    return _dio.post(
      '/pemakaian_bbm.php',
      data: payload,
      queryParameters: query,
    );
  }

  Future<Response> deletePemakaianBbm(int id) {
    return _dio.delete(
      '/pemakaian_bbm.php',
      queryParameters: {'id': id},
    );
  }

  Future<Response> refreshHargaPemakaian() {
    return _dio.post(
      '/pemakaian_bbm.php',
      queryParameters: {'action': 'refresh_harga'},
    );
  }
}