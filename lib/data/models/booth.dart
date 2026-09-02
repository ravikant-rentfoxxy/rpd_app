class Booth {
  const Booth({
    required this.id,
    required this.code,
    required this.boothNumber,
    required this.partNumber,
    required this.name,
    required this.landmark,
    required this.village,
    required this.pincode,
    required this.voterCount,
    required this.memberCount,
    required this.latitude,
    required this.longitude,
    required this.healthScore,
    required this.healthBand,
    this.mandalName,
    this.assemblyName,
    this.districtName,
    this.distanceMetres,
  });

  final String id;
  final String code;
  final String boothNumber;
  final String partNumber;
  final String name;
  final String landmark;
  final String village;
  final String pincode;
  final int voterCount;
  final int memberCount;
  final double latitude;
  final double longitude;
  final int healthScore;
  final String healthBand;
  final String? mandalName;
  final String? assemblyName;
  final String? districtName;
  final int? distanceMetres;

  Booth copyWith({int? distanceMetres}) => Booth(
        id: id,
        code: code,
        boothNumber: boothNumber,
        partNumber: partNumber,
        name: name,
        landmark: landmark,
        village: village,
        pincode: pincode,
        voterCount: voterCount,
        memberCount: memberCount,
        latitude: latitude,
        longitude: longitude,
        healthScore: healthScore,
        healthBand: healthBand,
        mandalName: mandalName,
        assemblyName: assemblyName,
        districtName: districtName,
        distanceMetres: distanceMetres ?? this.distanceMetres,
      );

  factory Booth.fromJson(Map<String, dynamic> json) => Booth(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        boothNumber: json['boothNumber'] as String? ?? '',
        partNumber: json['partNumber'] as String? ?? '',
        name: json['name'] as String? ?? '',
        landmark: json['landmark'] as String? ?? '',
        village: json['village'] as String? ?? '',
        pincode: json['pincode'] as String? ?? '',
        voterCount: (json['voterCount'] as num?)?.toInt() ?? 0,
        memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        healthScore: (json['healthScore'] as num?)?.toInt() ?? 0,
        healthBand: json['healthBand'] as String? ?? 'ATTENTION',
        mandalName: json['mandalName'] as String?,
        assemblyName: json['assemblyName'] as String?,
        districtName: json['districtName'] as String?,
        distanceMetres: (json['distanceMetres'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'boothNumber': boothNumber,
        'partNumber': partNumber,
        'name': name,
        'landmark': landmark,
        'village': village,
        'pincode': pincode,
        'voterCount': voterCount,
        'memberCount': memberCount,
        'latitude': latitude,
        'longitude': longitude,
        'healthScore': healthScore,
        'healthBand': healthBand,
        'mandalName': mandalName,
        'assemblyName': assemblyName,
        'districtName': districtName,
        'distanceMetres': distanceMetres,
      };
}
