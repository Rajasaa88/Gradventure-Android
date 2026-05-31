class UserModel {
  final String uid;
  final String nama;
  final String nim;
  final String prodi;
  final String angkatan;
  final String email;

  UserModel({
    required this.uid,
    required this.nama,
    required this.nim,
    required this.prodi,
    required this.angkatan,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'nim': nim,
      'prodi': prodi,
      'angkatan': angkatan,
      'email': email,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nama: map['nama'] ?? '',
      nim: map['nim'] ?? '',
      prodi: map['prodi'] ?? '',
      angkatan: map['angkatan'] ?? '',
      email: map['email'] ?? '',
    );
  }
}