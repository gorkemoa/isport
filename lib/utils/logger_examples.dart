import '../services/logger_service.dart';

/// Logger Service Kullanım Örnekleri
/// 
/// Bu dosya logger service'in nasıl kullanılacağını gösterir.
/// Production kodunda bu dosyayı kullanmayın - sadece referans amaçlıdır.
class LoggerExamples {
  /// Temel logging örnekleri
  static void basicLoggingExamples() {
    // Debug seviyesi - sadece development'ta görünür
    logger.debug('Bu bir debug mesajıdır');
    
    // Info seviyesi - genel bilgilendirme
    logger.info('Kullanıcı giriş ekranına geldi');
    
    // Warning seviyesi - dikkat edilmesi gereken durumlar
    logger.warning('API yanıt süresi normalden yavaş');
    
    // Error seviyesi - hatalar
    logger.error('Veritabanı bağlantısı başarısız');
    
    // Fatal seviyesi - kritik hatalar
    logger.fatal('Uygulama çöktü');
  }

  /// Extra parametreler ile logging
  static void loggingWithExtras() {
    // Debug mesajı extra bilgilerle
    logger.debug('Kullanıcı verisi yüklendi', extra: {
      'userID': '12345',
      'loadTime': '250ms',
      'cacheHit': true,
    });

    // Error mesajı exception ve stack trace ile
    try {
      throw Exception('Test hatası');
    } catch (e, stackTrace) {
      logger.error(
        'İşlem sırasında hata oluştu',
        error: e,
        stackTrace: stackTrace,
        extra: {
          'operation': 'user_data_load',
          'userID': '12345',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// Network request logging örnekleri
  static void networkLoggingExamples() {
    // Başarılı API çağrısı
    logger.logNetworkRequest(
      method: 'GET',
      url: 'https://api.example.com/users/123',
      statusCode: 200,
      duration: const Duration(milliseconds: 350),
    );

    // Başarısız API çağrısı
    logger.logNetworkRequest(
      method: 'POST',
      url: 'https://api.example.com/users',
      statusCode: 400,
      duration: const Duration(milliseconds: 150),
    );

    // Yavaş API çağrısı
    logger.logNetworkRequest(
      method: 'GET',
      url: 'https://api.example.com/large-data',
      statusCode: 200,
      duration: const Duration(seconds: 3),
    );
  }

  /// Kullanıcı action logging örnekleri
  static void userActionExamples() {
    // Basit kullanıcı aksiyonu
    logger.logUserAction('button_click');

    // Parametreli kullanıcı aksiyonu
    logger.logUserAction('login_attempt', parameters: {
      'method': 'email',
      'remember_me': true,
    });

    // Ekran değişimi
    logger.logUserAction('screen_view', parameters: {
      'screen_name': 'profile_screen',
      'previous_screen': 'home_screen',
    });

    // Özellik kullanımı
    logger.logUserAction('feature_used', parameters: {
      'feature': 'dark_mode',
      'enabled': true,
    });
  }

  /// Performance logging örnekleri
  static void performanceExamples() {
    final stopwatch = Stopwatch()..start();
    
    // Simüle edilmiş işlem
    simulateOperation();
    
    stopwatch.stop();
    
    // Performance ölçümü
    logger.logPerformance(
      'user_data_processing',
      stopwatch.elapsed,
      extra: {
        'records_processed': 1000,
        'cache_enabled': true,
      },
    );

    // Yavaş işlem
    logger.logPerformance(
      'slow_database_query',
      const Duration(seconds: 2),
      extra: {
        'query': 'SELECT * FROM users WHERE status = active',
        'result_count': 50000,
      },
    );
  }

  /// App lifecycle logging örnekleri
  static void lifecycleExamples() {
    logger.logAppLifecycle('App Started');
    logger.logAppLifecycle('App Paused');
    logger.logAppLifecycle('App Resumed');
    logger.logAppLifecycle('App Terminated');
  }

  /// Crash logging örnekleri
  static void crashLoggingExamples() {
    try {
      throw Exception('Kritik sistem hatası');
    } catch (error, stackTrace) {
      logger.logCrash(
        error,
        stackTrace,
        context: 'User profile loading',
      );
    }

    // Null pointer exception
    try {
      String? nullString;
      nullString!.length; // Bu bir crash'e sebep olur
    } catch (error, stackTrace) {
      logger.logCrash(
        error,
        stackTrace,
        context: 'String operation on null value',
      );
    }
  }

  /// Widget lifecycle logging örnekleri
  static void widgetLifecycleExamples() {
    logger.debug('Widget oluşturuldu', extra: {
      'widget': 'UserProfileWidget',
      'timestamp': DateTime.now().toIso8601String(),
    });

    logger.debug('Widget dispose edildi', extra: {
      'widget': 'UserProfileWidget',
      'lifecycle_duration': '45000ms',
    });
  }

  /// State management logging örnekleri
  static void stateManagementExamples() {
    // State değişimi
    logger.debug('State değişti', extra: {
      'from': 'loading',
      'to': 'loaded',
      'trigger': 'api_response',
    });

    // Provider state
    logger.debug('Provider güncellendi', extra: {
      'provider': 'AuthProvider',
      'property': 'isLoggedIn',
      'value': true,
    });
  }

  /// Development vs Production logging örnekleri
  static void environmentSpecificExamples() {
    // Development ortamında detaylı bilgi
    logger.debug('API Response detayı', extra: {
      'full_response': '{"user": {"id": 123, "name": "John"}}',
      'headers': {'content-type': 'application/json'},
      'cookies': ['session_id=abc123'],
    });

    // Production ortamında minimal bilgi
    logger.info('API işlemi tamamlandı', extra: {
      'operation': 'user_fetch',
      'success': true,
      'duration': '250ms',
    });

    // Sensitive data masking
    logger.info('Kullanıcı girişi', extra: {
      'email': 'user***@example.com', // Email maskelenmiş
      'ip_address': '192.168.***.*', // IP maskelenmiş
      'success': true,
    });
  }

  /// Helper method - gerçek projede bu tür metodlar olacak
  static void simulateOperation() {
    // Simülasyon için kısa bekleme
    // Gerçek projede bu bir veritabanı sorgusu, API çağrısı vb. olacak
  }
} 