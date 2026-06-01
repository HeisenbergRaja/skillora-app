import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/skill.dart';

class SkilloraAppState extends ChangeNotifier {
  SkilloraAppState({required bool useFirebase}) : _useFirebase = useFirebase {
    _skills = _demoSkills;
    if (_useFirebase) {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        _handleAuthChanged,
        onError: (Object error) {
          _useFirebase = false;
          _error = 'Firebase auth failed. Demo mode is active.';
          _loading = false;
          notifyListeners();
        },
      );

      // Real-time listener for skills collection so mobile updates instantly
      _skillsSubscription = FirebaseFirestore.instance
          .collection('skills')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        try {
          // Debug logging for realtime updates
          // ignore: avoid_print
          print('Firestore skills snapshot: ${snapshot.docs.length}');

          _skills = snapshot.docs
              .map((doc) => Skill.fromMap(doc.id, doc.data()))
              .where((skill) => skill.status == 'active')
              .toList();
          notifyListeners();
        } catch (e) {
          _error = 'Failed to parse skills: $e';
          notifyListeners();
        }
      }, onError: (Object error) {
        _error = 'Skills subscription failed: $error';
        notifyListeners();
      });
    } else {
      _loading = false;
    }
  }

  bool _useFirebase;
  bool _loading = true;
  String? _error;
  AppUser? _currentUser;
  List<Skill> _skills = const [];
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _skillsSubscription;

  bool get useFirebase => _useFirebase;
  bool get loading => _loading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;
  AppUser? get currentUser => _currentUser;
  List<Skill> get skills => List.unmodifiable(_skills);

  List<Skill> get mySkills {
    final user = _currentUser;
    if (user == null) return const [];
    return _skills.where((skill) => skill.userId == user.uid).toList();
  }

  Future<void> login(String email, String password) async {
    await _runAction(() async {
      if (_useFirebase) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return;
      }

      _currentUser = AppUser(
        uid: 'demo-user',
        name: 'Demo Learner',
        email: email.trim(),
        bio: 'Exploring skills on Skillora.',
        credits: 100,
        rating: 4.8,
      );
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _runAction(() async {
      if (_useFirebase) {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user;
        if (user == null) {
          throw StateError('Account was not created.');
        }

        final profile = AppUser(
          uid: user.uid,
          name: name.trim(),
          email: email.trim(),
          bio: '',
          credits: 100,
          rating: 0,
        );

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          ...profile.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      _currentUser = AppUser(
        uid: 'demo-user',
        name: name.trim(),
        email: email.trim(),
        bio: '',
        credits: 100,
        rating: 0,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    await _runAction(() async {
      if (!_useFirebase) {
        // Demo fallback when Firebase not enabled
        _currentUser = AppUser(
          uid: 'google-demo',
          name: 'Google Demo',
          email: '',
          bio: '',
          credits: 100,
          rating: 0,
        );
        return;
      }

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // user aborted
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    });
  }

  Future<void> logout() async {
    await _runAction(() async {
      if (_useFirebase) {
        await FirebaseAuth.instance.signOut();
      }
      _currentUser = null;
    });
  }

  Future<void> addSkill({
    required String title,
    required String description,
    required String category,
    required int credits,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('Please log in before adding a skill.');
    }

    await _runAction(() async {
      final skill = Skill(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        providerName: user.name,
        title: title.trim(),
        description: description.trim(),
        category: category,
        credits: credits,
        rating: 0,
        status: 'active',
      );

      if (_useFirebase) {
        await FirebaseFirestore.instance.collection('skills').add({
          ...skill.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        await loadSkills();
      } else {
        _skills = [skill, ..._skills];
      }
    });
  }

  Future<void> loadSkills() async {
    if (!_useFirebase) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('skills')
        .orderBy('createdAt', descending: true)
        .get();

    _skills = snapshot.docs
        .map((doc) => Skill.fromMap(doc.id, doc.data()))
        .where((skill) => skill.status == 'active')
        .toList();
  }

  Future<void> _handleAuthChanged(User? firebaseUser) async {
    _loading = true;
    notifyListeners();

    try {
      if (firebaseUser == null) {
        _currentUser = null;
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          _currentUser = AppUser.fromMap(doc.id, doc.data()!);
        } else {
          _currentUser = AppUser(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Skillora User',
            email: firebaseUser.email ?? '',
            bio: '',
            credits: 100,
            rating: 0,
          );
        }
      }

      await loadSkills();
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _error = _cleanFirebaseError(error);
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _cleanFirebaseError(Object error) {
    if (error is FirebaseAuthException) {
      return error.message ?? error.code;
    }
    return error.toString();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _skillsSubscription?.cancel();
    super.dispose();
  }
}

const _demoSkills = [
  Skill(
    id: 'design-1',
    userId: 'provider-1',
    providerName: 'Aarav Sharma',
    title: 'Logo & Poster Design',
    description: 'I can create clean social media posters and simple logos.',
    category: 'Design',
    credits: 20,
    rating: 4.7,
    status: 'active',
  ),
  Skill(
    id: 'dev-1',
    userId: 'provider-2',
    providerName: 'Maya Iyer',
    title: 'Flutter Basics Tutoring',
    description: 'Learn widgets, navigation, layout, and Firebase basics.',
    category: 'Development',
    credits: 30,
    rating: 4.9,
    status: 'active',
  ),
  Skill(
    id: 'academic-1',
    userId: 'provider-3',
    providerName: 'Rohan Mehta',
    title: 'Math Problem Solving',
    description: 'Algebra, calculus, and exam practice for students.',
    category: 'Academics',
    credits: 15,
    rating: 4.6,
    status: 'active',
  ),
];
