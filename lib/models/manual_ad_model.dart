class ManualAdModel {
  final int id;
  final String title;
  final String targetUrl;
  final String imageUrl;
  final String platform;
  final String placement;

  const ManualAdModel({
    required this.id,
    required this.title,
    required this.targetUrl,
    required this.imageUrl,
    required this.platform,
    required this.placement,
  });

  factory ManualAdModel.fromJson(Map<String, dynamic> json) {
    return ManualAdModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      targetUrl: (json['target_url'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      placement: (json['placement'] ?? '').toString(),
    );
  }
}
