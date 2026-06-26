import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/grade_selector.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../payment/domain/entities/payment.dart';
import '../../../payment/domain/usecases/get_user_payments.dart';

class TodayClassesPage extends StatefulWidget {
  const TodayClassesPage({super.key, this.embedInHomeShell = false});

  final bool embedInHomeShell;

  @override
  State<TodayClassesPage> createState() => _TodayClassesPageState();
}

class _TodayClassesPageState extends State<TodayClassesPage> {
  String? _schoolId;
  String? selectedGrade;
  String? selectedClassName;
  Map<String, dynamic>? selectedClassDoc;
  List<Map<String, dynamic>> _classesForGrade = [];
  bool _loadingClasses = false;
  List<Map<String, dynamic>> _classSubjectsForSelectedClass = [];
  bool _loadingClassSubjects = false;
  Map<String, String> _subjectIdToName = {};
  String? selectedSubject;
  bool _schoolIdLoading = true;

  List<dynamic> currentMonthPayments = [];
  bool paymentsLoading = false;
  bool paymentsLoaded = false;
  String? paymentsError;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPayments());
  }

  Future<void> _loadSchoolId() async {
    final user = await UserSessionService.getCurrentUser();
    if (mounted) {
      setState(() {
        _schoolId = user?.teacherId ?? '';
        _schoolIdLoading = false;
      });
    }
  }

  String _subjectDisplayName(Map<String, dynamic> classSubjectItem) {
    final subjectId = classSubjectItem['subject_id']?.toString() ??
        classSubjectItem['subjectId']?.toString() ??
        classSubjectItem['subject']?.toString();
    if (subjectId == null || subjectId.isEmpty) return '—';
    return _subjectIdToName[subjectId] ?? '—';
  }

  String? _getSelectedClassSubjectId() {
    if (selectedSubject == null || selectedSubject!.isEmpty) return null;
    for (final item in _classSubjectsForSelectedClass) {
      if (_subjectDisplayName(item) == selectedSubject) {
        final id = item['id']?.toString();
        if (id != null && id.isNotEmpty) return id;
        return null;
      }
    }
    return null;
  }

  static bool _isPaidStatus(String status) {
    final s = status.toLowerCase();
    return s == 'paid' || s == 'approved' || s == 'completed';
  }

  bool _hasPaymentForSelection() {
    if (!paymentsLoaded || selectedGrade == null || selectedSubject == null) return false;
    final now = DateTime.now();
    final grade = selectedGrade!;
    final subject = selectedSubject!;
    final classSubjectId = _getSelectedClassSubjectId();
    for (final p in currentMonthPayments) {
      if (p is! Payment) continue;
      if (p.month != now.month || p.year != now.year) continue;
      if (!_isPaidStatus(p.status)) continue;
      if (classSubjectId != null && p.classSubjectId != null && p.classSubjectId == classSubjectId) return true;
      if (p.grade == grade && p.subject == subject) return true;
    }
    return false;
  }

  Future<void> _fetchPayments() async {
    setState(() {
      paymentsLoading = true;
      paymentsError = null;
    });
    try {
      final authState = context.read<AuthBloc>().state;
      final user = authState.user;
      if (user == null) return;
      final userId = user.userId;
      final schoolId = user.teacherId ?? '';
      final now = DateTime.now();
      final getUserPayments = sl.get<GetUserPayments>();
      final params = GetUserPaymentsParams(userId: userId, schoolId: schoolId);
      final result = await getUserPayments(params);
      result.fold(
        (failure) {
          setState(() {
            paymentsError = failure.message;
            paymentsLoading = false;
            paymentsLoaded = false;
          });
        },
        (payments) {
          final filtered = payments.where((p) {
            if (p.month != now.month || p.year != now.year) return false;
            return _isPaidStatus(p.status);
          }).toList();
          setState(() {
            currentMonthPayments = filtered;
            paymentsLoading = false;
            paymentsLoaded = true;
          });
        },
      );
    } catch (e) {
      setState(() {
        paymentsError = e.toString();
        paymentsLoading = false;
        paymentsLoaded = false;
      });
    }
  }

  Set<String> _allowedClassSubjectIds() {
    final allowed = <String>{};
    for (final doc in _classSubjectsForSelectedClass) {
      if (selectedSubject != null && selectedSubject!.isNotEmpty) {
        if (_subjectDisplayName(doc) != selectedSubject) continue;
      }
      final id = doc['id']?.toString();
      if (id != null && id.isNotEmpty) allowed.add(id);
    }
    return allowed;
  }

  bool _isFreeAndForSelectedClass(Map<String, dynamic> item, Set<String> allowedIds) {
    final access = (item['accessLevel'] ?? item['access_level'] ?? '').toString().trim().toLowerCase();
    if (access.isNotEmpty && access != 'free') return false;
    final csId = item['class_subject_id']?.toString()?.trim();
    if (csId == null || csId.isEmpty) return false;
    return allowedIds.contains(csId);
  }

  bool _isPaidAndForSelectedClass(Map<String, dynamic> item, Set<String> allowedIds) {
    final access = (item['accessLevel'] ?? item['access_level'] ?? '').toString().trim().toLowerCase();
    if (access == 'free') return false;
    final csId = item['class_subject_id']?.toString()?.trim();
    if (csId == null || csId.isEmpty) return false;
    return allowedIds.contains(csId);
  }

  Widget _buildClassesFromCache(BuildContext context, String schoolId) {
    final allowedIds = _allowedClassSubjectIds();
    final hasPayment = _hasPaymentForSelection();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentZoomClasses(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final freeList = all.where((item) => _isFreeAndForSelectedClass(item, allowedIds)).toList();
        final paidList = hasPayment
            ? all.where((item) => _isPaidAndForSelectedClass(item, allowedIds)).toList()
            : <Map<String, dynamic>>[];
        final combined = [...freeList, ...paidList];
        if (combined.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_call, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No classes for this class/subject'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: combined.length,
          itemBuilder: (context, index) {
            final zoom = combined[index];
            final isFree = _isFreeAndForSelectedClass(zoom, allowedIds);
            return _buildClassListItem(context, zoom, isFree: isFree);
          },
        );
      },
    );
  }

  /// Same class cell design as FreeVideosPage: card with subject/title, grade, teacher, time, Zoom ID & password, Share Link & Join Now.
  /// Uses zoom_classes DB: title, zoom_meeting_id, zoom_password, join_url, class_day, start_time, end_time (+ subject, grade, teacher if from API).
  Widget _buildClassListItem(BuildContext context, Map<String, dynamic> zoom, {bool isFree = true}) {
    final title = zoom['title']?.toString().trim() ?? 'Class';
    final subject = zoom['subject']?.toString().trim();
    final grade = zoom['grade']?.toString().trim();
    final teacher = zoom['teacher']?.toString().trim();
    final classDay = zoom['class_day']?.toString().trim() ?? '';
    final startTime = zoom['start_time']?.toString().trim() ?? '';
    final endTime = zoom['end_time']?.toString().trim() ?? '';
    final zoomMeetingId = zoom['zoom_meeting_id']?.toString().trim() ?? '';
    final zoomPassword = zoom['zoom_password']?.toString().trim() ?? '';
    final joinUrl = zoom['join_url']?.toString().trim() ?? '';

    final timeParts = <String>[];
    if (startTime.isNotEmpty || endTime.isNotEmpty) {
      timeParts.add(startTime);
      if (endTime.isNotEmpty) timeParts.add(endTime);
    }
    final timeStr = timeParts.join(' - ');
    final displaySubject = subject?.isNotEmpty == true ? subject! : title;
    final displayGrade = grade?.isNotEmpty == true ? (grade!.toUpperCase().startsWith('GRADE') ? grade : 'Grade $grade') : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    displaySubject,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isFree ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isFree ? 'Free' : 'Paid',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFree ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (displayGrade.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                displayGrade,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],
            if (teacher != null && teacher.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Teacher: $teacher', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
            ],
            if (timeStr.isNotEmpty || classDay.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Time: ${[classDay, timeStr].where((s) => s.isNotEmpty).join(' • ')}',
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],
            if (zoomMeetingId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.video_call, size: 22, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Zoom class ID: $zoomMeetingId',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (zoomPassword.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, size: 22, color: Colors.orange.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Password: $zoomPassword',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (joinUrl.isNotEmpty) {
                        Share.share(joinUrl, subject: title);
                      }
                    },
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text('Share Link', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (joinUrl.isNotEmpty) {
                        launchUrl(Uri.parse(joinUrl), mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Join Now', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolIdLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final schoolId = _schoolId ?? '';
    if (schoolId.isEmpty) {
      return Scaffold(
        appBar: widget.embedInHomeShell
            ? null
            : AppBar(
                title: const Text("අද දවසේ පන්ති"),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
        body: const Center(child: Text('School not found. Please login again.')),
      );
    }
    return Scaffold(
      appBar: widget.embedInHomeShell
          ? null
          : AppBar(
              title: const Text("අද දවසේ පන්ති"),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
      body: Column(
        children: [
          if (paymentsLoading) const LinearProgressIndicator(),
          if (paymentsError != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Payment load: $paymentsError', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GradeSelector(
                      value: selectedGrade,
                      label: 'පන්තිය',
                      hint: 'පන්තිය තෝරන්න',
                      onGradeSelected: (value) async {
                        setState(() {
                          selectedGrade = value;
                          selectedClassName = null;
                          selectedClassDoc = null;
                          selectedSubject = null;
                          _classesForGrade = [];
                          _classSubjectsForSelectedClass = [];
                          _subjectIdToName = {};
                        });
                        if (value != null && value.isNotEmpty && schoolId.isNotEmpty) {
                          setState(() => _loadingClasses = true);
                          final cache = sl<SchoolCacheService>();
                          final list = await cache.getClassesByGradeNumber(schoolId, value);
                          if (mounted) {
                            setState(() {
                              _classesForGrade = list;
                              _loadingClasses = false;
                              if (list.length == 1) {
                                selectedClassDoc = list.first;
                                selectedClassName = SchoolCacheService.classDisplayName(list.first, value);
                              }
                            });
                            if (list.length == 1 && list.first.isNotEmpty && schoolId.isNotEmpty) {
                              setState(() => _loadingClassSubjects = true);
                              final cache = sl<SchoolCacheService>();
                              final doc = list.first;
                              final classId = doc['id']?.toString() ?? '';
                              final cName = SchoolCacheService.classDisplayName(doc, value);
                              final subjects = await cache.getClassSubjectsForClass(schoolId, classId, cName);
                              final subjectDocs = await cache.getSubjects(schoolId);
                              final idToName = <String, String>{};
                              for (final s in subjectDocs) {
                                final id = s['id']?.toString();
                                if (id == null) continue;
                                final name = s['subject'] ?? s['name'] ?? s['title'];
                                if (name != null && name.toString().trim().isNotEmpty) {
                                  idToName[id] = name.toString().trim();
                                }
                              }
                              if (mounted) {
                                setState(() {
                                  _classSubjectsForSelectedClass = subjects;
                                  _subjectIdToName = idToName;
                                  _loadingClassSubjects = false;
                                });
                              }
                            }
                          }
                        }
                      },
                    ),
                    if (selectedGrade != null && selectedGrade!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      if (_loadingClasses)
                        const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
                      else if (_classesForGrade.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'මෙම පන්තිය සඳහා පන්ති නොමැත',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedClassName != null &&
                                  _classesForGrade.any((c) =>
                                      SchoolCacheService.classDisplayName(c, selectedGrade!) == selectedClassName)
                              ? selectedClassName
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'පන්තියේ නම',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('පන්තිය තෝරන්න'),
                          items: _classesForGrade.map((c) {
                            final name = SchoolCacheService.classDisplayName(c, selectedGrade!);
                            return DropdownMenuItem<String>(value: name, child: Text(name));
                          }).toList(),
                          onChanged: (value) async {
                            final className = value ?? '';
                            final doc = _classesForGrade.cast<Map<String, dynamic>>().firstWhere(
                                  (c) => SchoolCacheService.classDisplayName(c, selectedGrade!) == className,
                                  orElse: () => <String, dynamic>{},
                                );
                            setState(() {
                              selectedClassName = className;
                              selectedClassDoc = doc.isNotEmpty ? doc : null;
                              selectedSubject = null;
                              _classSubjectsForSelectedClass = [];
                              _subjectIdToName = {};
                            });
                            if (doc.isNotEmpty && schoolId.isNotEmpty) {
                              setState(() => _loadingClassSubjects = true);
                              final cache = sl<SchoolCacheService>();
                              final classId = doc['id']?.toString() ?? '';
                              final list = await cache.getClassSubjectsForClass(schoolId, classId, className);
                              final subjectDocs = await cache.getSubjects(schoolId);
                              final idToName = <String, String>{};
                              for (final s in subjectDocs) {
                                final id = s['id']?.toString();
                                if (id == null) continue;
                                final name = s['subject'] ?? s['name'] ?? s['title'];
                                if (name != null && name.toString().trim().isNotEmpty) {
                                  idToName[id] = name.toString().trim();
                                }
                              }
                              if (mounted) {
                                setState(() {
                                  _classSubjectsForSelectedClass = list;
                                  _subjectIdToName = idToName;
                                  _loadingClassSubjects = false;
                                });
                              }
                            }
                          },
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (selectedClassDoc != null && selectedClassName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'විෂය තෝරන්න',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_loadingClassSubjects)
                        const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
                      else if (_classSubjectsForSelectedClass.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'මෙම පන්තිය සඳහා විෂය නොමැත',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _classSubjectsForSelectedClass.map((item) {
                            final name = _subjectDisplayName(item);
                            final isSelected = selectedSubject == name;
                            return FilterChip(
                              label: Text(name),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  selectedSubject = isSelected ? null : name;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: (selectedGrade == null || selectedSubject == null)
                  ? const Center(child: Text('වීඩියෝ පන්ති නැරබීමට පන්තිය සහ විෂයය තෝරන්න'))
                  : (!paymentsLoaded)
                      ? const Center(child: Text('Loading your payment data...'))
                      : _buildClassesFromCache(context, schoolId),
            ),
          ],
        ),
    );
  }

  Future<void> _joinNow(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not join class'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 