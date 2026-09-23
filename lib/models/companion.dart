class Companion {
  final String id;
  final String name;
  final String pairingCode;
  final DateTime pairedAt;
  final bool isActive;

  Companion({
    required this.id,
    required this.name,
    required this.pairingCode,
    required this.pairedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pairingCode': pairingCode,
        'pairedAt': pairedAt.toIso8601String(),
        'isActive': isActive ? 1 : 0,
      };

  factory Companion.fromJson(Map<String, dynamic> json) => Companion(
        id: json['id'],
        name: json['name'],
        pairingCode: json['pairingCode'],
        pairedAt: DateTime.parse(json['pairedAt']),
        isActive: json['isActive'] == 1,
      );
}
