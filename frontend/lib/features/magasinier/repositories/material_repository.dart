import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class MaterialItem {
  final String id;
  final String name;
  final String category;
  final String? refCode;
  final double unitPrice;
  final bool returnRequired;
  final bool isActive;

  MaterialItem({
    required this.id,
    required this.name,
    required this.category,
    this.refCode,
    required this.unitPrice,
    this.returnRequired = false,
    this.isActive = true,
  });

  bool get isEquipement =>
      category.toUpperCase() == 'EQUIPEMENT' ||
      category.toLowerCase() == 'consignable' ||
      returnRequired;

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      refCode: json['refCode'] as String?,
      unitPrice: _toDouble(json['unitPrice']),
      returnRequired: json['returnRequired'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class MaterialFicheLine {
  final String id;
  final String itemId;
  final int qtyRequested;
  final int qtyDelivered;
  final int qtyReturned;
  final String? outNotes;
  final String? returnNotes;
  final String? returnState;
  final bool isLost;
  final bool isChecked;
  final MaterialItem? item;
  final Map<String, dynamic>? retention;

  MaterialFicheLine({
    required this.id,
    required this.itemId,
    required this.qtyRequested,
    required this.qtyDelivered,
    required this.qtyReturned,
    this.outNotes,
    this.returnNotes,
    this.returnState,
    this.isLost = false,
    this.isChecked = false,
    this.item,
    this.retention,
  });

  factory MaterialFicheLine.fromJson(Map<String, dynamic> json) {
    return MaterialFicheLine(
      id: json['id'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      qtyRequested: _toInt(json['qtyRequested']),
      qtyDelivered: _toInt(json['qtyDelivered']),
      qtyReturned: _toInt(json['qtyReturned']),
      outNotes: json['outNotes'] as String?,
      returnNotes: json['returnNotes'] as String?,
      returnState: json['returnState'] as String?,
      isLost: json['isLost'] as bool? ?? false,
      isChecked: json['isChecked'] as bool? ?? false,
      item: json['item'] is Map
          ? MaterialItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
      retention: json['retention'] as Map<String, dynamic>?,
    );
  }
}

class MaterialFiche {
  final String id;
  final String code;
  final String siteId;
  final String status;
  final String? requestDate;
  final String? plannedReturn;
  final String? deliveredAt;
  final String? sector;
  final int? spaceCount;
  final int? personCount;
  final int? dayCount;
  final String? notes;
  final Map<String, dynamic>? site;
  final Map<String, dynamic>? requester;
  final Map<String, dynamic>? magasinier;
  final List<MaterialFicheLine> lines;

  MaterialFiche({
    required this.id,
    required this.code,
    required this.siteId,
    required this.status,
    this.requestDate,
    this.plannedReturn,
    this.deliveredAt,
    this.sector,
    this.spaceCount,
    this.personCount,
    this.dayCount,
    this.notes,
    this.site,
    this.requester,
    this.magasinier,
    this.lines = const [],
  });

  String get siteName => site?['name'] as String? ?? '';
  String get requesterName {
    if (requester == null) return '';
    return '${requester!['firstName'] ?? ''} ${requester!['lastName'] ?? ''}'.trim();
  }

  String get magasinierName {
    if (magasinier == null) return '';
    return '${magasinier!['firstName'] ?? ''} ${magasinier!['lastName'] ?? ''}'.trim();
  }

  String get statusLabel {
    switch (status) {
      case 'DRAFT':
        return 'Brouillon';
      case 'REQUESTED':
        return 'Demandée';
      case 'DELIVERED':
        return 'Livrée';
      case 'RETURN_IN_PROGRESS':
        return 'Retour en cours';
      case 'CLOSED':
        return 'Clôturée';
      default:
        return status;
    }
  }

  factory MaterialFiche.fromJson(Map<String, dynamic> json) {
    return MaterialFiche(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      siteId: json['siteId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      requestDate: json['requestDate'] as String?,
      plannedReturn: json['plannedReturn'] as String?,
      deliveredAt: json['deliveredAt'] as String?,
      sector: json['sector'] as String?,
      spaceCount: _toInt(json['spaceCount']) == 0 && json['spaceCount'] == null
          ? null
          : (json['spaceCount'] == null ? null : _toInt(json['spaceCount'])),
      personCount: json['personCount'] == null ? null : _toInt(json['personCount']),
      dayCount: json['dayCount'] == null ? null : _toInt(json['dayCount']),
      notes: json['notes'] as String?,
      site: json['site'] as Map<String, dynamic>?,
      requester: json['requester'] as Map<String, dynamic>?,
      magasinier: json['magasinier'] as Map<String, dynamic>?,
      lines: (json['lines'] as List<dynamic>? ?? [])
          .map((e) => MaterialFicheLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MaterialRepository {
  final ApiClient _api;
  MaterialRepository(this._api);

  Future<List<MaterialItem>> listItems({String? category, bool all = false}) async {
    try {
      final response = await _api.dio.get(
        '/material/items',
        queryParameters: {
          if (category != null) 'category': category,
          if (all) 'all': 'true',
        },
      );
      return (response.data as List<dynamic>)
          .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> seedCatalog() async {
    try {
      await _api.dio.post('/material/items/seed');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<MaterialItem> createItem(Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.post('/material/items', data: data);
      return MaterialItem.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<MaterialItem> updateItem(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.patch('/material/items/$id', data: data);
      return MaterialItem.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<MaterialFiche>> listFiches({String? siteId, String? status}) async {
    try {
      final res = await _api.dio.get('/material/fiches', queryParameters: {
        if (siteId != null) 'siteId': siteId,
        if (status != null) 'status': status,
      });
      return (res.data as List<dynamic>)
          .map((e) => MaterialFiche.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<MaterialFiche> getFiche(String id) async {
    try {
      final res = await _api.dio.get('/material/fiches/$id');
      return MaterialFiche.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<MaterialFiche> createFiche(Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.post('/material/fiches', data: data);
      return MaterialFiche.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<MaterialFiche> updateFiche(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.patch('/material/fiches/$id', data: data);
      return MaterialFiche.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<MaterialFiche> deliverFiche(String id) async {
    try {
      final res = await _api.dio.post('/material/fiches/$id/deliver');
      return MaterialFiche.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<MaterialFiche> checkReturn(String id, List<Map<String, dynamic>> lines) async {
    try {
      final res = await _api.dio.post('/material/fiches/$id/return', data: {'lines': lines});
      return MaterialFiche.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<MaterialFiche> closeFiche(String id) async {
    try {
      final res = await _api.dio.post('/material/fiches/$id/close');
      return MaterialFiche.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<Map<String, dynamic>>> listDamages() async {
    try {
      final res = await _api.dio.get('/material/damages');
      return (res.data as List<dynamic>).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> applySanction({
    required String lineId,
    required String target,
    required double amount,
    String? agentId,
    String? reason,
  }) async {
    try {
      await _api.dio.post('/material/sanctions', data: {
        'lineId': lineId,
        'target': target,
        'amount': amount,
        if (agentId != null) 'agentId': agentId,
        if (reason != null) 'reason': reason,
      });
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<Map<String, dynamic>> materialOut({
    required String siteId,
    required String itemId,
    required int quantity,
    String? notes,
  }) async {
    try {
      final response = await _api.dio.post('/material/out', data: {
        'siteId': siteId,
        'itemId': itemId,
        'quantity': quantity,
        if (notes != null) 'notes': notes,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<Map<String, dynamic>> materialReturn({
    required String siteId,
    required String itemId,
    required int quantity,
    required String state,
    String? retentionTarget,
    String? agentId,
    String? notes,
  }) async {
    try {
      final response = await _api.dio.post('/material/return', data: {
        'siteId': siteId,
        'itemId': itemId,
        'quantity': quantity,
        'state': state,
        if (retentionTarget != null) 'retentionTarget': retentionTarget,
        if (agentId != null) 'agentId': agentId,
        if (notes != null) 'notes': notes,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
