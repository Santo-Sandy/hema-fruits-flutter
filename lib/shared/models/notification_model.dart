enum NotificationType { enquiry, system, subscription, general }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? refId;
  final String? refType;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.refId,
    this.refType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
        title: j['title'] ?? '',
        body: j['body'] ?? j['message'] ?? '',
        isRead: j['isread'] ?? j['is_read'] ?? false,
        refId: j['ref_id']?.toString(),
        refType: j['ref_type'],
        createdAt: j['created_on'] != null
            ? DateTime.parse(j['created_on']).toLocal()
            : (j['created_at'] != null
                  ? DateTime.parse(j['created_at']).toLocal()
                  : DateTime.now()),
        type: NotificationType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => NotificationType.general,
        ),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    title: title,
    body: body,
    type: type,
    createdAt: createdAt,
    refId: refId,
    refType: refType,
    isRead: isRead ?? this.isRead,
  );
}
