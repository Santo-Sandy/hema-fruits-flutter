class BlockedUser {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime blockedAt;
  final String? reason;
  final dynamic raw;

  BlockedUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.blockedAt,
    this.reason,
    this.raw
  });

  // For API serialization
  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: (json['_id'] ?? "") as String,
      name: (json['name'] ?? "") as String,
      email: (json['email'] ?? "") as String,
      avatarUrl: (json['picture'] ?? "") as String?,
      blockedAt: DateTime.parse((json['created_on'] ?? "") as String),
      reason: (json['reason'] ?? "") as String?,
      raw:(json)
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'picture': avatarUrl,
      'created_on': blockedAt.toIso8601String(),
      'reason': reason,
    };
  }
}
