class Skill {
  const Skill({
    required this.id,
    required this.userId,
    required this.providerName,
    required this.title,
    required this.description,
    required this.category,
    required this.credits,
    required this.rating,
    required this.status,
  });

  final String id;
  final String userId;
  final String providerName;
  final String title;
  final String description;
  final String category;
  final int credits;
  final double rating;
  final String status;

  factory Skill.fromMap(String id, Map<String, dynamic> data) {
    return Skill(
      id: id,
      userId: data['userId'] as String? ?? '',
      providerName: data['providerName'] as String? ?? 'Skill Provider',
      title: data['title'] as String? ?? 'Untitled Skill',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      credits: (data['credits'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'providerName': providerName,
      'title': title,
      'description': description,
      'category': category,
      'credits': credits,
      'rating': rating,
      'status': status,
    };
  }
}
