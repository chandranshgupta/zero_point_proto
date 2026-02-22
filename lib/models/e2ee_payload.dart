class E2EEPayload {
  final String id;
  final String text;
  final int expiresAtMs; // UTC milliseconds

  E2EEPayload({
    required this.id,
    required this.text,
    required this.expiresAtMs,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "text": text,
        "expiresAtMs": expiresAtMs,
      };

  static E2EEPayload fromJson(Map<String, dynamic> json) {
    return E2EEPayload(
      id: json["id"] as String,
      text: json["text"] as String,
      expiresAtMs: json["expiresAtMs"] as int,
    );
  }
}