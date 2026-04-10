import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:stamp_camera/src/api/stampverse_api.dart';
import 'package:stamp_camera/src/core/model/request/auth_login_request.dart';
import 'package:stamp_camera/src/core/model/request/auth_register_request.dart';
import 'package:stamp_camera/src/core/model/request/stamp_upload_request.dart';
import 'package:stamp_camera/src/core/model/response/auth_response.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/result/app_result.dart';
import 'package:stamp_camera/src/core/result/failure.dart';

class StampverseRepository {
  StampverseRepository({
    required StampverseApi api,
    required SharedPreferences preferences,
  }) : _api = api,
       _preferences = preferences;

  static const String _tokenKey = 'stampverse_token';
  static const String _cacheKey = 'stampverse_stamps';
  static const String _collectionCacheKey = 'stampverse_collections';
  static const String _editBoardsCacheKey = 'stampverse_edit_boards';

  final StampverseApi _api;
  final SharedPreferences _preferences;

  String? get token => _preferences.getString(_tokenKey);

  Future<AppResult<AuthResponse>> login(AuthLoginRequest request) async {
    try {
      final AuthResponse response = await _api.login(request);
      if (response.token.isEmpty) {
        return const AppFailure<AuthResponse>(
          Failure(message: 'Token is missing from server response'),
        );
      }
      await _preferences.setString(_tokenKey, response.token);
      return AppSuccess<AuthResponse>(response);
    } catch (error) {
      return AppFailure<AuthResponse>(_mapFailure(error));
    }
  }

  Future<AppResult<void>> register(AuthRegisterRequest request) async {
    try {
      await _api.register(request);
      return const AppSuccess<void>(null);
    } catch (error) {
      return AppFailure<void>(_mapFailure(error));
    }
  }

  Future<AppResult<List<StampDataModel>>> fetchStamps() async {
    final String? currentToken = token;
    if (currentToken == null || currentToken.isEmpty) {
      return const AppFailure<List<StampDataModel>>(
        Failure(message: 'Authentication required'),
      );
    }

    try {
      final List<StampDataModel> stamps = (await _api.listStamps(
        token: currentToken,
      )).data;
      await saveCache(stamps);
      return AppSuccess<List<StampDataModel>>(stamps);
    } catch (error) {
      return AppFailure<List<StampDataModel>>(_mapFailure(error));
    }
  }

  Future<AppResult<List<StampDataModel>>> uploadStamp(
    StampUploadRequest request,
  ) async {
    final String? currentToken = token;
    if (currentToken == null || currentToken.isEmpty) {
      return const AppFailure<List<StampDataModel>>(
        Failure(message: 'Authentication required'),
      );
    }

    try {
      await _api.uploadStamp(token: currentToken, request: request);
      return fetchStamps();
    } catch (error) {
      return AppFailure<List<StampDataModel>>(_mapFailure(error));
    }
  }

  Future<AppResult<List<StampDataModel>>> deleteStamp(String id) async {
    final String? currentToken = token;
    if (currentToken == null || currentToken.isEmpty) {
      return const AppFailure<List<StampDataModel>>(
        Failure(message: 'Authentication required'),
      );
    }

    try {
      await _api.deleteStamp(token: currentToken, id: id);
      return fetchStamps();
    } catch (error) {
      return AppFailure<List<StampDataModel>>(_mapFailure(error));
    }
  }

  Future<List<StampDataModel>> readCache() async {
    final String? cache = _preferences.getString(_cacheKey);
    if (cache == null || cache.isEmpty) {
      return <StampDataModel>[];
    }

    try {
      final dynamic rawList = jsonDecode(cache);
      if (rawList is! List<dynamic>) {
        return <StampDataModel>[];
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(StampDataModel.fromJson)
          .toList(growable: false);
    } catch (_) {
      return <StampDataModel>[];
    }
  }

  Future<void> saveCache(List<StampDataModel> stamps) async {
    final String json = jsonEncode(
      stamps
          .map((StampDataModel item) => item.toJson())
          .toList(growable: false),
    );
    await _preferences.setString(_cacheKey, json);
  }

  Future<List<String>> readCollectionsCache() async {
    final String? cache = _preferences.getString(_collectionCacheKey);
    if (cache == null || cache.isEmpty) {
      return <String>[];
    }

    try {
      final dynamic rawList = jsonDecode(cache);
      if (rawList is! List<dynamic>) {
        return <String>[];
      }

      return rawList
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> saveCollectionsCache(List<String> collections) async {
    final List<String> normalized =
        collections
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(_compareCollectionName);

    final String raw = jsonEncode(normalized);
    await _preferences.setString(_collectionCacheKey, raw);
  }

  Future<List<StampEditBoard>> readEditBoardsCache() async {
    final String? cache = _preferences.getString(_editBoardsCacheKey);
    if (cache == null || cache.isEmpty) {
      return <StampEditBoard>[];
    }

    try {
      final dynamic rawList = jsonDecode(cache);
      if (rawList is! List<dynamic>) {
        return <StampEditBoard>[];
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(StampEditBoard.fromJson)
          .toList(growable: false);
    } catch (_) {
      return <StampEditBoard>[];
    }
  }

  Future<void> saveEditBoardsCache(List<StampEditBoard> boards) async {
    final String json = jsonEncode(
      boards
          .map((StampEditBoard board) => board.toJson())
          .toList(growable: false),
    );
    await _preferences.setString(_editBoardsCacheKey, json);
  }

  Future<List<String>> mergeCollectionsWithStamps(
    List<StampDataModel> stamps,
  ) async {
    final List<String> cached = await readCollectionsCache();
    final List<String> albums = stamps
        .map((StampDataModel stamp) => stamp.album?.trim() ?? '')
        .where((String album) => album.isNotEmpty)
        .toList(growable: false);

    final List<String> merged = _mergeCollectionNames(cached, albums);
    await saveCollectionsCache(merged);
    return merged;
  }

  Future<List<String>> addCollection(String collectionName) async {
    final List<String> cached = await readCollectionsCache();
    final List<String> merged = _mergeCollectionNames(cached, <String>[
      collectionName,
    ]);
    await saveCollectionsCache(merged);
    return merged;
  }

  Future<void> clearSession() async {
    await _preferences.remove(_tokenKey);
    await _preferences.remove(_cacheKey);
    await _preferences.remove(_collectionCacheKey);
    await _preferences.remove(_editBoardsCacheKey);
  }

  List<String> _mergeCollectionNames(List<String> base, List<String> incoming) {
    final Set<String> values = <String>{...base, ...incoming}
      ..removeWhere((String item) => item.trim().isEmpty);
    final List<String> merged = values.toList(growable: false)
      ..sort(_compareCollectionName);
    return merged;
  }

  static int _compareCollectionName(String a, String b) {
    final DateTime? dateA = _parseCollectionDate(a);
    final DateTime? dateB = _parseCollectionDate(b);

    if (dateA != null && dateB != null) {
      return dateB.compareTo(dateA);
    }
    if (dateA != null) return -1;
    if (dateB != null) return 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  static DateTime? _parseCollectionDate(String value) {
    final List<String> parts = value.split('/');
    if (parts.length != 3) return null;

    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    if (day <= 0 || month <= 0 || month > 12 || year <= 0) {
      return null;
    }

    return DateTime(year, month, day);
  }

  Failure _mapFailure(Object error) {
    if (error is StampverseApiException) {
      return Failure(message: error.message, statusCode: error.statusCode);
    }

    return Failure(message: error.toString().replaceFirst('Exception: ', ''));
  }
}
