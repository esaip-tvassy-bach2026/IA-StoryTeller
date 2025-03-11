import 'package:flutter/material.dart';

/*
This is the code for the log out screen.
Realise par Thomas VASSY--ROUSSEAU.
*/

class LoggedOutPage extends StatelessWidget {
  const LoggedOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Déconnexion"),
      ),
      body: Center(
        child: Text("Vous vous êtes correctement déconnecté. Vous pouvez fermer cette application."),
      ),
    );
  }
}
