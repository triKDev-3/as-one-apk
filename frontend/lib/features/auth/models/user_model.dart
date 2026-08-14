class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String role;
  final String? agentType;
  final bool? isAvailable;
  final double rankingScore;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    this.agentType,
    this.isAvailable,
    this.rankingScore = 0,
  });

  String get fullName => '$firstName $lastName';

  bool get isAgent => role == 'AGENT';
  bool get isChef => role == 'CHEF';
  bool get isAdmin => role == 'ADMIN';
  bool get isComptable => role == 'COMPTABLE';
  bool get isMagasinier => role == 'MAGASINIER';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      agentType: json['agentType'] as String?,
      isAvailable: json['isAvailable'] as bool?,
      rankingScore: (json['rankingScore'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'role': role,
        'agentType': agentType,
        'isAvailable': isAvailable,
        'rankingScore': rankingScore,
      };

  UserModel copyWith({bool? isAvailable, double? rankingScore}) {
    return UserModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      role: role,
      agentType: agentType,
      isAvailable: isAvailable ?? this.isAvailable,
      rankingScore: rankingScore ?? this.rankingScore,
    );
  }
}
