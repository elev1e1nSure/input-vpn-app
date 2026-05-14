class CustomDnsProfile {
  CustomDnsProfile({
    required this.id,
    required this.name,
    required this.primary,
    this.secondary,
  });

  final String id;
  final String name;
  final String primary;
  final String? secondary;

  List<String> get servers =>
      [primary, if (secondary != null && secondary!.isNotEmpty) secondary!];

  CustomDnsProfile copyWith(
      {String? name, String? primary, String? secondary}) {
    return CustomDnsProfile(
      id: id,
      name: name ?? this.name,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primary': primary,
        if (secondary != null) 'secondary': secondary,
      };

  factory CustomDnsProfile.fromJson(Map<String, dynamic> json) =>
      CustomDnsProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        primary: json['primary'] as String,
        secondary: json['secondary'] as String?,
      );
}
