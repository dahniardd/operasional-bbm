import 'package:flutter/material.dart';

import '../models/kendaraan.dart';
import '../services/api_service.dart';

class MasterDataProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Kendaraan> _kendaraanList = [];
  List<String> _jenisKendaraanList = [];
  bool _isLoading = false;

  List<Kendaraan> get kendaraanList => _kendaraanList;
  List<String> get jenisKendaraanList => _jenisKendaraanList;
  bool get isLoading => _isLoading;

  Future<void> loadKendaraan() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getKendaraan();
      final data = res.data['data'] as List? ?? [];

      _kendaraanList = data
          .map((item) => Kendaraan.fromJson(item as Map<String, dynamic>))
          .toList();

      _jenisKendaraanList = (_kendaraanList
              .map((k) => k.namaJenis)
              .whereType<String>()
              .where((jenis) => jenis.isNotEmpty)
              .toSet()
              .toList())
        ..sort();
    } catch (_) {
      _kendaraanList = [];
      _jenisKendaraanList = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Kendaraan? byId(int? id) {
    if (id == null) {
      return null;
    }

    for (final kendaraan in _kendaraanList) {
      if (kendaraan.id == id) {
        return kendaraan;
      }
    }

    return null;
  }
}
