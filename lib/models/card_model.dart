class CardModel {
  int? id;
  String name;
  String suit;
  String imageUrl;
  int? folderId;
  DateTime createdAt;

  CardModel({
    this.id,
    required this.name,
    required this.suit,
    required this.imageUrl,
    this.folderId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'imageUrl': imageUrl,
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
      folderId: map['folderId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}