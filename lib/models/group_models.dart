enum DeliveryState { encrypted, sent, delivered }

class BroadcastPeer {
  final String id;
  final String name;
  final String userId;
  final String publicKey;

  BroadcastPeer({
    required this.id,
    required this.name,
    required this.userId,
    required this.publicKey,
  });
}

class RecipientDelivery {
  final String peerId;
  final String peerName;
  final String peerUserId;
  final String encryptedPreview;
  DeliveryState state;

  RecipientDelivery({
    required this.peerId,
    required this.peerName,
    required this.peerUserId,
    required this.encryptedPreview,
    this.state = DeliveryState.encrypted,
  });
}

class SentBroadcastMessage {
  final String id;
  final String plainText;
  final int expiresAtMs;
  final List<RecipientDelivery> recipients;

  SentBroadcastMessage({
    required this.id,
    required this.plainText,
    required this.expiresAtMs,
    required this.recipients,
  });
}

class IncomingGroupMessage {
  final String id;
  final String fromUserId;
  final String text;
  final int expiresAtMs;

  IncomingGroupMessage({
    required this.id,
    required this.fromUserId,
    required this.text,
    required this.expiresAtMs,
  });
}