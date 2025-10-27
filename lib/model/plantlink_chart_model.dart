class PlantLinkChartModel {
  final int id;
  final String name;
  final String embedLink;
  final String chartType;
  final DateTime startDate;
  final DateTime endDate;
  final int userId;

  PlantLinkChartModel({
    required this.id,
    required this.name,
    required this.embedLink,
    required this.chartType,
    required this.startDate,
    required this.endDate,
    required this.userId,
  });

  factory PlantLinkChartModel.fromJson(Map<String, dynamic> json) {
    return PlantLinkChartModel(
      id: json['id'],
      name: json['name'] ?? '',
      embedLink: json['embed_link'] ?? '',
      chartType: json['chart_type'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'embed_link': embedLink,
      'chart_type': chartType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
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
  final DateTime createdAt;

  PlantLinkChartSharingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.chartType,
    required this.groupId,
    required this.userId,
    required this.createdAt,
  });

  factory PlantLinkChartSharingModel.fromJson(Map<String, dynamic> json) {
    return PlantLinkChartSharingModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      chartType: json['chart_type'] ?? '',
      groupId: json['Group_fk'],
      userId: json['Person_fk'],
      createdAt: DateTime.parse(json['created_at']),
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
    };
  }
}