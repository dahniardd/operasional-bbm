import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/harga_bbm.dart';
import '../services/api_service.dart';
import '../utils/api_error.dart';

class HargaBbmProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<HargaBbm> _hargaList = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _successMessage;

  List<HargaBbm> get hargaList => _hargaList;
  HargaBbm? get terakhir => _hargaList.isNotEmpty ? _hargaList.first : null;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _error = null;
    _successMessage = null;
  }

  Future<void> loadHargaBbm() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getHargaBbm();
      final data = res.data['data'] as List? ?? [];

      _hargaList = data
          .map((item) => HargaBbm.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = parseApiError(e, 'Gagal memuat data harga BBM.');
    } catch (_) {
      _error = 'Gagal memuat data harga BBM.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveHargaBbm(
    Map<String, dynamic> payload, {
    int? id,
  }) async {
    _isSubmitting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final res = await _api.storeHargaBbm(payload, id: id);
      _successMessage = res.data['message']?.toString() ??
          'Data harga BBM berhasil disimpan.';
      _isSubmitting = false;
      notifyListeners();

      await loadHargaBbm();

      return true;
    } on DioException catch (e) {
      _error = parseApiError(e, 'Gagal menyimpan harga BBM.');
      _isSubmitting = false;
      notifyListeners();

      return false;
    }
  }

  Future<bool> deleteHargaBbm(int id) async {
    _error = null;
    _successMessage = null;

    try {
      final res = await _api.deleteHargaBbm(id);
      _successMessage = res.data['message']?.toString() ??
          'Data harga BBM berhasil dihapus.';
      _hargaList.removeWhere((item) => item.id == id);
      notifyListeners();

      return true;
    } on DioException catch (e) {
      _error = parseApiError(e, 'Gagal menghapus harga BBM.');
      notifyListeners();

      return false;
    }
  }

  double? hargaUntukTanggal(DateTime tanggal, String jenis) {
    for (final harga in _hargaList) {
      final berlaku = DateTime(
        harga.tanggalBerlaku.year,
        harga.tanggalBerlaku.month,
        harga.tanggalBerlaku.day,
      );
      final target = DateTime(tanggal.year, tanggal.month, tanggal.day);

      if (!berlaku.isAfter(target)) {
        return harga.hargaUntuk(jenis);
      }
    }

    return null;
  }
}
