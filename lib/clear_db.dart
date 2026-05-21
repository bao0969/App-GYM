import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final db = FirebaseFirestore.instance;
  for (var c in ['members', 'trainers', 'packages', 'checkins']) {
    var snap = await db.collection(c).get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
