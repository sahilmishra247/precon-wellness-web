import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Turns an exception from an API call into a short sentence a person can act on.
/// The raw error still goes to the debug console.
String describeError(Object error) {
  debugPrint('[API Error] $error');
  if (error is! DioException) return 'Something went wrong. Please try again.';

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'The server took too long to respond. Please try again.';
    case DioExceptionType.connectionError:
      return "Can't reach the server. Check your connection and try again.";
    default:
      break;
  }

  final status = error.response?.statusCode;
  final data = error.response?.data;
  final detail = data is Map && data['detail'] is String ? data['detail'] as String : null;

  if (status == 401) return 'Your session has expired. Please sign in again.';
  if (status == 403) return "You don't have permission to make this change.";
  if (status == 404) return "That record couldn't be found. It may have been removed.";
  if (status != null && status >= 500) return 'The server had a problem. Please try again in a moment.';
  if (status != null && status >= 400) {
    return detail ?? "Some details weren't accepted. Please check them and try again.";
  }
  return 'Something went wrong. Please try again.';
}
