import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class DioClient {
  static final DioClient instance = DioClient._init();
  static Dio? _dio;

  DioClient._init();

  Dio get dio {
    if (_dio != null) return _dio!;

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiService.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Dynamic Authorization Header Interceptor
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await ApiService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            print('🌐 [Dio Scanner Request] ${options.method} ${options.uri}');
            if (options.data != null) {
              print('📦 Body: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print(
                '📥 [Dio Scanner Response] ${response.statusCode} | ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            print(
                '❌ [Dio Scanner Error] ${e.type} | ${e.message} | Path: ${e.requestOptions.path}');
            if (e.response != null) {
              print('📥 Error Response Data: ${e.response?.data}');
            }
          }
          return handler.next(e);
        },
      ),
    );

    return _dio!;
  }
}
