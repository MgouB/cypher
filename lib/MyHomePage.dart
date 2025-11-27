import 'package:flutter/material.dart';
import 'classe.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'BibliothequeDetailPage.dart'; 
import 'supabase_service.dart'; 

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Bibliotheque> bibliotheques = [];
  
  final SupabaseService sbService = SupabaseService(); 
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    loadData(); 
  }
  
  
  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      
      List<Bibliotheque> loadedBibliotheques = await sbService.getBibliotheques();

      if (loadedBibliotheques.isEmpty) {
        
        await recupDataJson();
      } else {
        
        setState(() {
          bibliotheques = loadedBibliotheques;
        });
      }
    } catch (e) {
      print('Erreur de chargement Supabase: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  
  Future<void> recupDataJson() async {
    
    String url = "https://api.deezer.com/playlist/14478423703";
    var reponse = await http.get(Uri.parse(url));
    if (reponse.statusCode == 200) {
      var dataMap = convert.jsonDecode(reponse.body);
      List<Morceau> morceaux = [];

      for (var track in dataMap['tracks']['data']) {
        morceaux.add(Morceau(
          titre: track['title'],
          artiste: track['artist']['name'],
          cover: track['album']['cover_medium'],
          id: track['id'].toString(),
        ));
      }

      Collection nouvelleCollection =
          Collection(nom: "Morceaux Rap FR", morceaux: morceaux);
      
      
      Bibliotheque nouvelleBibliotheque =
          Bibliotheque(nom: "Ma Bibliothèque", collections: [nouvelleCollection]); 

      setState(() {
        bibliotheques.add(nouvelleBibliotheque);
      });
      
      await sbService.saveBibliotheque(nouvelleBibliotheque);
    }
  }

  
  Future<void> ajouterBibliotheque(String nom) async {
    
    final nouvelleBibliotheque = Bibliotheque(nom: nom, collections: []);
    setState(() {
      bibliotheques.add(nouvelleBibliotheque);
    });
    
    await sbService.saveBibliotheque(nouvelleBibliotheque);
  }

  
  Future<void> retirerBibliotheque(Bibliotheque bibliotheque) async {
    setState(() {
      bibliotheques.removeWhere((b) => b.nom == bibliotheque.nom);
    });
    
    await sbService.deleteBibliotheque(bibliotheque.nom);
  }

  void _showAddBibliothequeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nom de la Nouvelle Bibliothèque"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Ex: Ma Collection de Vinyles"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                 
                  ajouterBibliotheque(controller.text.trim()); 
                  Navigator.pop(context);
                }
              },
              child: const Text("Créer"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: bibliotheques.isEmpty
          ? Center(child: Text("Aucune bibliothèque trouvée. Créez-en une !"))
          : GridView.builder( // Utilisation de GridView pour un design moderne
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.8, 
              ),
              itemCount: bibliotheques.length,
              itemBuilder: (context, index) {
                final bibliothequeSelectionnee = bibliotheques[index];
                return InkWell( 
                  onTap: () {
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BibliothequeDetailPage(bibliotheque: bibliothequeSelectionnee),
                      ),
                    );
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Supprimer la bibliothèque ?"),
                        content: Text(
                            "Êtes-vous sûr de vouloir supprimer la bibliothèque '${bibliothequeSelectionnee.nom}' et tout son contenu ?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Annuler")),
                          TextButton(
                            onPressed: () async { 
                              
                              await retirerBibliotheque(bibliothequeSelectionnee);
                              Navigator.pop(context);
                            },
                            child: const Text("Supprimer",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Card( 
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Icon(
                              Icons.menu_book, 
                              size: 80,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            bibliothequeSelectionnee.nom,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBibliothequeDialog(context),
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text("Ajouter Bibliothèque"),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}