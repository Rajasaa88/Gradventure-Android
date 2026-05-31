import 'package:cloud_firestore/cloud_firestore.dart';

class CourseService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Stream<QuerySnapshot> getCourses() {
    return firestore
        .collection('courses')
        .orderBy('semester')
        .snapshots();
  }
}