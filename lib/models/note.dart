class Note {
  int? id;
  String? clientEmail;
  String text;
  final DateTime createdAt;
  final String? authorName;
  final List<String> attachments;
  final String? voiceNotePath;

  Note({
    this.id,
    this.clientEmail,
    required this.text,
    required this.createdAt,
    this.authorName,
    this.attachments = const [],
    this.voiceNotePath,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int?,
      clientEmail: json['client_email'],
      authorName: json['author_name'],
      text: json['text'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (clientEmail != null) 'client_email': clientEmail,
      'author_name': authorName ?? '',
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

