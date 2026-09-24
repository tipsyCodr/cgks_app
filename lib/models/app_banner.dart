class AppBannerModel {
  final int id;
  final String? title;
  final String image;
  final String? imageUrl;
  final String? link;
  final int order;
  final bool isActive;

  AppBannerModel({
    required this.id,
    this.title,
    required this.image,
    this.imageUrl,
    this.link,
    this.order = 0,
    this.isActive = true,
  });

  factory AppBannerModel.fromJson(Map<String, dynamic> json) {
    return AppBannerModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'],
      image: json['image'] ?? '',
      imageUrl: json['image_url'],
      link: json['link'],
      order: json['order'] is int
          ? json['order']
          : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}
