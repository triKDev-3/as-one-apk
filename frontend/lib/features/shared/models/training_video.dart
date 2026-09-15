class TrainingVideo {
  final String id;
  final String title;
  final String? description;
  final String youtubeUrl;
  final String? lessonContent;
  final bool isActive;
  final int orderIndex;
  final DateTime createdAt;

  TrainingVideo({
    required this.id,
    required this.title,
    this.description,
    required this.youtubeUrl,
    this.lessonContent,
    required this.isActive,
    required this.orderIndex,
    required this.createdAt,
  });

  factory TrainingVideo.fromJson(Map<String, dynamic> json) {
    return TrainingVideo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      youtubeUrl: json['youtubeUrl'],
      lessonContent: json['lessonContent'],
      isActive: json['isActive'] ?? true,
      orderIndex: json['orderIndex'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'youtubeUrl': youtubeUrl,
      'lessonContent': lessonContent,
      'isActive': isActive,
      'orderIndex': orderIndex,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
