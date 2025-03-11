import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart'; // Permet de gerer les liens profonds et les redirections au sein de l'application
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Package pour lancer le WebView
import './homepage.dart';

/*
This is the code for the login page screen.
Made by Thomas VASSY--ROUSSEAU.
*/

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Mise en place des liens profonds
  late AppLinks _appLinks;
  // Uniquement pour le developpement
  String ? _deppLink;

  @override
  void initState() {
    super.initState();
    // J'utilise WidgetsBinding ici pour corriger un bug (suggestion de code copie-colle a partir d'Internet).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeppLinkListener(); // J'intialise ici l'ecoute des liens profonds (code redige par moi-meme).
    });

    // Veririfcation de la connexion de l'utilisateur
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Uniquement pour le developpement
      print("Utilisateur deja connecte avec l'e-mail : ${session.user.email}");
      // Meme chose que ligne 28.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      });
    }
  }

  // Initialisation de la gestion des liens profonds
  void _initializeDeppLinkListener() async {
    _appLinks = AppLinks();

    // Ecoute des liens lors de l'ouverture de l'application
    final Uri? initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeppLink(initialUri);
    }

    // Ecoute des liens lors pendant l'execution de l'application
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeppLink(uri);
      }
    });
  }

  // Gestion des liens profonds reçus
  void _handleDeppLink(Uri uri) {

    // Utiliser uniquement en conditions de developpement
    setState(() {
      _deppLink = uri.toString();
      print('Le lien profond qui a ete recu est : $_deppLink');
    });

    // Verification pour savoir si le lien reçu est bien celui qui correspond a notre application
    if (uri.scheme == 'io.supabase.flutterapp' &&
        uri.host == 'login-callback') {
      // Meme chose que ligne 28.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Navigation vers l'ecran principal de l'application
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      });
    }
  }

  Future<void> signInWithTwitter() async {
    // La future pour la connexion a Twitter.
    // Code recupere a partir des instructions de la documentation officielle Supabase.
    final supabase = Supabase.instance.client;

    // On teste et recupere les erreurs
    try {
      // final response = await supabase.auth.signInWithOAuth(
      await supabase.auth.signInWithOAuth(
        OAuthProvider.twitter,
        redirectTo: kIsWeb ? null : 'io.supabase.flutterapp://login-callback', // Redirection vers lien profond
        authScreenLaunchMode:
        kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication, // Lancement du WebView pour la connexion à Twitter
      );

      // Tests de developpement (ne fonctionne pas, mais conserve au cas ou si besoin)
      /*
      if (response.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : La connexion a échoué'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connexion reussie.'),
          ),
        );
      }
      */

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
        ),
      );
    }
  }

  // Partie affichage de la page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connectez-vous a Twitter"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await signInWithTwitter();
          },
          child: Text("Cliquez pour lancer la connexion"),
        ),
      ),
    );
  }
}
