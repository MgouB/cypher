class Morceau {
  String titre;
  String artiste;
  String cover;
  String id;

  Morceau(
      {required this.titre,
      required this.artiste,
      required this.cover,
      required this.id});

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'artiste': artiste,
      'cover': cover,
      'id': id,
    };
  }
}

class Collection {
  String nom;
  List<Morceau> morceaux;

  Collection({required this.nom, required this.morceaux});

  void ajouterMorceau(Morceau morceau) {
    morceaux.add(morceau);
  }

  void retirerMorceau(Morceau morceau) {
    morceaux.removeWhere((m) => m.id == morceau.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'morceaux': morceaux.map((e) => e.toMap()).toList(),
    };
  }
}

class Bibliotheque {
  String nom;
  
  List<Collection> collections; 

 
  Bibliotheque({required this.nom, required this.collections});

  
  void ajouterCollection(Collection collection) {
    collections.add(collection);
  }

 
  void retirerCollection(Collection collection) {
    collections.removeWhere((c) => c.nom == collection.nom);
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'collections': collections.map((e) => e.toMap()).toList(),
    };
  }
}