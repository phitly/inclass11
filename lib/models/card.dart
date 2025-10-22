class Card {
  final int? id;
  final String name;
  final String suit;
  final String value; // Ace, 2-10, Jack, Queen, King
  final String imageUrl;
  final List<int>? imageData; // Optional byte data for offline storage
  final int? folderId; // Foreign key to folder

  Card({
    this.id,
    required this.name,
    required this.suit,
    required this.value,
    required this.imageUrl,
    this.imageData,
    this.folderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'value': value,
      'imageUrl': imageUrl,
      'imageData': imageData,
      'folderId': folderId,
    };
  }

  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      id: map['id'],
      name: map['name'],
      suit: map['suit'],
      value: map['value'],
      imageUrl: map['imageUrl'],
      imageData: map['imageData'] != null ? List<int>.from(map['imageData']) : null,
      folderId: map['folderId'],
    );
  }

  Card copyWith({
    int? id,
    String? name,
    String? suit,
    String? value,
    String? imageUrl,
    int? folderId,
  }) {
    return Card(
      id: id ?? this.id,
      name: name ?? this.name,
      suit: suit ?? this.suit,
      value: value ?? this.value,
      imageUrl: imageUrl ?? this.imageUrl,
      folderId: folderId ?? this.folderId,
    );
  }

  String get displayName => '$value of $suit';
}