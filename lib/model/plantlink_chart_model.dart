class PlantLinkChartModel {
  final int id;
  final String name;
  final String embedLink;
  final String chartType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int userId;

  bool get isLive =>
      startDate != null &&
      endDate != null &&
      startDate!.year == 2000 &&
      endDate!.year == 2099;

  PlantLinkChartModel({
    required this.id,
    required this.name,
    required this.embedLink,
    required this.chartType,
    this.startDate,
    this.endDate,
    required this.userId,
  });

  factory PlantLinkChartModel.fromJson(Map<String, dynamic> json) {
    return PlantLinkChartModel(
      id: json['id'],
      name: json['name'],
      embedLink: json['embed_link'],
      chartType: json['chart_type'],
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'embed_link': embedLink,
      'chart_type': chartType,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'user_id': userId,
    };
  }
}

class PlantLinkChartSharingModel {
  final int id;
  final String title;
  final String description;
  final String link;
  final String chartType;
  final int groupId;
  final int userId;
  final DateTime? createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final String posterName;
  final String posterUsername;
  final String posterPhoto;

  bool get isLive =>
      startDate != null &&
      endDate != null &&
      startDate!.year == 2000 &&
      endDate!.year == 2099;

  PlantLinkChartSharingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.chartType,
    required this.groupId,
    required this.userId,
    this.createdAt,
    this.startDate,
    this.endDate,
    this.posterName = '',
    this.posterUsername = '',
    this.posterPhoto = '',
  });

  factory PlantLinkChartSharingModel.fromJson(Map<String, dynamic> json) {
    return PlantLinkChartSharingModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      chartType: json['chart_type'] ?? '',
      groupId: json['Group_fk'] ?? 0,
      userId: json['user_id'] ?? json['Person_fk'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      posterName: json['name'] ?? '',
      posterUsername: json['username'] ?? '',
      posterPhoto: json['photo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'link': link,
      'chart_type': chartType,
      'Group_fk': groupId,
      'Person_fk': userId,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}