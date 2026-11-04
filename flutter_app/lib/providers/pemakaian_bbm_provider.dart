import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/pemakaian_bbm.dart';
import '../services/api_service.dart';
import '../utils/api_error.dart';

class PemakaianBbmProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<PemakaianBbm> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  bool _isRefreshing = false;
  String? _error;
  String? _successMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  List<PemakaianBbm> get items => _items;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  String? get successMessage => _successMessage;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  bool get hasMore => _currentPage < _lastPage;

  void clearMessages() {
    _error = null;
    _successMessage = null;
  }

  Future<void> loadPemakaian({
    String? search,
    String? jenisKendaraan,
    int? kendaraanId,
    String? jenisBbm,
    String? lokasiPembelian,
    bool reset = true,
    int perPage = 20,
  }) async {
    if (reset) {
      _isLoading = true;
      _currentPage = 1;
    } else {
      if (!hasMore || _isLoadingMore) {
        return;
      }
      _isLoadingMore = true;
    }

    _error = null;
    notifyListeners();

    final page = reset ? 1 : _currentPage + 1;

    try {
      final res = await _api.getPemakaianBbm(
        search: search,
        jenisKendaraan: jenisKendaraan,
        kendaraanId: kendaraanId,
        jenisBbm: jenisBbm,
        lokasiPembelian: lokasiPembelian,
        page: page,
        perPage: perPage,
      );

      final data = res.data['data'] as List? ?? [];
      final meta = res.data['meta'] as Map<String, dynamic>? ?? {};
      final parsed = data
          .map((item) => PemakaianBbm.fromJson(item as Map<String, dynamic>))
          .toList();

      if (reset) {
        _items
          ..clear()
          ..addAll(parsed);
      } else {
        _items.addAll(parsed);
      }

      _currentPage = (meta['current_page'] as num?)?.toInt() ?? page;
      _lastPage = (meta['last_page'] as num?)?.toInt() ?? 1;
      _total = (meta['total'] as num?)?.toInt() ?? _items.length;
    } on DioException catch (e) {
      _error = parseApiError(e, 'Gagal memuat data pemakaian BBM.');
    } catch (_) {
      _error = 'Gagal memuat data pemakaian BBM.';
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<bool> savePemakaian(
    Map<String, dynamic> payload, {
    int? id,
  }) async {
    _isSubmitting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final res = await _api.storePemakaianBbm(payload, id: id);
      _successMessage = res.data['message']?.toString() ??
          'Data pemakaian BBM berhasil disimpan.';
      _isSubmitting = false;
      notifyListeners();

      await loadPemakaian();

      return true;
    } on DioException catch (e) {
      _error = parseApiError(e, 'Gagal menyimpan pemakaian BBM.');
      _isSubmitting = false;
      notifyListeners();

      return false;
    }
  }

  Future<bool> deletePemakaian(int id) async {
    _error = null;
    _successMessage = null;

    try {
      final res = await _api.deletePemakaianBbm(id);
      _successMessage = res.data['message']?.toString() ??
          'Data pemakaian BBM berhasil dihapus.';
      _items.removeWhere((item) => item.id == id);
      _total = _items.length;
      notifyListeners();

      return true;
    } on DioException catch (e) {
      _error = parseApiError(e, 'Gagal menghapus pemakaian BBM.');
      notifyListeners();

      return false;
    }
  }

  Future<bool> refreshHarga() async {
    _isRefreshing = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final res = await _api.refreshHargaPemakaian();
      _successMessage = res.data['message']?.toString() ??
          'Harga pemakaian BBM berhasil di-refresh.';
      _isRefreshing = false;
      notifyListeners();

      await loadPemakaian();

      return true;
    } on DioException catch (e) {
      _error = parseApiError(e, 'Gagal refresh harga pemakaian BBM.');
      _isRefreshing = false;
      notifyListeners();

      return false;
    }
  }
}
