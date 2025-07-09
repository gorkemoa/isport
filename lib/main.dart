import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/applications_viewmodel.dart';
import 'viewmodels/auth_viewmodels.dart';
import 'viewmodels/job_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'views/login_screen.dart';
import 'views/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProxyProvider<AuthViewModel, JobViewModel>(
          create: (context) => JobViewModel(context.read<AuthViewModel>()),
          update: (context, auth, previous) => JobViewModel(auth),
        ),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => ApplicationsViewModel()),
      ],
      child: MaterialApp(
        title: 'iSport',
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasData && snapshot.data == true) {
              return const MainScreen();
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}
