import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitter_api_v2/twitter_api_v2.dart';
import 'package:clipboard/clipboard.dart';
import './loggedout.dart';

// Ceci est le code de Nolan.

// 1️⃣ Écran de sélection du type d’histoire
class StoryTypeSelectionScreen extends StatefulWidget {
  @override
  _StoryTypeSelectionScreenState createState() =>
      _StoryTypeSelectionScreenState();
}

class _StoryTypeSelectionScreenState extends State<StoryTypeSelectionScreen> {
  String selectedGenre = 'Horreur';
  List<String> genres = ['Horreur', 'Enfant', 'Drôle', 'Réaliste'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choisir le genre')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Sélectionnez un genre :', style: TextStyle(fontSize: 18)),
          DropdownButton<String>(
            value: selectedGenre,
            onChanged: (String? newValue) {
              setState(() {
                selectedGenre = newValue!;
              });
            },
            items: genres.map<DropdownMenuItem<String>>((String genre) {
              return DropdownMenuItem<String>(
                value: genre,
                child: Text(genre),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StoryInputScreen(selectedGenre: selectedGenre),
                ),
              );
            },
            child: Text('Continuer'),
          ),
        ],
      ),
    );
  }
}

// 2️⃣ Écran de saisie du début de l’histoire
class StoryInputScreen extends StatefulWidget {
  final String selectedGenre;
  StoryInputScreen({required this.selectedGenre});

  @override
  _StoryInputScreenState createState() => _StoryInputScreenState();
}

class _StoryInputScreenState extends State<StoryInputScreen> {
  TextEditingController _textController = TextEditingController();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Erreur: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Commence ton histoire')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Début de l’histoire'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? 'Arrêter' : 'Micro 🎙️'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryGenerationScreen(
                      genre: widget.selectedGenre,
                      startText: _textController.text,
                    ),
                  ),
                );
              },
              child: Text('Générer l’histoire'),
            ),
          ],
        ),
      ),
    );
  }
}

// 3️⃣ Écran de génération et d'affichage de l’histoire
class StoryGenerationScreen extends StatefulWidget {
  final String genre;
  final String startText;

  StoryGenerationScreen({required this.genre, required this.startText});

  @override
  _StoryGenerationScreenState createState() => _StoryGenerationScreenState();
}

class _StoryGenerationScreenState extends State<StoryGenerationScreen> {
  String story = 'Génération en cours...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      generateStory();
    });
  }

  Future<void> generateStory() async {
    await dotenv.load();
    final String mistralApiKey = dotenv.env['KEY_MISTRAL']!;
    const String mistralEndpoint = 'https://api.mistral.ai/v1/completions';

    final response = await http.post(
      Uri.parse(mistralEndpoint),
      headers: {
        'Authorization': 'Bearer $mistralApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "mistral-7B",
        "prompt":
        "Écris une histoire de type ${widget
            .genre} qui commence ainsi : ${widget.startText}",
        "max_tokens": 200,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        story = data['choices'][0]['text'];
      });
    } else {
      setState(() {
        story = "Erreur lors de la génération de l’histoire.";
      });
    }
  }

  /*
  A partir d'ici se trouve le code realise par Thomas VASSY--ROUSSEAU.
  */

  // Bouton de deconnexion de Twitter
  Future<void> _signOut() async {
    // Instruction recuperes a partir de la documentation officielle de Supabase
    try {
      final supabase = Supabase.instance
          .client; // Simplification du code via une variable

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
    await dotenv.load();
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
      await twitterApi.tweetsService.createTweet(text: story); // Publication du Tweet a partir des donnees affichees sur l'ecran

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Tweet publié avec succès ! Regardez dans votre fil Twitter pour le voir."),
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
    FlutterClipboard.copy(story).then((
        value) { // On copie les donnees affichees sur l'ecran
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
        title: Text("Histoire générée"),
      ),

      // Le body a ete code par Nolan.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(story, style: TextStyle(fontSize: 18)),
        ),
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
  // Fin du code realise par Thomas VASSY--ROUSSEAU.
}
