class ChartCommentModel {
  final int id;
  final String message;
  final String commenterName;
  final String commenterUsername;
  final String commenterPhoto;
  final String createdAt;

  ChartCommentModel({
    required this.id,
    required this.message,
    required this.commenterName,
    required this.commenterUsername,
    required this.commenterPhoto,
    required this.createdAt,
  });

  factory ChartCommentModel.fromJson(Map<String, dynamic> json) {
    return ChartCommentModel(
      id: json['id'] ?? 0,
      message: json['message'] ?? '',
      commenterName: json['commenter_name'] ?? '',
      commenterUsername: json['commenter_username'] ?? '',
      commenterPhoto: json['commenter_photo'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}