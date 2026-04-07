import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Device>> getDevices({String? category}) {
    Query query = _db
        .collection('devices')
        .where('isAvailable', isEqualTo: true);
    if (category != null && category != 'Alles') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map((d) => Device.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
    );
  }

  Future<void> addDevice(Device device) async {
    await _db.collection('devices').add(device.toMap());
  }

  Future<void> updateDevice(String id, Map<String, dynamic> data) async {
    await _db.collection('devices').doc(id).update(data);
  }

  Stream<QuerySnapshot> getMyReservations(String uid) {
    return _db
        .collection('reservations')
        .where('renterId', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot> getIncomingReservations(String uid) {
    return _db
        .collection('reservations')
        .where('ownerId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> updateReservationStatus(String id, String status) async {
    await _db.collection('reservations').doc(id).update({'status': status});
  }
}
