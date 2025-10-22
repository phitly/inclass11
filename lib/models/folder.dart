class Folder {
  final int? id;
  final String name;
  final String suit;
  final DateTime timestamp;

  Folder({
    this.id,
    required this.name,
    required this.suit,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      suit: map['suit'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  Folder copyWith({
    int? id,
    String? name,
    String? suit,
    DateTime? timestamp,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      suit: suit ?? this.suit,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}