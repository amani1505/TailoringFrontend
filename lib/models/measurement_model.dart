class Measurement {
  final String id;
  final String userId;
  final double height;
  final double? shoulderWidth;
  final double? chestCircumference;
  final double? waistCircumference;
  final double? hipCircumference;
  final double? sleeveLength;
  final double? upperArmLength;
  final double? neckCircumference;
  final double? inseam;
  final double? torsoLength;
  final double? bicepCircumference;
  final double? wristCircumference;
  final double? thighCircumference;
  final String? frontImageUrl;
  final String? sideImageUrl;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? confidence;
  final String? notes;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  Measurement({
    required this.id,
    required this.userId,
    required this.height,
    this.shoulderWidth,
    this.chestCircumference,
    this.waistCircumference,
    this.hipCircumference,
    this.sleeveLength,
    this.upperArmLength,
    this.neckCircumference,
    this.inseam,
    this.torsoLength,
    this.bicepCircumference,
    this.wristCircumference,
    this.thighCircumference,
    this.frontImageUrl,
    this.sideImageUrl,
    this.metadata,
    this.confidence,
    this.notes,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'] as String,
      userId: json['userId'] as String,
      height: (json['height'] as num).toDouble(),
      shoulderWidth: json['shoulderWidth'] != null
          ? (json['shoulderWidth'] as num).toDouble()
          : null,
      chestCircumference: json['chestCircumference'] != null
          ? (json['chestCircumference'] as num).toDouble()
          : null,
      waistCircumference: json['waistCircumference'] != null
          ? (json['waistCircumference'] as num).toDouble()
          : null,
      hipCircumference: json['hipCircumference'] != null
          ? (json['hipCircumference'] as num).toDouble()
          : null,
      sleeveLength: json['sleeveLength'] != null
          ? (json['sleeveLength'] as num).toDouble()
          : null,
      upperArmLength: json['upperArmLength'] != null
          ? (json['upperArmLength'] as num).toDouble()
          : null,
      neckCircumference: json['neckCircumference'] != null
          ? (json['neckCircumference'] as num).toDouble()
          : null,
      inseam: json['inseam'] != null
          ? (json['inseam'] as num).toDouble()
          : null,
      torsoLength: json['torsoLength'] != null
          ? (json['torsoLength'] as num).toDouble()
          : null,
      bicepCircumference: json['bicepCircumference'] != null
          ? (json['bicepCircumference'] as num).toDouble()
          : null,
      wristCircumference: json['wristCircumference'] != null
          ? (json['wristCircumference'] as num).toDouble()
          : null,
      thighCircumference: json['thighCircumference'] != null
          ? (json['thighCircumference'] as num).toDouble()
          : null,
      frontImageUrl: json['frontImageUrl'] as String?,
      sideImageUrl: json['sideImageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      confidence: json['confidence'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'height': height,
      'shoulderWidth': shoulderWidth,
      'chestCircumference': chestCircumference,
      'waistCircumference': waistCircumference,
      'hipCircumference': hipCircumference,
      'sleeveLength': sleeveLength,
      'upperArmLength': upperArmLength,
      'neckCircumference': neckCircumference,
      'inseam': inseam,
      'torsoLength': torsoLength,
      'bicepCircumference': bicepCircumference,
      'wristCircumference': wristCircumference,
      'thighCircumference': thighCircumference,
      'frontImageUrl': frontImageUrl,
      'sideImageUrl': sideImageUrl,
      'metadata': metadata,
      'confidence': confidence,
      'notes': notes,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
