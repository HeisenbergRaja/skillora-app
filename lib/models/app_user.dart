class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.bio,
    required this.credits,
    required this.rating,
    this.profileImage = '',
  });

  final String uid;
  final String name;
  final String email;
  final String bio;
  final int credits;
  final double rating;
  final String profileImage;

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? bio,
    int? credits,
    double? rating,
    String? profileImage,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      credits: credits ?? this.credits,
      rating: rating ?? this.rating,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] as String? ?? 'Skillora User',
      email: data['email'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      credits: (data['credits'] as num?)?.toInt() ?? 100,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      profileImage: data['profileImage'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'bio': bio,
      'credits': credits,
      'rating': rating,
      'profileImage': profileImage,
    };
  }
}
