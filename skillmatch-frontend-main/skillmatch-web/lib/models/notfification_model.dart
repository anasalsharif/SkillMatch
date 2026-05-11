class NotificationModel {
  final String? id;
  final String? title;
  final String? body;
  final String? timestamp;
  final String? reciver;
  final String? jobId;
  final String? postId;
  final bool? read;

  final String? meetingLink;
  final String? meetingId;
  final String? applicantId;
  final String? scheduledDateTime;
  final String? organizationId;
  final String? sender;
  final String? applicationId;

  NotificationModel({
    this.id,
    this.title,
    this.body,
    this.timestamp,
    this.reciver,
    this.jobId,
    this.postId,
    this.read,
    this.meetingLink,
    this.meetingId,
    this.applicantId,
    this.scheduledDateTime,
    this.organizationId,
    this.sender,
    this.applicationId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'No title',
      body: json['body'] ?? 'No body',
      timestamp: json['timestamp']?.toString() ?? 'Unknown time',
      reciver: json['reciver'] ?? 'No reciver',
      jobId: json['jobId'] ?? 'No jobId',
      postId: json['postId'] ?? 'No postId',
      read: json['read'] ?? false,
      meetingLink: json['meetingLink'] ?? 'No meetingLink',
      meetingId: json['meetingId'] ?? 'No meetingId',
      applicantId: json['applicantId'] ?? 'No applicantId',
      scheduledDateTime: json['scheduledDateTime'] ?? 'No scheduledDateTime',
      organizationId: json['organizationId'] ?? 'No organizationId',
      sender: json['sender'] ?? 'No sender',
      applicationId: json['applicationId'] ?? 'No applicationId',
    );
  }
}
