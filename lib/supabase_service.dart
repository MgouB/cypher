import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'classe.dart'; 
import 'dart:convert'; 

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'bibliotheques';

  Bibliotheque _mapToBibliotheque(Map<String, dynamic> data) {
    Map<String, dynamic> decodedData = data['data'];

    String nom = decodedData['nom'];
    List<dynamic> collectionsMaps = decodedData['collections'] ?? [];
    
    List<Collection> collections = collectionsMaps.map((collectionMap) {
      
      List<dynamic> morceauxMaps = collectionMap['morceaux'] ?? [];
      List<Morceau> morceaux = morceauxMaps.map((morceauMap) => Morceau(
        titre: morceauMap['titre'],
        artiste: morceauMap['artiste'],
        cover: morceauMap['cover'],
        id: morceauMap['id'],
      )).toList();
      
      return Collection(nom: collectionMap['nom'], morceaux: morceaux);
    }).toList();

    return Bibliotheque(nom: nom, collections: collections);
  }

  
  Map<String, dynamic> _bibliothequeToSupabase(Bibliotheque bibliotheque) {
    return {
      'nom': bibliotheque.nom,
      'data': bibliotheque.toMap(), 
    };
  }

  Future<List<Bibliotheque>> getBibliotheques() async {
    final response = await _client.from(_tableName).select().order('nom', ascending: true);
    
    if (response.isEmpty) {
        return [];
    }
    return (response as List<dynamic>).map((e) => _mapToBibliotheque(e as Map<String, dynamic>)).toList();
  }

  
  Future<void> saveBibliotheque(Bibliotheque bibliotheque) async {
    final existing = await _client
        .from(_tableName)
        .select('id')
        .eq('nom', bibliotheque.nom); 

    final data = _bibliothequeToSupabase(bibliotheque);

    if (existing != null && existing.isNotEmpty) {
      
      final idToUpdate = existing.first['id'];
      await _client
          .from(_tableName)
          .update(data)
          .eq('id', idToUpdate);
    } else {
      await _client.from(_tableName).insert(data);
    }
  }

  
  Future<void> deleteBibliotheque(String nom) async {
    await _client
        .from(_tableName)
        .delete()
        .eq('nom', nom);
  }
}