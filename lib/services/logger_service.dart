import 'package:logger/logger.dart';

/// Uygulama genelinde kullanılacak logger servisi.
///
/// Kullanım:
/// - logger.d('Debug mesajı');
/// - logger.i('Info mesajı');
/// - logger.w('Warning mesajı');
/// - logger.e('Error mesajı', error: hata, stackTrace: stackTrace);
/// - logger.v('Verbose mesajı');
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 1, // Çağrıldığı metodun adını gösterir
    errorMethodCount: 5, // Hata durumunda gösterilecek stack trace satır sayısı
    lineLength: 80, // Çıktı genişliği
    colors: true, // Renkli çıktı
    printEmojis: true, // Emoji ile log seviyesini belirtir
    printTime: true, // Log zamanını gösterir
  ),
  level: Level.debug, // Sadece debug ve üzeri seviyedeki logları gösterir
); 