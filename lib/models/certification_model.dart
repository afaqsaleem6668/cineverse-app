// Certification Model
class CertificationList {
  final Map<String, List<Certification>> certifications;

  CertificationList({required this.certifications});

  factory CertificationList.fromJson(Map<String, dynamic> json) {
    Map<String, List<Certification>> certs = {};
    if (json['certifications'] != null) {
      (json['certifications'] as Map<String, dynamic>).forEach((key, value) {
        certs[key] = (value as List)
            .map((e) => Certification.fromJson(e))
            .toList();
      });
    }
    return CertificationList(certifications: certs);
  }
}

class Certification {
  final String certification;
  final String meaning;
  final int order;

  Certification({
    required this.certification,
    required this.meaning,
    required this.order,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      certification: json['certification'] ?? '',
      meaning: json['meaning'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}
