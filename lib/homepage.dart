import 'package:flutter/material.dart';

/*
This is the code for the home page screen.
 */

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Accueil"),
      ),
      body: Center(
        child: Text("Bienvennue dans IA StoryTeller !"),
      ),
    );
  }
}
