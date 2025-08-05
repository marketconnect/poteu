class Subscription {
  final bool isActive;
  final DateTime? expirationDate;

  const Subscription({required this.isActive, this.expirationDate});

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      isActive: json['isActive'] ?? false,
      expirationDate: json['expiresAt'] != null && json['expiresAt'].isNotEmpty
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }

  factory Subscription.inactive() => const Subscription(isActive: false);

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'expiresAt': expirationDate?.toIso8601String(),
    };
  }
}
