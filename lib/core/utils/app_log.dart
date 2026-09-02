import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class LogEntry {
  LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    required this.at,
    this.error,
    this.stack,
  });

  final String level;
  final String tag;
  final String message;
  final DateTime at;
  final Object? error;
  final StackTrace? stack;

  String get title => '[$level] [$tag] $message';

  String get detail {
    final buf = StringBuffer(title);
    buf.writeln();
    buf.writeln(at.toIso8601String());
    if (error != null) {
      buf.writeln();
      buf.writeln(error);
    }
    if (stack != null) {
      buf.writeln();
      buf.writeln(stack);
    }
    return buf.toString();
  }
}

class AppLog {
  static const _max = 80;
  static final entries = <LogEntry>[].obs;

  static void info(String message, {String tag = 'RPD'}) {
    _write(level: 'INFO', tag: tag, message: message);
  }

  static void warn(String message, {Object? error, String tag = 'RPD'}) {
    _write(level: 'WARN', tag: tag, message: message, error: error);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stack,
    String tag = 'RPD',
  }) {
    _write(level: 'ERROR', tag: tag, message: message, error: error, stack: stack);
  }

  static void clear() => entries.clear();

  static void _write({
    required String level,
    required String tag,
    required String message,
    Object? error,
    StackTrace? stack,
  }) {
    final entry = LogEntry(
      level: level,
      tag: tag,
      message: message,
      at: DateTime.now(),
      error: error,
      stack: stack,
    );
    entries.insert(0, entry);
    if (entries.length > _max) {
      entries.removeRange(_max, entries.length);
    }

    final line = '[${entry.at.toIso8601String()}] [$level] [$tag] $message';
    debugPrint(line);
    if (error != null) debugPrint('  error: $error');
    if (stack != null) debugPrint('$stack');

    developer.log(
      message,
      name: 'RPD.$tag',
      level: switch (level) {
        'ERROR' => 1000,
        'WARN' => 900,
        _ => 800,
      },
      error: error,
      stackTrace: stack,
    );
  }
}
