import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/medication/medication_model.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.loading;
  UserModel? _currentUser;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isPatient => _currentUser?.role == 'patient';
  bool get isDoctor => _currentUser?.role == 'doctor';

  AuthProvider() {
    debugPrint('🔧 AuthProvider initialized');
    // Listen to auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    debugPrint('🔄 Auth state changed');
    debugPrint('   Firebase User: ${firebaseUser?.email ?? "null"}');

    if (firebaseUser == null) {
      debugPrint('   ❌ No user logged in');
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      notifyListeners();
    } else {
      debugPrint('   ✅ User found: ${firebaseUser.uid}');
      await _loadUserData(firebaseUser.uid);
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      debugPrint('📥 Loading user data for: $uid');

      _status = AuthStatus.loading;
      notifyListeners();

      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        debugPrint('   ✅ User document found');
        final data = userDoc.data()!;
        debugPrint('   User data: $data');

        _currentUser = UserModel.fromJson(data);
        _status = AuthStatus.authenticated;

        debugPrint('   ✅ User loaded: ${_currentUser!.name}');
        debugPrint('   Role: ${_currentUser!.role}');
      } else {
        debugPrint('   ❌ User document not found in Firestore');
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
      }
    } catch (e, stackTrace) {
      debugPrint('   ❌ Error loading user data: $e');
      debugPrint('   Stack trace: $stackTrace');
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
    }
    notifyListeners();
  }

  // Sign In
  Future<bool> signIn(String email, String password) async {
    try {
      debugPrint('🔐 Attempting sign in for: $email');

      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Firebase auth successful');
      debugPrint('   User ID: ${credential.user!.uid}');

      await _loadUserData(credential.user!.uid);

      if (_currentUser != null) {
        debugPrint('✅ Sign in complete!');
        return true;
      } else {
        debugPrint('❌ User data load failed');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase auth error: ${e.code}');

      _status = AuthStatus.unauthenticated;

      if (e.code == 'user-not-found') {
        _errorMessage = 'البريد الإلكتروني غير مسجل';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'كلمة المرور غير صحيحة';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'البريد الإلكتروني غير صالح';
      } else if (e.code == 'invalid-credential') {
        _errorMessage = 'البيانات غير صحيحة';
      } else {
        _errorMessage = 'حدث خطأ في تسجيل الدخول: ${e.message}';
      }

      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'حدث خطأ غير متوقع';
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role, // 'patient' or 'doctor'
    String? phoneNumber,
    DateTime? dateOfBirth,
  }) async {
    try {
      debugPrint('📝 Attempting registration for: $email');

      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      // Create auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      debugPrint('✅ Firebase user created: ${user.uid}');

      // Update display name
      await user.updateDisplayName(name);
      debugPrint('✅ Display name updated');

      // Create user document
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        dateOfBirth: dateOfBirth,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('💾 Saving user document to Firestore...');
      await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
      debugPrint('✅ User document saved');

      await _loadUserData(user.uid);

      if (_currentUser != null) {
        debugPrint('✅ Registration complete!');
        return true;
      } else {
        debugPrint('❌ User data load failed after registration');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase auth error: ${e.code}');

      _status = AuthStatus.unauthenticated;

      if (e.code == 'email-already-in-use') {
        _errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل)';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'البريد الإلكتروني غير صالح';
      } else {
        _errorMessage = 'حدث خطأ في التسجيل: ${e.message}';
      }

      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'حدث خطأ غير متوقع: $e';
      notifyListeners();
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    debugPrint('👋 Signing out...');
    await _auth.signOut();
    _status = AuthStatus.unauthenticated;
    _currentUser = null;
    notifyListeners();
    debugPrint('✅ Signed out successfully');
  }

  // Update User Profile
  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    DateTime? dateOfBirth,
    List<String>? chronicConditions,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) {
      debugPrint('❌ Cannot update profile: no user logged in');
      return false;
    }

    try {
      debugPrint('📝 Updating profile for: ${_currentUser!.id}');

      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (dateOfBirth != null) {
        updates['dateOfBirth'] = dateOfBirth.toIso8601String();
      }
      if (chronicConditions != null) {
        updates['chronicConditions'] = chronicConditions;
      }
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(_currentUser!.id).update(updates);

      await _loadUserData(_currentUser!.id);
      debugPrint('✅ Profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      return false;
    }
  }

  // Connect to Doctor
  Future<bool> connectToDoctor(String doctorId) async {
    if (_currentUser == null || !isPatient) {
      debugPrint('❌ Cannot connect to doctor: not a patient');
      return false;
    }

    try {
      debugPrint('🔗 Connecting to doctor: $doctorId');

      // Verify doctor exists
      final doctorDoc =
      await _firestore.collection('users').doc(doctorId).get();

      if (!doctorDoc.exists || doctorDoc.data()?['role'] != 'doctor') {
        _errorMessage = 'الطبيب غير موجود';
        notifyListeners();
        debugPrint('❌ Doctor not found or not a doctor');
        return false;
      }

      // Update patient
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'connectedDoctorId': doctorId,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Add patient to doctor's patients list
      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('patients')
          .doc(_currentUser!.id)
          .set({
        'patientId': _currentUser!.id,
        'patientName': _currentUser!.name,
        'patientEmail': _currentUser!.email,
        'connectedAt': DateTime.now().toIso8601String(),
      });

      await _loadUserData(_currentUser!.id);
      debugPrint('✅ Connected to doctor successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error connecting to doctor: $e');
      _errorMessage = 'فشل الاتصال بالطبيب';
      notifyListeners();
      return false;
    }
  }

  // Clear Error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}