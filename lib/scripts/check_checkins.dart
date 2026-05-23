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

  final checkins = await db.collection('checkins').get();
  print('=============================================');
  print('TOTAL CHECKINS IN DATABASE: ${checkins.docs.length}');
  for (var doc in checkins.docs) {
    print('ID: ${doc.id}, DATA: ${doc.data()}');
  }
  print('=============================================');
}
