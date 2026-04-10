import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _role;
  String? get role => _role;

  bool _isSuperAdmin = false;
  bool get isSuperAdmin => _isSuperAdmin;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription? _userSub;
  StreamSubscription? _authSub;

  UserProvider() {
    _init();
  }

  void _init() {
    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _role = null;
        _isSuperAdmin = false;
        _isLoading = false;
        _userSub?.cancel();
        notifyListeners();
      } else {
        _listenToUserDoc(user.uid);
      }
    });
  }

  void _listenToUserDoc(String uid) {
    _userSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _userSub = _firestore.collection('users').doc(uid).snapshots().listen((snap) {
      if (snap.exists) {
        _role = snap.data()?['role'];
        // Broaden check: Allow both 'super_admin' and 'admin' for now
        _isSuperAdmin = _role == 'super_admin' || _role == 'admin';
        debugPrint('UserProvider: Role fetched from Firestore: $_role (isSuperAdmin: $_isSuperAdmin)');
      } else {
        debugPrint('UserProvider: User document NOT found for UID: $uid');
        _role = null;
        _isSuperAdmin = false;
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('UserProvider: Error fetching user doc: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
