import 'package:flutter/material.dart';
import 'classe.dart';
import 'affichepage.dart'; 
import 'supabase_service.dart';

class BibliothequeDetailPage extends StatefulWidget {
  final Bibliotheque bibliotheque;

  const BibliothequeDetailPage({Key? key, required this.bibliotheque}) : super(key: key);

  @override
  _BibliothequeDetailPageState createState() => _BibliothequeDetailPageState();
}

class _BibliothequeDetailPageState extends State<BibliothequeDetailPage> {
  final SupabaseService sbService = SupabaseService();

  void ajouterCollection(String nom) async {
    setState(() {
      widget.bibliotheque.ajouterCollection(Collection(nom: nom, morceaux: []));
    });
    await sbService.saveBibliotheque(widget.bibliotheque); 
  }
  
  
  Future<void> retirerCollection(Collection collectionSelectionnee) async { 
    setState(() {
      widget.bibliotheque.retirerCollection(collectionSelectionnee);
    });
    await sbService.saveBibliotheque(widget.bibliotheque);
  }

  void _showAddCollectionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nom de la Nouvelle Collection"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Ex: Albums de Jazz"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ajouterCollection(controller.text.trim());
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Collections de ${widget.bibliotheque.nom}"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: widget.bibliotheque.collections.length,
        itemBuilder: (context, index) {
          final collectionSelectionnee = widget.bibliotheque.collections[index];
          return Card( 
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.folder_copy, color: Theme.of(context).colorScheme.tertiary),
              title: Text(collectionSelectionnee.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  '/affiche',
                  arguments: {
                    'collectionNom': collectionSelectionnee.nom, 
                    'bibliotheque': widget.bibliotheque, 
                  },
                );
                await sbService.saveBibliotheque(widget.bibliotheque);
                setState(() {});
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Supprimer la collection ?"),
                    content: Text(
                        "Êtes-vous sûr de vouloir supprimer la collection '${collectionSelectionnee.nom}' ?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler")),
                      TextButton(
                        // L'onPressed doit être asynchrone pour utiliser await
                        onPressed: () async { 
                          await retirerCollection(collectionSelectionnee);
                          Navigator.pop(context);
                        },
                        child: const Text("Supprimer",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCollectionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Ajouter Collection"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}