import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/session_store.dart';
import 'network_info.dart';

class ApiClient {
  ApiClient({
    required TokenManager tokens,
    required NetworkInfo networkInfo,
    Dio? dio,
  }) : _tokens = tokens,
       _networkInfo = networkInfo,
       _dio = dio ??
           Dio(
             BaseOptions(
               baseUrl: ApiEndpoints.baseUrl,
               connectTimeout: AppConstants.connectTimeout,
               receiveTimeout: AppConstants.receiveTimeout,
               sendTimeout: AppConstants.sendTimeout,
               headers: const {'Accept': 'application/json'},
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!await _networkInfo.isConnected) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message: 'No internet connection right now.',
              ),
            );
          }
          final token = await _tokens.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Idempotency-Key'] ??=
              options.headers['X-Client-Transaction-Id'];
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _tokens.clear();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenManager _tokens;
  final NetworkInfo _networkInfo;

  Dio get raw => _dio;
}
