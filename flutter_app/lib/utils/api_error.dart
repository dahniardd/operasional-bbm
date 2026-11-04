import 'package:dio/dio.dart';

String parseApiError(DioException error, String fallback) {
  final data = error.response?.data;

  if (data is Map) {
    final errors = data['errors'];

    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;

      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }

      return first.toString();
    }

    if (data['message'] != null) {
      return data['message'].toString();
    }
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError) {
    return 'Gagal terhubung ke server. Periksa koneksi dan alamat API.';
  }

  return fallback;
}
