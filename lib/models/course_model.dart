class CourseModel {
  final String kode;
  final String nama;
  final int sks;
  final int semester;
  final List<dynamic> prasyarat;

  CourseModel({
    required this.kode,
    required this.nama,
    required this.sks,
    required this.semester,
    required this.prasyarat,
  });

  factory CourseModel.fromMap(
      Map<String, dynamic> map) {
    return CourseModel(
      kode: map['kode'] ?? '',
      nama: map['nama'] ?? '',
      sks: map['sks'] ?? 0,
      semester: map['semester'] ?? 0,
      prasyarat: map['prasyarat'] ?? [],
    );
  }
}