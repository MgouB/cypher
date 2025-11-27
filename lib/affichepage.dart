import 'package:flutter/material.dart';
import 'classe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'supabase_service.dart';

class AffichePage extends StatefulWidget {
  const AffichePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<AffichePage> createState() => _AffichePageState();
}

class _AffichePageState extends State<AffichePage> {
  final SupabaseService sbService = SupabaseService();
  
  late Collection collection; 
  late Bibliotheque bibliothequeRacine; 

  final TextEditingController _searchController = TextEditingController();

  Future<void> ajouterMorceau(String morceauId) async {
    String url = "https://api.deezer.com/track/$morceauId";
    var reponse = await http.get(Uri.parse(url));

    if (reponse.statusCode == 200) {
      var data = convert.jsonDecode(reponse.body);

      if (data.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Morceau non trouvé."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Morceau morceau = Morceau(
        titre: data['title'],
        artiste: data['artist']['name'],
        cover: data['album']['cover_medium'],
        id: morceauId,
      );

      setState(() {
        collection.ajouterMorceau(morceau);
      });
      
      await sbService.saveBibliotheque(bibliothequeRacine); 

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Morceau '${morceau.titre}' ajouté à ${collection.nom} !"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Erreur lors de la récupération du morceau (Statut: ${reponse.statusCode})."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> retirerMorceau(Morceau morceau) async {
    setState(() {
      collection.morceaux.removeWhere((m) => m.id == morceau.id);
    });
    
    await sbService.saveBibliotheque(bibliothequeRacine);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Morceau '${morceau.titre}' retiré de ${collection.nom}."),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<List<Morceau>> chercher(String query) async {
    String encodedQuery = Uri.encodeComponent(query);
    String url = "https://api.deezer.com/search?q=$encodedQuery&limit=10";

    var reponse = await http.get(Uri.parse(url));

    if (reponse.statusCode == 200) {
      var dataMap = convert.jsonDecode(reponse.body);
      List<Morceau> resultats = [];

      if (dataMap['data'] != null) {
        for (var track in dataMap['data']) {
          resultats.add(Morceau(
            titre: track['title'],
            artiste: track['artist']['name'],
            cover: track['album']['cover_medium'],
            id: track['id'].toString(),
          ));
        }
      }
      return resultats;
    }
    return [];
  }

  void rechercherMorceau() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rechercher un morceau"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    hintText: "Nom du morceau ou artiste..."),
                onSubmitted: (value) async {
                  Navigator.of(context).pop();
                  await afficherResultatsRecherche(value);
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final query = _searchController.text.trim();
                  if (query.isNotEmpty) {
                    Navigator.of(context).pop();
                    await afficherResultatsRecherche(query);
                  }
                },
                child: const Text("Rechercher"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Annuler"),
              onPressed: () {
                _searchController.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> afficherResultatsRecherche(String query) async {
    List<Morceau> resultats = await chercher(query);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Résultats pour '$query'"),
          content: resultats.isEmpty
              ? const Text("Aucun résultat trouvé.")
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: resultats.length,
                    itemBuilder: (context, index) {
                      final morceauResultat = resultats[index];
                      return ListTile(
                        leading: Image.network(morceauResultat.cover),
                        title: Text(morceauResultat.titre),
                        subtitle: Text(morceauResultat.artiste),
                        onTap: () {
                          Navigator.of(context).pop();
                          ajouterMorceau(morceauResultat.id);
                        },
                      );
                    },
                  ),
                ),
          actions: <Widget>[
            TextButton(
              child: const Text("Fermer"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget afficheData() {
    return ListView.builder(
      itemCount: collection.morceaux.length,
      itemBuilder: (context, index) {
        final morceau = collection.morceaux[index];
        return Card( 
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(10.0),
            leading: ClipRRect( 
              borderRadius: BorderRadius.circular(8.0),
              child: SizedBox( // Utilisation de SizedBox pour garantir la taille
                width: 60,
                height: 60,
                child: FadeInImage.assetNetwork( // Utilisation de FadeInImage pour gérer les erreurs de chargement
                  placeholder: 'assets/loading.gif', // Vous devez avoir un fichier loading.gif ou un placeholder
                  image: morceau.cover,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.music_note, size: 40));
                  },
                ),
              ),
            ),
            title: Text(
              morceau.titre,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              morceau.artiste,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.more_vert), 
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.delete_forever,
                              color: Colors.red),
                          title: const Text('Retirer de la collection',
                              style: TextStyle(color: Colors.red)),
                          onTap: () async {
                            await retirerMorceau(morceau);
                            Navigator.pop(context); 
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.send),
                          title: const Text('Transférer vers une autre collection'),
                          onTap: () {
                            Navigator.pop(context); 
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Le transfert nécessite une gestion d'état globale."),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('Voir le détail du morceau'),
                          onTap: () {
                            Navigator.pop(context); 
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Détail de ${morceau.titre} (ID: ${morceau.id})"),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    bibliothequeRacine = args['bibliotheque'] as Bibliotheque;
    final collectionNom = args['collectionNom'] as String;

    final foundCollection = bibliothequeRacine.collections.cast<Collection?>().firstWhere(
      (c) => c != null && c.nom == collectionNom,
      orElse: () => null, 
    );

    if (foundCollection == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Erreur"),
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "La collection '$collectionNom' n'a pas pu être trouvée dans la bibliothèque '${bibliothequeRacine.nom}'.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    collection = foundCollection;

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.nom),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
        child: afficheData(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: rechercherMorceau,
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}