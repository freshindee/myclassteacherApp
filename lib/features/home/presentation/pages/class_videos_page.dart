import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/youtube_thumbnail_player.dart';
import '../../../../core/widgets/youtube_webview_player_page.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/grade_selector.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../domain/usecases/add_video.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../payment/domain/entities/payment.dart';
import '../../../payment/domain/usecases/get_user_payments.dart';

class ClassVideosPage extends StatefulWidget {
  const ClassVideosPage({super.key, this.embedInHomeShell = false});

  final bool embedInHomeShell;

  @override
  State<ClassVideosPage> createState() => _ClassVideosPageState();
}

class _ClassVideosPageState extends State<ClassVideosPage> {
  String? selectedGrade;
  String? selectedClassName;
  Map<String, dynamic>? selectedClassDoc;
  List<Map<String, dynamic>> _classesForGrade = [];
  bool _loadingClasses = false;
  List<Map<String, dynamic>> _classSubjectsForSelectedClass = [];
  bool _loadingClassSubjects = false;
  Map<String, String> _subjectIdToName = {};
  String? selectedSubject;

  List<dynamic> currentMonthPayments = [];
  bool paymentsLoading = false;
  bool paymentsLoaded = false;
  String? paymentsError;
  bool _paymentNotFoundForSelection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPayments());
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

  String _subjectDisplayName(Map<String, dynamic> classSubjectItem) {
    final subjectId = classSubjectItem['subject_id']?.toString() ??
        classSubjectItem['subjectId']?.toString() ??
        classSubjectItem['subject']?.toString();
    if (subjectId == null || subjectId.isEmpty) return '—';
    return _subjectIdToName[subjectId] ?? '—';
  }

  /// Allowed class_subject ids for the selected class (and selected subject if set).
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

  /// True if item is for selected class/subject and is paid (accessLevel not 'free'; empty treated as paid).
  bool _isPaidAndForSelectedClass(Map<String, dynamic> item, Set<String> allowedIds) {
    final access = (item['accessLevel'] ?? item['access_level'] ?? '').toString().trim().toLowerCase();
    if (access == 'free') return false;
    final csId = item['class_subject_id']?.toString()?.trim();
    if (csId == null || csId.isEmpty) return false;
    return allowedIds.contains(csId);
  }

  static int? _parseIntField(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString().trim());
  }

  static DateTime? _coerceDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) {
      if (v > 2000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v > 1000000000) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static int? _contentMonthFromItem(Map<String, dynamic> item) {
    const keys = [
      'month',
      'Month',
      'video_month',
      'videoMonth',
      'class_month',
      'classMonth',
      'published_month',
      'publishedMonth',
    ];
    for (final k in keys) {
      final n = _parseIntField(item[k]);
      if (n != null && n >= 1 && n <= 12) return n;
    }
    return null;
  }

  static int? _contentYearFromItem(Map<String, dynamic> item) {
    const keys = [
      'year',
      'Year',
      'video_year',
      'videoYear',
      'class_year',
      'classYear',
      'published_year',
      'publishedYear',
    ];
    for (final k in keys) {
      final n = _parseIntField(item[k]);
      if (n != null && n >= 1990 && n <= 2100) return n;
    }
    return null;
  }

  /// "මේ මාසේ වීඩියෝ" — only videos for this calendar month/year.
  ///
  /// Uses explicit **content** month/year fields, or a few semantically named date fields
  /// (`video_date`, `recording_date`, …). Does **not** use [created_at]/[uploaded_at]/generic
  /// [date] — those often track sync/import and would wrongly show old papers in the current month.
  bool _isVideoInCurrentMonth(Map<String, dynamic> item) {
    final now = DateTime.now();
    final month = _contentMonthFromItem(item);
    if (month != null) {
      final y = _contentYearFromItem(item) ?? now.year;
      return month == now.month && y == now.year;
    }

    for (final key in [
      'video_date',
      'videoDate',
      'recording_date',
      'recordingDate',
      'class_date',
      'classDate',
      'live_date',
      'liveDate',
      'scheduled_at',
      'scheduledAt',
    ]) {
      final dt = _coerceDateTime(item[key]);
      if (dt != null) {
        return dt.month == now.month && dt.year == now.year;
      }
    }
    return false;
  }

  /// Builds video list from local DB (school_content_videos). Returns Column of cards for use inside SingleChildScrollView.
  Widget _buildClassVideosContent(BuildContext context, String schoolId) {
    final allowedIds = _allowedClassSubjectIds();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentVideos(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading videos...'),
                ],
              ),
            ),
          );
        }
        final all = snapshot.data ?? [];
        final list = all
            .where((item) => _isPaidAndForSelectedClass(item, allowedIds))
            .where(_isVideoInCurrentMonth)
            .toList();
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No class videos for this subject this month',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: list.map((video) => _buildVideoCard(context, video)).toList(),
        );
      },
    );
  }

  /// Video list item cell: same design as FreeVideosPage — thumbnail, title, description, grade/subject tags, Watch Video.
  Widget _buildVideoCard(BuildContext context, Map<String, dynamic> video) {
    final title = video['title']?.toString().trim() ?? 'Video';
    final description = video['description']?.toString().trim() ?? '';
    final grade = video['grade']?.toString().trim();
    final subject = video['subject']?.toString().trim();
    final videoUrl = (video['video_url'] ?? video['youtube_url'])?.toString().trim() ?? '';
    final thumbUrl = video['thumb']?.toString().trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (videoUrl.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => YoutubeWebViewPlayerPage(
                  videoUrl: videoUrl,
                  title: title,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video URL is not available.')),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YoutubeThumbnailPlayer(
              videoUrl: videoUrl,
              thumbUrl: thumbUrl,
              title: title,
              aspectRatio: 16 / 9,
              borderRadius: 12,
              showSnackBarOnInvalidUrl: true,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if ((grade != null && grade.isNotEmpty) || (subject != null && subject.isNotEmpty)) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (grade != null && grade.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              grade.toUpperCase().startsWith('GRADE') ? grade : 'Grade $grade',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                            ),
                          ),
                        if (subject != null && subject.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              subject,
                              style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.play_circle_filled, size: 22, color: Colors.red[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Watch Video',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeClassSubjectSections(BuildContext context, String userId, String schoolId) {
    return Column(
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
              _paymentNotFoundForSelection = false;
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
                  _paymentNotFoundForSelection = false;
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
                      if (isSelected) _paymentNotFoundForSelection = false;
                    });
                    if (!isSelected) {
                      _onGradeSubjectSelected(userId, schoolId, context);
                    }
                  },
                );
              }).toList(),
            ),
        ],
      ],
    );
  }

  void _onGradeSubjectSelected(String userId, String schoolId, BuildContext context) {
    if (selectedGrade == null || selectedSubject == null) return;
    final grade = selectedGrade!;
    final subject = selectedSubject!;
    if (!paymentsLoaded) {
      setState(() => _paymentNotFoundForSelection = true);
      return;
    }
    final hasPayment = _hasPaymentForSelection();
    if (!hasPayment) {
      setState(() => _paymentNotFoundForSelection = true);
      return;
    }
    setState(() => _paymentNotFoundForSelection = false);
    // Videos load from local cache (getSchoolContentVideos); list updates on rebuild.
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
      final currentMonth = now.month;
      final currentYear = now.year;
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
            if (p.month != currentMonth || p.year != currentYear) return false;
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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      // User is not logged in, show a message and a login button
      return Scaffold(
        appBar: widget.embedInHomeShell
            ? null
            : AppBar(
                title: const Text('පන්ති වීඩියෝ නරබන්න '),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'You need to be logged in to view class videos.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Go to Login Page'),
              ),
            ],
          ),
        ),
      );
    }

    final userId = user.userId;
    final schoolId = user.teacherId ?? '';

    return Scaffold(
            appBar: widget.embedInHomeShell
                ? null
                : AppBar(
              title: const Text('පන්ති වීඩියෝ නරබන්න '),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              // actions: [
              //   IconButton(
              //     icon: const Icon(Icons.refresh),
              //     onPressed: () {
              //       context.read<ClassVideosBloc>().add(FetchClassVideos(userId: userId));
              //     },
              //   ),
              //   // Temporary test button
              //   IconButton(
              //     icon: const Icon(Icons.add),
              //     onPressed: () async {
              //       await _addTestVideo(context, userId, teacherId);
              //     },
              //   ),
              // ],
            ),
            body: Column(
              children: [
                if (paymentsLoading)
                  const LinearProgressIndicator(),
                if (paymentsError != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading payments: ${paymentsError ?? ""}', style: TextStyle(color: Colors.red)),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildGradeClassSubjectSections(context, userId, schoolId),
                          const SizedBox(height: 24),
                          if (selectedGrade == null || selectedSubject == null)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'වීඩියෝ නැරබීමට පන්තිය සහ විෂයය තෝරන්න',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else if (!paymentsLoaded)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: Text('Loading your payment data...')),
                            )
                          else if (_paymentNotFoundForSelection)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No payment found for this month and subject.\nPlease complete payment to view class videos.',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            _buildClassVideosContent(context, schoolId),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Future<void> _addTestVideo(BuildContext context, String userId, String schoolId) async {
    try {
      final addVideo = sl<AddVideo>();
      final params = AddVideoParams(
        title: 'Test Video - Flutter Tutorial',
        description: 'This is a test video to verify the video functionality works correctly.',
        youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        thumb: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        grade: 'Grade 10',
        subject: 'Computer Science',
        accessLevel: 'free',
      );

      final result = await addVideo(params);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add test video: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (video) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test video added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // Refresh video list from cache
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 