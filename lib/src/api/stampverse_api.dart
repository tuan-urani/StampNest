import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'package:stamp_camera/src/core/model/request/auth_login_request.dart';
import 'package:stamp_camera/src/core/model/request/auth_register_request.dart';
import 'package:stamp_camera/src/core/model/request/stamp_upload_request.dart';
import 'package:stamp_camera/src/core/model/response/auth_response.dart';
import 'package:stamp_camera/src/core/model/response/stamp_action_response.dart';
import 'package:stamp_camera/src/core/model/response/stamp_list_response.dart';

class StampverseApiException implements Exception {
  const StampverseApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;
}

class StampverseApi {
  StampverseApi({required Dio dio, String? baseUrl})
    : _dio = dio,
      _baseUrl = _resolveBaseUrl(baseUrl);

  static const String _fallbackBaseUrl = '';

  final Dio _dio;
  final String _baseUrl;

  Future<AuthResponse> login(AuthLoginRequest request) async {
    final Map<String, dynamic> data = await _requestJson(
      endpoint: '/auth',
      method: 'POST',
      queryParameters: const <String, dynamic>{'action': 'login'},
      body: request.toJson(),
    );
    return AuthResponse.fromJson(data);
  }

  Future<StampActionResponse> register(AuthRegisterRequest request) async {
    final Map<String, dynamic> data = await _requestJson(
      endpoint: '/auth',
      method: 'POST',
      queryParameters: const <String, dynamic>{'action': 'register'},
      body: request.toJson(),
    );
    return StampActionResponse.fromJson(data);
  }

  Future<StampListResponse> listStamps({required String token}) async {
    final Map<String, dynamic> data = await _requestJson(
      endpoint: '/stamps',
      method: 'GET',
      token: token,
    );
    return StampListResponse.fromJson(data);
  }

  Future<StampActionResponse> uploadStamp({
    required String token,
    required StampUploadRequest request,
  }) async {
    final Map<String, dynamic> data = await _requestJson(
      endpoint: '/stamps',
      method: 'POST',
      token: token,
      body: request.toJson(),
    );
    return StampActionResponse.fromJson(data);
  }

  Future<StampActionResponse> deleteStamp({
    required String token,
    required String id,
  }) async {
    final Map<String, dynamic> data = await _requestJson(
      endpoint: '/stamps',
      method: 'GET',
      token: token,
      queryParameters: <String, dynamic>{'action': 'delete', 'id': id},
    );
    return StampActionResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> _requestJson({
    required String endpoint,
    required String method,
    String? token,
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) async {
    final String normalizedMethod = method.toUpperCase();
    final bool isStampUploadRequest =
        endpoint == '/stamps' && normalizedMethod == 'POST';
    final String requestUrl = '$_baseUrl$endpoint';

    if (isStampUploadRequest) {
      developer.log(
        'Upload started -> $requestUrl',
        name: 'StampverseApi.Upload',
      );
    }

    try {
      final Options options = Options(
        method: method,
        responseType: ResponseType.plain,
        headers: <String, dynamic>{
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        validateStatus: (_) => true,
      );

      final Response<String> response = await _dio.request<String>(
        requestUrl,
        queryParameters: queryParameters,
        data: body,
        options: options,
      );

      final String rawResponse = response.data ?? '';
      final String cleanJson = _extractJsonPayload(rawResponse);
      final dynamic decoded = jsonDecode(cleanJson);

      if (decoded is! Map<String, dynamic>) {
        throw StampverseApiException(
          message: 'Invalid API response structure',
          statusCode: response.statusCode,
        );
      }

      final String status = decoded['status']?.toString() ?? 'error';
      final bool isHttpOk =
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
      final String message =
          decoded['message']?.toString() ?? 'API request failed';

      if (!isHttpOk || status == 'error') {
        if (isStampUploadRequest) {
          developer.log(
            'Upload failed <- $requestUrl | http=${response.statusCode} | status=$status | message=$message',
            name: 'StampverseApi.Upload',
            level: 1000,
          );
        }

        throw StampverseApiException(
          message: message,
          statusCode: response.statusCode,
        );
      }

      if (isStampUploadRequest) {
        developer.log(
          'Upload success <- $requestUrl | http=${response.statusCode} | status=$status | message=$message',
          name: 'StampverseApi.Upload',
        );
      }

      return decoded;
    } catch (error, stackTrace) {
      if (isStampUploadRequest) {
        developer.log(
          'Upload exception <- $requestUrl | error=$error',
          name: 'StampverseApi.Upload',
          level: 1000,
          error: error,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  static String _extractJsonPayload(String rawText) {
    final String trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      throw const StampverseApiException(message: 'Empty server response');
    }

    final RegExpMatch? match = RegExp(
      r'(\{[\s\S]*\}|\[[\s\S]*\])',
    ).firstMatch(trimmed);

    if (match == null) {
      throw StampverseApiException(
        message:
            'Invalid server response: ${trimmed.substring(0, trimmed.length.clamp(0, 100))}',
      );
    }

    return match.group(0)!;
  }

  static String _resolveBaseUrl(String? configuredBaseUrl) {
    final String? value = configuredBaseUrl?.trim();
    if (value == null || value.isEmpty || value.contains('example.com')) {
      return _fallbackBaseUrl;
    }
    return value;
  }
}
