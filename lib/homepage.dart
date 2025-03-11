import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitter_api_v2/twitter_api_v2.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clipboard/clipboard.dart';
// A n'utiliser qu'en cas de debogage ou de tests qui ne fonctionnent pas
// import 'package:http/http.dart' as http;
import './loggedout.dart';

/*
This is the code for the home page screen.
Made by Thomas VASSY--ROUSSEAU.
*/

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Texte de test pour le developpement
  String displayedText = "Bienvenue dans IA StoryTeller !";

  // Bouton de deconnexion de Twitter
  Future<void> _signOut() async {
    // Instruction recuperes a partir de la documentation officielle de Supabase
    try {
      final supabase = Supabase.instance.client; // Simplification du code via une variable

      await supabase.auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoggedOutPage(),
        ),
      );

    } catch (e) {
      // On recupere et affiche les eventuelles erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
        ),
      );
    }
  }

  // Publier un Tweet a partir de la reponse de l'IA
  Future<void> _postTweet() async {
    // Recuperation des cles API de Twitter dans .env
    final apiKey = dotenv.env['KEY_TWITTER'];
    final apiSecret = dotenv.env['SECRET_TWITTER'];

    if (apiKey == null || apiSecret == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : cles API de Twitter introuvables dans .env"),
        ),
      );
      return; // Arreter l'application immediatement si il n'y a pas de cles API.
    }

    try {
      final twitterApi = TwitterApi(bearerToken: apiKey.toString()); // Utilisation du token necessaire a la publication d'un Tweet
      await twitterApi.tweetsService.createTweet(text: displayedText); // Publication du Tweet a partir des donnees affichees sur l'ecran

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tweet publié avec succès ! Regardez dans votre fil Twitter pour le voir."),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
        ),
      );
    }
  }

  // Fonction pour copier le texte dans le presse-papiers
  void _copyToClipboard() {
    FlutterClipboard.copy(displayedText).then((value) { // On copie les donnees affichees sur l'ecran
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Le texte a bien été copié dans votre presse-papiers."),
        ),
      );
    });
  }

  // Partie affichage de la page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Accueil"),
      ),
      body: Center(
        child: Text(displayedText),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Se déconnecter de Twitter",
              onPressed: _signOut,
            ),
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: "Publier automatiquement votre histoire actuelle dans un Tweet",
              onPressed: _postTweet,
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: "Copier votre histoire dans votre presse-papiers pour la partager",
              onPressed: _copyToClipboard,
            ),
          ],
        ),
      ),
    );
  }
}
