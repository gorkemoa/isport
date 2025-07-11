import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Uygulama ortamları
enum AppEnvironment {
  development,
  staging,
  production,
}

/// Gelişmiş logger servisi
/// 
/// Özellikler:
/// - Environment-based log seviyeleri
/// - Dosyaya yazma özelliği
/// - Structured logging
/// - Network request logging
/// - Crash reporting
class LoggerService {
  static LoggerService? _instance;
  static LoggerService get instance => _instance ??= LoggerService._internal();
  
  late final Logger _logger;
  late final AppEnvironment _environment;
  File? _logFile;
  
  LoggerService._internal();
  
  /// Logger'ı başlatır
  Future<void> initialize({
    AppEnvironment environment = AppEnvironment.development,
    bool enableFileLogging = true,
  }) async {
    _environment = environment;
    
    // Dosya yazma özelliği için log dosyası oluştur
    if (enableFileLogging && !kIsWeb) {
      await _initializeFileLogging();
    }
    
    _logger = Logger(
      printer: _getPrinterForEnvironment(),
      output: _getOutputForEnvironment(enableFileLogging),
      level: _getLevelForEnvironment(),
    );
    
    // Başlatma logunu yaz
    _logger.i('🚀 Logger başlatıldı - Ortam: ${environment.name}');
  }
  
  /// Environment'a göre log seviyesini belirler
  Level _getLevelForEnvironment() {
    switch (_environment) {
      case AppEnvironment.development:
        return Level.debug;
      case AppEnvironment.staging:
        return Level.info;
      case AppEnvironment.production:
        return Level.warning;
    }
  }
  
  /// Environment'a göre printer'ı belirler
  LogPrinter _getPrinterForEnvironment() {
    switch (_environment) {
      case AppEnvironment.development:
        return PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 80,
          colors: true,
          printEmojis: true,
          printTime: true,
          excludeBox: const {},
        );
      case AppEnvironment.staging:
      case AppEnvironment.production:
        return SimplePrinter(colors: false, printTime: true);
    }
  }
  
  /// Environment'a göre output'u belirler
  LogOutput _getOutputForEnvironment(bool enableFileLogging) {
    final outputs = <LogOutput>[ConsoleOutput()];
    
    if (enableFileLogging && _logFile != null) {
      outputs.add(FileOutput(file: _logFile!));
    }
    
    return MultiOutput(outputs);
  }
  
  /// Dosya logging'i başlatır
  Future<void> _initializeFileLogging() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final now = DateTime.now();
      final fileName = 'isport_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.log';
      _logFile = File('${logDir.path}/$fileName');
      
      // Eski log dosyalarını temizle (7 günden eski)
      await _cleanOldLogFiles(logDir);
    } catch (e) {
      // Dosya oluşturulamadıysa sessizce devam et
      debugPrint('Log dosyası oluşturulamadı: $e');
    }
  }
  
  /// 7 günden eski log dosyalarını siler
  Future<void> _cleanOldLogFiles(Directory logDir) async {
    try {
      final files = await logDir.list().toList();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.log')) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Eski log dosyaları temizlenirken hata: $e');
    }
  }
  
  // Debug level logging
  void debug(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    _logWithExtra(Level.debug, message, error: error, stackTrace: stackTrace, extra: extra);
  }
  
  // Info level logging
  void info(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    _logWithExtra(Level.info, message, error: error, stackTrace: stackTrace, extra: extra);
  }
  
  // Warning level logging
  void warning(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    _logWithExtra(Level.warning, message, error: error, stackTrace: stackTrace, extra: extra);
  }
  
  // Error level logging
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    _logWithExtra(Level.error, message, error: error, stackTrace: stackTrace, extra: extra);
  }
  
  // Fatal level logging
  void fatal(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    _logWithExtra(Level.fatal, message, error: error, stackTrace: stackTrace, extra: extra);
  }
  
  /// Extra data ile log yapar
  void _logWithExtra(Level level, String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    String finalMessage = message;
    
    if (extra != null && extra.isNotEmpty) {
      final extraString = extra.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      finalMessage = '$message [$extraString]';
    }
    
    _logger.log(level, finalMessage, error: error, stackTrace: stackTrace);
  }
  
  /// Network request'leri loglar
  void logNetworkRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Object? body,
    int? statusCode,
    String? response,
    Duration? duration,
  }) {
    final extra = <String, dynamic>{
      'method': method,
      'url': url,
      if (statusCode != null) 'statusCode': statusCode,
      if (duration != null) 'duration': '${duration.inMilliseconds}ms',
    };
    
    if (statusCode != null && statusCode >= 400) {
      error('Network Error', extra: extra);
    } else {
      info('Network Request', extra: extra);
    }
  }
  
  /// User action'ları loglar
  void logUserAction(String action, {Map<String, dynamic>? parameters}) {
    info('User Action: $action', extra: parameters);
  }
  
  /// Performance metriklerini loglar
  void logPerformance(String operation, Duration duration, {Map<String, dynamic>? extra}) {
    final performanceData = <String, dynamic>{
      'operation': operation,
      'duration': '${duration.inMilliseconds}ms',
      ...?extra,
    };
    
    if (duration.inMilliseconds > 1000) {
      warning('Slow Operation', extra: performanceData);
    } else {
      debug('Performance', extra: performanceData);
    }
  }
  
  /// App lifecycle events'leri loglar
  void logAppLifecycle(String event) {
    info('App Lifecycle: $event');
  }
  
  /// Crash'leri loglar
  void logCrash(Object error, StackTrace stackTrace, {String? context}) {
    final extra = <String, dynamic>{
      if (context != null) 'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    fatal('App Crash', error: error, stackTrace: stackTrace, extra: extra);
  }
}

/// Global logger instance'ı
final logger = LoggerService.instance;

/// Custom file output class
class FileOutput extends LogOutput {
  final File file;
  
  FileOutput({required this.file});
  
  @override
  void output(OutputEvent event) {
    try {
      final logLine = event.lines.join('\n');
      file.writeAsStringSync('$logLine\n', mode: FileMode.append);
    } catch (e) {
      // Dosya yazma hatası durumunda sessizce devam et
      debugPrint('Log dosyasına yazarken hata: $e');
    }
  }
} 