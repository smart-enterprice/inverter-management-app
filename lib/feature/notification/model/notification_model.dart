// lib/feature/notifications/model/notification_model.dart

class NotificationModel {
  final String id;
  final String notificationId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> payload;
  final List<String> targetRoles;
  final List<ReadBy> readBy;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.notificationId,
    required this.type,
    required this.title,
    required this.message,
    required this.payload,
    required this.targetRoles,
    required this.readBy,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      notificationId: json['notification_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      targetRoles: List<String>.from(json['target_roles'] ?? []),
      readBy: (json['read_by'] as List<dynamic>? ?? [])
          .map((e) => ReadBy.fromJson(e))
          .toList(),
      createdBy: json['created_by'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      notificationId: notificationId,
      type: type,
      title: title,
      message: message,
      payload: payload,
      targetRoles: targetRoles,
      readBy: readBy,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class ReadBy {
  final String employeeId;
  final DateTime readAt;

  ReadBy({required this.employeeId, required this.readAt});

  factory ReadBy.fromJson(Map<String, dynamic> json) {
    return ReadBy(
      employeeId: json['employee_id'] ?? '',
      readAt: DateTime.tryParse(json['read_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final bool isConnected; // SSE connection status

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.isConnected = false,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool? isConnected,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
      isConnected: isConnected ?? this.isConnected,
    );
  }
}