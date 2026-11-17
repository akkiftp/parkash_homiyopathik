import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import '../core/storage/local_storage.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? fromData,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (fromData != null && json['data'] != null)
          ? fromData(json['data'])
          : json['data'] as T?,
      errors: json['errors'] is Map ? Map<String, dynamic>.from(json['errors']) : null,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode, Map<String, dynamic>? errors}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamic baseUrl update support
          options.baseUrl = AppConfig.baseUrl;

          final token = await LocalStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          fromData: fromData,
          statusCode: response.statusCode,
        );
      }
      return ApiResponse.error('Invalid response format', statusCode: response.statusCode);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          fromData: fromData,
          statusCode: response.statusCode,
        );
      }
      return ApiResponse.error('Invalid response format', statusCode: response.statusCode);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}');
    }
  }

  ApiResponse<T> _handleDioError<T>(DioException e) {
    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      final map = e.response!.data as Map<String, dynamic>;
      final msg = map['message'] ?? 'Request failed';
      final errors = map['errors'] is Map ? Map<String, dynamic>.from(map['errors']) : null;
      return ApiResponse.error(
        msg.toString(),
        statusCode: e.response?.statusCode,
        errors: errors,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResponse.error('Connection timed out. Please check your internet connection.');
      case DioExceptionType.connectionError:
        return ApiResponse.error(
          'Cannot connect to clinic server. Please verify server is running on ${AppConfig.baseUrl}.',
        );
      case DioExceptionType.badResponse:
        return ApiResponse.error(
          'Server returned error code: ${e.response?.statusCode}',
          statusCode: e.response?.statusCode,
        );
      default:
        return ApiResponse.error('Network error. Please try again.');
    }
  }
}
