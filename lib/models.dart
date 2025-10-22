class Folder {
  int? id;
  String name;
  String? previewImage;
  DateTime createdAt;

  Folder({
    this.id,
    required this.name,
    this.previewImage,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'previewImage': previewImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      previewImage: map['previewImage'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class CardModel {
  int? id;
  String name;
  String suit;
  String imageUrl;
  String? imageBytes;
  int? folderId;
  DateTime createdAt;

  CardModel({
    this.id,
    required this.name,
    required this.suit,
    required this.imageUrl,
    this.imageBytes,
    this.folderId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'imageUrl': imageUrl,
      'imageBytes': imageBytes,
      'folderId': folderId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      name: map['name'],
      suit: map['suit'],
      imageUrl: map['imageUrl'],
      imageBytes: map['imageBytes'],
      folderId: map['folderId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}