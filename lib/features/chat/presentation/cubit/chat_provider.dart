import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Queries the `users` collection for all doctors.
  Future<List<Map<String, dynamic>>> getAvailableDoctors() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Error getting available doctors: $e');
      return [];
    }
  }

  /// Requests a consultation with a doctor.
  /// Creates a chat document with status 'pending'.
  Future<bool> assignDoctor(String patientId, String doctorId) async {
    try {
      final patientDoc =
          await _firestore.collection('users').doc(patientId).get();
      final doctorDoc =
          await _firestore.collection('users').doc(doctorId).get();

      final patientName = patientDoc.data()?['name'] ?? '';
      final doctorName = doctorDoc.data()?['name'] ?? '';

      final chatId = getChatId(patientId, doctorId);

      // Create the chat document with pending status.
      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'status': 'pending', // <--- New status field
        'lastMessage': 'طلب استشارة جديد',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': patientId,
      });

      debugPrint('Consultation request sent from $patientId to $doctorId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error requesting consultation: $e');
      return false;
    }
  }

  /// Gets all pending requests for a doctor
  Stream<QuerySnapshot> getPendingRequests(String doctorId) {
    return _firestore
        .collection('chats')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Accepts a consultation request
  Future<void> acceptRequest(String chatId, String patientId, String patientName, String doctorId) async {
    try {
      // 1. Update chat status
      await _firestore.collection('chats').doc(chatId).update({
        'status': 'accepted',
      });

      // 2. Update patient's connectedDoctorId (optional, depending on your logic, but good for primary doctor)
      await _firestore.collection('users').doc(patientId).update({
        'connectedDoctorId': doctorId,
      });

      // 3. Add to doctor's patients subcollection
      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .set({
        'patientId': patientId,
        'patientName': patientName,
        'assignedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error accepting request: $e');
    }
  }

  /// Rejects a consultation request
  Future<void> rejectRequest(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'status': 'rejected',
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting request: $e');
    }
  }

  /// Gets the connected doctor info for a given patient.
  Future<Map<String, dynamic>?> getConnectedDoctor(String patientId) async {
    try {
      final patientDoc =
          await _firestore.collection('users').doc(patientId).get();
      final connectedDoctorId = patientDoc.data()?['connectedDoctorId'];

      if (connectedDoctorId == null || connectedDoctorId.isEmpty) {
        debugPrint('No connected doctor for patient $patientId');
        return null;
      }

      final doctorDoc =
          await _firestore.collection('users').doc(connectedDoctorId).get();

      if (!doctorDoc.exists) {
        debugPrint('Connected doctor document not found');
        return null;
      }

      return {'id': doctorDoc.id, ...doctorDoc.data()!};
    } catch (e) {
      debugPrint('Error getting connected doctor: $e');
      return null;
    }
  }

  /// Returns a stream of chats where the given doctorId is the doctor,
  /// ordered by lastMessageTime descending.
  Stream<QuerySnapshot> getMyPatients(String doctorId) {
    return _firestore
        .collection('chats')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'accepted')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Returns a stream of chats where the given patientId is the patient,
  /// ordered by lastMessageTime descending.
  Stream<QuerySnapshot> getMyDoctors(String patientId) {
    return _firestore
        .collection('chats')
        .where('patientId', isEqualTo: patientId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Sends a message to the specified chat and updates the parent chat
  /// document with the latest message info.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String text,
    String type = 'text',
    Map<String, dynamic>? conflictData,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();

      // Add the message to the messages subcollection.
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'senderRole': senderRole,
        'text': text,
        'type': type,
        'timestamp': timestamp,
        'conflictData': conflictData,
      });

      // Update the parent chat document.
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
      });

      debugPrint('Message sent in chat $chatId');
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  /// Returns a stream of messages for a chat, ordered by timestamp ascending.
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Sends a conflict alert message to the doctor-patient chat.
  Future<void> sendConflictAlert({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String medicationName,
    required List<Map<String, dynamic>> interactions,
  }) async {
    try {
      final chatId = getChatId(patientId, doctorId);
      final conflictData = {
        'medicationName': medicationName,
        'interactions': interactions,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await sendMessage(
        chatId: chatId,
        senderId: patientId,
        senderRole: 'patient',
        text: '⚠️ تنبيه تعارض دوائي: $medicationName',
        type: 'conflict',
        conflictData: conflictData,
      );

      debugPrint('Conflict alert sent for medication: $medicationName');
    } catch (e) {
      debugPrint('Error sending conflict alert: $e');
    }
  }

  /// Returns the chat ID derived from patient and doctor IDs.
  String getChatId(String patientId, String doctorId) {
    return '${patientId}_$doctorId';
  }
}
