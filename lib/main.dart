import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './loginpage.dart';

/*
This is the main file of IA StoryTeller project. It contains the base code and loads the initial functions.
 */

Future<void> main() async {

  // Initialisation of the app before the RunApp function.
  WidgetsFlutterBinding.ensureInitialized();

  // Loading environment variables
  await dotenv.load();

  // Initialisation of Supabase with dotenv variables
  await Supabase.initialize(
    url: dotenv.env['URL_SUPABASE']!,
    anonKey: dotenv.env['KEY_SUPABASE']!,
  );

  runApp(
    MaterialApp(
      title: "IA StoryTeller",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
    ),
  );
}
