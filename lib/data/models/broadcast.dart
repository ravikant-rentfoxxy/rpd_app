import 'package:get/get.dart';

/// An official message an office bearer publishes to the members under them,
/// served on the home payload as `announcement`.
class Broadcast {
  const Broadcast({
    required this.id,
    required this.messages,
    required this.sentAt,
    this.audioUrl,
  });

  final String id;

  /// One entry per locale code the server carries: `hi`, `en`, `bho`. A language
  /// the author left blank is absent rather than empty.
  final Map<String, String> messages;
  final DateTime sentAt;

  /// A recording of the message. Null while none has been attached, which is
  /// what hides the listen button.
  final String? audioUrl;

  bool get hasAudio => (audioUrl ?? '').trim().isNotEmpty;

  /// The member's own language, falling back to whichever the author did write.
  /// An announcement is worth showing in the wrong language; it is not worth
  /// showing as a blank card.
  String get message {
    final preferred = Get.locale?.languageCode ?? 'hi';
    for (final code in [preferred, 'hi', 'en', 'bho']) {
      final text = messages[code]?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  bool get isEmpty => message.isEmpty;

  static Broadcast? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final body = json['message'] is Map ? Map<String, dynamic>.from(json['message'] as Map) : const {};
    final messages = <String, String>{};
    for (final code in ['hi', 'en', 'bho']) {
      final text = '${body[code] ?? ''}'.trim();
      if (text.isNotEmpty) messages[code] = text;
    }
    if (messages.isEmpty) return null;
    final audio = '${json['audioUrl'] ?? ''}'.trim();
    return Broadcast(
      id: '${json['id'] ?? ''}',
      messages: messages,
      sentAt: DateTime.tryParse('${json['sentAt'] ?? ''}')?.toLocal() ?? DateTime.now(),
      audioUrl: audio.isEmpty ? null : audio,
    );
  }
}
