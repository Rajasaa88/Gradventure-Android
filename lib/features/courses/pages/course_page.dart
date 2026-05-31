import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/course_service.dart';

class CoursePage extends StatelessWidget {
  const CoursePage({super.key});

  @override
  Widget build(BuildContext context) {
    final CourseService courseService =
        CourseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daftar Mata Kuliah",
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: courseService.getCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada mata kuliah",
              ),
            );
          }

          final courses =
              snapshot.data!.docs;

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final data =
                  courses[index].data()
                      as Map<String, dynamic>;

              return Card(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: ListTile(
                  title: Text(
                    data['nama'] ?? '-',
                  ),
                  subtitle: Text(
                    "${data['kode']} • ${data['sks']} SKS",
                  ),
                  trailing: Text(
                    "Smt ${data['semester']}",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}