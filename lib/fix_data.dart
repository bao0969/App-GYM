import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = FirebaseFirestore.instance;

  // Xóa toàn bộ equipment cũ
  final snap = await db.collection('equipment').get();
  for (final doc in snap.docs) {
    await doc.reference.delete();
  }

  // Thêm lại dữ liệu chuẩn
  final items = [
    {
      'name': 'Dây kháng lực',
      'category': 'Phụ kiện',
      'quantity': 20,
      'status': 'good',
      'lastMaintenance': null,
      'notes': '',
      'updatedAt': Timestamp.now(),
    },
    {
      'name': 'Ghế tập đa năng',
      'category': 'Tạ',
      'quantity': 12,
      'status': 'good',
      'lastMaintenance': null,
      'notes': '',
      'updatedAt': Timestamp.now(),
    },
    {
      'name': 'Máy ép ngực',
      'category': 'Máy',
      'quantity': 3,
      'status': 'good',
      'lastMaintenance': Timestamp.fromDate(DateTime(2026, 4, 1)),
      'notes': '',
      'updatedAt': Timestamp.now(),
    },
    {
      'name': 'Máy chạy bộ Technogym',
      'category': 'Cardio',
      'quantity': 8,
      'status': 'good',
      'lastMaintenance': Timestamp.fromDate(DateTime(2026, 3, 1)),
      'notes': '',
      'updatedAt': Timestamp.now(),
    },
    {
      'name': 'Máy elip',
      'category': 'Cardio',
      'quantity': 4,
      'status': 'maintenance',
      'lastMaintenance': Timestamp.fromDate(DateTime(2026, 5, 8)),
      'notes': '',
      'updatedAt': Timestamp.now(),
    },
  ];

  for (final item in items) {
    await db.collection('equipment').add(item);
  }

  // ignore: avoid_print
  print('Fixed equipment data successfully!');
}
