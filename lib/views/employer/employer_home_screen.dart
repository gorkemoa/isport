import 'package:flutter/material.dart';
import 'package:isport/views/login_screen.dart';

class EmployerHomeScreen extends StatelessWidget {
  const EmployerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Employer Home',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
        bottomNavigationBar: SizedBox(
        height: 50,
        child:  ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) =>  LoginScreen()));
          },
          child:  Text('Logout'),
        ),
      ),
    );
  }
} 