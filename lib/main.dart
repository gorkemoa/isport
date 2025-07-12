import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/logger_service.dart';
import 'utils/app_constants.dart';
import 'viewmodels/auth_viewmodels.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/job_viewmodel.dart';
import 'viewmodels/company_viewmodel.dart';
import 'viewmodels/application_viewmodel.dart';
import 'views/login_screen.dart';
import 'views/job_seeker/job_seeker_home_screen.dart';
import 'views/employer/employer_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Logger'ı başlat
  await logger.initialize(
    environment: AppConstants.loggerEnvironment,
    enableFileLogging: AppConstants.enableFileLogging,
  );
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.logCrash(
      details.exception, 
      details.stack ?? StackTrace.current,
      context: 'Flutter Framework Error',
    );
  };
  
  logger.logAppLifecycle('App Started');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => JobViewModel()),
        ChangeNotifierProvider(create: (_) => CompanyViewModel()),
        ChangeNotifierProvider(create: (_) => ApplicationViewModel()),
      ],
      child: MaterialApp(
        title: 'iSport',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        return FutureBuilder<bool>(
          future: authViewModel.isLoggedIn(),
          builder: (context, snapshot) {
          
            return const LoginScreen();
          },
        ); 
      },
    );
  }
}
  
  

