import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'MyHomePage.dart';
import 'affichepage.dart';
import 'BibliothequeDetailPage.dart';
import 'classe.dart'; 

// VOS CLÉS SUPABASE (À REMPLACER)
const String SUPABASE_URL = 'https://liugxtedmyhdwqrewpbc.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpdWd4dGVkbXloZHdxcmV3cGJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxOTQyNjIsImV4cCI6MjA3OTc3MDI2Mn0.Cfw3I7Ou2F7uMoWYMZfrVY0m24j2aNTWFwF4-TaZ0_U';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  
  
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cypher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, 
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        ),
      ),
      home: const MyHomePage(title: 'Cypher'),
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        '/affiche': (BuildContext context) =>
            const AffichePage(title: 'Détail Collection'),
        
        '/bibliothequeDetail': (BuildContext context) =>
            BibliothequeDetailPage(bibliotheque: ModalRoute.of(context)!.settings.arguments as Bibliotheque),
        '/login': (BuildContext context) =>
            const MyHomePage(title: 'Mes Bibliothèques Musicales'),
      },
    );
  }
}