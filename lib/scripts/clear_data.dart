import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = FirebaseFirestore.instance;

  // 1. Delete all checkins
  final checkins = await db
      .collection('checkins')
      .get();
      
  for (var doc in checkins.docs) {
    await doc.reference.delete();
  }
  print('Deleted ${checkins.docs.length} checkins.');

  // 2. Fix the joinDate of members created this month
  final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final members = await db
      .collection('members')
      .where('joinDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .get();
      
  final oldDate = DateTime(2000, 1, 1);
  for (var doc in members.docs) {
    await doc.reference.update({
      'joinDate': Timestamp.fromDate(oldDate),
    });
  }
  print('Updated ${members.docs.length} members.');

  print('CLEAR SCRIPT COMPLETED.');
}
