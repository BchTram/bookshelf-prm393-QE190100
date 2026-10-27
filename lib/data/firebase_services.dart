import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseServices {
  static FirebaseApp? app;
  static FirebaseAuth get auth =>
      FirebaseAuth.instanceFor(app: app ?? Firebase.app());
  static FirebaseFirestore get firestore =>
      FirebaseFirestore.instanceFor(app: app ?? Firebase.app());
}
