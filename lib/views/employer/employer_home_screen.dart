import 'package:flutter/material.dart';
import 'employer_main_router.dart';

/// Modern Employer Ana Sayfa
/// LinkedIn ve Kariyer.net tarzında kurumsal tasarım
class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const EmployerMainRouter();
  }
} 