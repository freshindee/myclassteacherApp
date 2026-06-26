import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/school_cache_database.dart';

/// Result of app_config fetch on load: [data_version], [update_the_app], and optional
/// [appConfigDocs] for reuse in sync (avoids a second Firestore read).
class AppConfigLoadResult {
  const AppConfigLoadResult({
    this.dataVersion,
    this.updateTheApp = false,
    this.appConfigDocs,
  });
  final int? dataVersion;
  final bool updateTheApp;
  /// When present, sync() can use these instead of fetching app_config again.
  final List<Map<String, dynamic>>? appConfigDocs;
}

/// Fetches school master data from Firestore (schools/{schoolId}/...) and caches in SQLite.
/// Only for students app. Uses data_version in app_config to decide whether to refresh.
class SchoolCacheSyncService {
  SchoolCacheSyncService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Name of the version field in app_config (e.g. data_version or version).
  static const String dataVersionKey = 'data_version';

  /// Result of a single app_config fetch for app load (data_version + update_the_app).
  static AppConfigLoadResult emptyAppConfigLoadResult() =>
      AppConfigLoadResult(dataVersion: null, updateTheApp: false);

  /// Single API call: fetches app_config from Firestore and returns [data_version],
  /// [update_the_app], and [appConfigDocs] for reuse in sync (one read, no second get).
  Future<AppConfigLoadResult> fetchAppConfigOnLoad(String schoolId) async {
    if (schoolId.isEmpty) return emptyAppConfigLoadResult();
    final snap = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('app_config')
        .get();
    if (snap.docs.isEmpty) return emptyAppConfigLoadResult();
    int? dataVersion;
    bool updateTheApp = false;
    final appConfigDocs = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final data = _toJsonEncodable(doc.data());
      data['id'] = doc.id;
      appConfigDocs.add({'id': doc.id, 'data': jsonEncode(data)});
      final v = doc.data()[dataVersionKey];
      if (v != null && dataVersion == null) {
        if (v is int) dataVersion = v;
        else if (v is num) dataVersion = v.toInt();
      }
      if (!updateTheApp) {
        final d = doc.data();
        updateTheApp = d['update_the_app'] == true || d['updateTheApp'] == true;
      }
    }
    return AppConfigLoadResult(
      dataVersion: dataVersion,
      updateTheApp: updateTheApp,
      appConfigDocs: appConfigDocs.isEmpty ? null : appConfigDocs,
    );
  }

  /// Fetches bank_details array from schools/{schoolId}/app_config (first doc).
  /// Use this when cache is empty (e.g. payment page before sync completes).
  Future<List<String>> fetchBankDetailsFromAppConfig(String schoolId) async {
    final snap = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('app_config')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return [];
    final data = snap.docs.first.data();
    final list = data['bank_details'] as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  /// Fetches update_the_app from Firestore app_config (first doc). Prefer
  /// [fetchAppConfigOnLoad] when you need both data_version and update_the_app in one call.
  Future<bool> fetchUpdateTheAppFromFirestore(String schoolId) async {
    final result = await fetchAppConfigOnLoad(schoolId);
    return result.updateTheApp;
  }

  /// Syncs all cacheable collections for [schoolId]. If [studentId] is provided,
  /// enrollments, invoices, and payments are filtered to that student only.
  /// When [preFetchedAppConfigDocs] and [preFetchedRemoteVersion] are provided (e.g. from
  /// fetchAppConfigOnLoad), app_config is not fetched again from Firestore.
  /// If [force] is true, the sync runs even when local data_version >= remote.
  Future<bool> sync(
    String schoolId, {
    String? studentId,
    List<Map<String, dynamic>>? preFetchedAppConfigDocs,
    int? preFetchedRemoteVersion,
    bool force = false,
  }) async {
    final schoolRef = _firestore.collection('schools').doc(schoolId);

    int? remoteVersion;
    List<Map<String, dynamic>> appConfigDocs;
    final usePreFetched = preFetchedAppConfigDocs != null &&
        preFetchedAppConfigDocs.isNotEmpty &&
        preFetchedRemoteVersion != null;

    if (usePreFetched) {
      remoteVersion = preFetchedRemoteVersion;
      appConfigDocs = preFetchedAppConfigDocs;
    } else {
      final appConfigSnap = await schoolRef.collection('app_config').get();
      appConfigDocs = <Map<String, dynamic>>[];
      for (final doc in appConfigSnap.docs) {
        final data = _toJsonEncodable(doc.data());
        data['id'] = doc.id;
        appConfigDocs.add({'id': doc.id, 'data': jsonEncode(data)});
        final v = doc.data()[dataVersionKey];
        if (v != null) {
          if (v is int) remoteVersion = v;
          else if (v is num) remoteVersion = v.toInt();
        }
      }
    }

    final localVersion = await SchoolCacheDatabase.getDataVersion(schoolId);
    if (!force &&
        localVersion != null &&
        remoteVersion != null &&
        localVersion >= remoteVersion &&
        appConfigDocs.isNotEmpty) {
      return false; // already up to date
    }

    // 2. Use remoteVersion as new version (or 0 if missing)
    final newVersion = remoteVersion ?? 0;

    // 3. Fetch all collections
    final collections = [
      'class_subjects',
      'classes',
      'modules',
      'subjects',
      'teachers',
      'timetables',
    ];

    await SchoolCacheDatabase.replaceCollection(
        schoolId, 'app_config', appConfigDocs);

    for (final name in collections) {
      final snap = await schoolRef.collection(name).get();
      final docs = snap.docs
          .map((d) => {
                'id': d.id,
                'data': jsonEncode(_toJsonEncodable(d.data())),
              })
          .toList();
      await SchoolCacheDatabase.replaceCollection(schoolId, name, docs);
    }

    // Enrollments: all or filtered by student_id
    final enrollmentsSnap = studentId != null
        ? await schoolRef
            .collection('enrollments')
            .where('student_id', isEqualTo: studentId)
            .get()
        : await schoolRef.collection('enrollments').get();
    final enrollmentDocs = enrollmentsSnap.docs
        .map((d) => {
              'id': d.id,
              'data': jsonEncode(_toJsonEncodable(d.data())),
            })
        .toList();
    await SchoolCacheDatabase.replaceCollection(
        schoolId, 'enrollments', enrollmentDocs);

    // Invoices: all or filtered by student_id
    final invoicesSnap = studentId != null
        ? await schoolRef
            .collection('invoices')
            .where('student_id', isEqualTo: studentId)
            .get()
        : await schoolRef.collection('invoices').get();
    final invoiceDocs = invoicesSnap.docs
        .map((d) => {
              'id': d.id,
              'data': jsonEncode(_toJsonEncodable(d.data())),
            })
        .toList();
    await SchoolCacheDatabase.replaceCollection(
        schoolId, 'invoices', invoiceDocs);

    // Payments: all or filtered by student_id
    final paymentsSnap = studentId != null
        ? await schoolRef
            .collection('payments')
            .where('student_id', isEqualTo: studentId)
            .get()
        : await schoolRef.collection('payments').get();
    final paymentDocs = paymentsSnap.docs
        .map((d) => {
              'id': d.id,
              'data': jsonEncode(_toJsonEncodable(d.data())),
            })
        .toList();
    await SchoolCacheDatabase.replaceCollection(
        schoolId, 'payments', paymentDocs);

    await SchoolCacheDatabase.setDataVersion(schoolId, newVersion);
    return true;
  }

  static Map<String, dynamic> _toJsonEncodable(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      if (value is Map) {
        return MapEntry(
            key, _toJsonEncodable(Map<String, dynamic>.from(value)));
      }
      if (value is List) {
        return MapEntry(
          key,
          value.map((e) {
            if (e is Timestamp) return e.toDate().toIso8601String();
            if (e is Map) return _toJsonEncodable(Map<String, dynamic>.from(e));
            return e;
          }).toList(),
        );
      }
      return MapEntry(key, value);
    });
  }
}
