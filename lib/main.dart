import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StoryTypeSelectionScreen(),
    );
  }
}

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
    generateStory();
  }

  Future<void> generateStory() async {
    const String mistralApiKey = 'VOTRE_CLE_API';
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
            "Écris une histoire de type ${widget.genre} qui commence ainsi : ${widget.startText}",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Histoire générée')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(story, style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
