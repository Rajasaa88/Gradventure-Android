import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoursePage extends StatelessWidget {
  const CoursePage({super.key});

  @override
  Widget build(BuildContext context) {
    String uid =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daftar Mata Kuliah",
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .orderBy('semester')
            .snapshots(),
        builder: (context, courseSnapshot) {
          if (!courseSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final courses =
              courseSnapshot.data!.docs;

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course =
                  courses[index];

              final data =
                    course.data() as Map<String, dynamic>;

                print(data);

              final String kode =
    data['kode']?.toString() ?? '';;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(
                        'student_courses')
                    .doc(uid)
                    .collection('courses')
                    .doc(kode)
                    .snapshots(),
                builder: (context,
                    studentSnapshot) {
                  bool isTaken =
                      studentSnapshot.hasData &&
                          studentSnapshot
                              .data!.exists;

                  return CheckboxListTile(
                    title: Text(
  data['nama']?.toString() ?? '-',
),
                    subtitle: Text(
  "${data['kode'] ?? '-'} • ${data['sks'] ?? 0} SKS",
),
                    secondary: Text(
                      "Smt ${data['semester']}",
                    ),
                    value: isTaken,
                    onChanged:
                        (value) async {
                      if (value ==
                          true) {
                        await FirebaseFirestore
                            .instance
                            .collection(
                                'student_courses')
                            .doc(uid)
                            .collection(
                                'courses')
                            .doc(kode)
                            .set({
                          'kode':
                              data['kode'],
                          'nama':
                              data['nama'],
                          'sks':
                              data['sks'],
                          'nilai': 'A',
                          'status':
                              'Lulus',
                          'semester_tempuh':
                              data[
                                  'semester'],
                        });
                      } else {
                        await FirebaseFirestore
                            .instance
                            .collection(
                                'student_courses')
                            .doc(uid)
                            .collection(
                                'courses')
                            .doc(kode)
                            .delete();
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}