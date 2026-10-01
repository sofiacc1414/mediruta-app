class MensajeChat {
  const MensajeChat({
    required this.id,
    required this.chatId,
    required this.remitenteId,
    required this.rolRemitente,
    required this.contenido,
    required this.creadoEn,
    required this.leidoEn,
  });

  final String id;
  final String chatId;
  final String remitenteId;
  final String rolRemitente;
  final String contenido;
  final DateTime creadoEn;
  final DateTime? leidoEn;

  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    return MensajeChat(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      remitenteId: json['remitenteId'] as String,
      rolRemitente: json['rolRemitente'] as String,
      contenido: json['contenido'] as String,
      creadoEn: DateTime.parse(json['creadoEn'] as String).toLocal(),
      leidoEn: json['leidoEn'] == null
          ? null
          : DateTime.parse(json['leidoEn'] as String).toLocal(),
    );
  }
}
