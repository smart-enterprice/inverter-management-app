import 'package:dio/dio.dart';

class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  factory AppException.fromDio(
    DioException e, {
    String fallback = 'Something went wrong',
  }) {
    return AppException(
      _extractMessage(e.response?.data) ?? e.message ?? fallback,
      statusCode: e.response?.statusCode,
      cause: e,
    );
  }

  @override
  String toString() => message;
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final msg = data['message'];
    if (msg is String && msg.isNotEmpty) return msg;
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map<String, dynamic>) {
        final m = first['message'];
        if (m is String && m.isNotEmpty) return m;
      }
    }
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}

Future<T> guardDio<T>(
  Future<T> Function() body, {
  String fallback = 'Something went wrong',
}) async {
  try {
    return await body();
  } on DioException catch (e) {
    throw AppException.fromDio(e, fallback: fallback);
  }
}
