import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/youtube_thumbnail_player.dart';
import '../../../../core/widgets/youtube_webview_player_page.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/grade_selector.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../../../core/services/school_content_service.dart';
import '../../domain/entities/video.dart';
import 'free_videos_bloc.dart';
import '../../../../core/services/user_session_service.dart';

class FreeVideosPage extends StatefulWidget {
  const FreeVideosPage({super.key, this.embedInHomeShell = false});

  final bool embedInHomeShell;

  @override
  State<FreeVideosPage> createState() => _FreeVideosPageState();
}

class _FreeVideosPageState extends State<FreeVideosPage> {
  String? selectedGrade;
  String? schoolId;
  String? selectedClassName;
  Map<String, dynamic>? selectedClassDoc;
  List<Map<String, dynamic>> _classesForGrade = [];
  bool _loadingClasses = false;
  List<Map<String, dynamic>> _classSubjectsForSelectedClass = [];
  bool _loadingClassSubjects = false;
  Map<String, String> _subjectIdToName = {};
  String? selectedSubject;
  bool _schoolIdLoading = true;
  static const int _tabVideos = 0;
  static const int _tabNotes = 1;
  static const int _tabClasses = 2;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    final user = await UserSessionService.getCurrentUser();
    if (mounted) {
      setState(() {
        schoolId = user?.teacherId ?? '';
        _schoolIdLoading = false;
      });
      // Ensure school content (videos/notes/classes) is fetched when opening FreeVideosPage.
      // Throttled by SchoolContentService, so this won't spam the API or hurt UX.
      if (schoolId != null && schoolId!.isNotEmpty) {
        sl<SchoolContentService>().fetchSchoolContentIfNeeded(schoolId!);
      }
    }
  }

  String _subjectDisplayName(Map<String, dynamic> classSubjectItem) {
    final subjectId = classSubjectItem['subject_id']?.toString() ??
        classSubjectItem['subjectId']?.toString() ??
        classSubjectItem['subject']?.toString();
    if (subjectId == null || subjectId.isEmpty) return '—';
    return _subjectIdToName[subjectId] ?? '—';
  }

  /// Allowed class_subject ids for filtering: all for selected class, or only for selectedSubject if set.
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

  /// True if item is for selected class/subject and is free (accessLevel/access_level 'free', or missing/empty treated as free).
  bool _isFreeAndForSelectedClass(
    Map<String, dynamic> item,
    Set<String> allowedIds,
  ) {
    final access = (item['accessLevel'] ?? item['access_level'] ?? '').toString().trim().toLowerCase();
    if (access.isNotEmpty && access != 'free') return false;
    final csId = item['class_subject_id']?.toString()?.trim();
    if (csId == null || csId.isEmpty) return false;
    return allowedIds.contains(csId);
  }

  void _loadVideosForGrade(String grade) {
    if (schoolId == null || schoolId!.isEmpty) return;
    context.read<FreeVideosBloc>().add(LoadFreeVideosByGrade(schoolId!, grade));
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolIdLoading) {
      return Scaffold(
        appBar: widget.embedInHomeShell
            ? null
            : AppBar(
                title: const Text('Free Videos'),
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (schoolId == null || schoolId!.isEmpty) {
      return Scaffold(
        appBar: widget.embedInHomeShell
            ? null
            : AppBar(
                title: const Text('Free Videos'),
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'School not found. Please login again.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: widget.embedInHomeShell
          ? null
          : AppBar(
              title: const Text('Free Videos'),
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGradeClassSubjectSections(context),
              if (selectedClassDoc != null && selectedClassName != null) ...[
                const SizedBox(height: 16),
                _buildTabBar(context),
                const SizedBox(height: 16),
                _buildTabContent(context),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: selectedGrade != null && schoolId != null && schoolId!.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                context.read<FreeVideosBloc>().add(LoadFreeVideosByGrade(schoolId!, selectedGrade!));
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  Widget _buildGradeClassSubjectSections(BuildContext context) {
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
                        _classesForGrade = [];
                        _classSubjectsForSelectedClass = [];
                        _subjectIdToName = {};
                      });
                      if (value != null && value.isNotEmpty && schoolId!.isNotEmpty) {
                        setState(() => _loadingClasses = true);
                        final cache = sl<SchoolCacheService>();
                        final list = await cache.getClassesByGradeNumber(schoolId!, value);
                        if (mounted) {
                          setState(() {
                            _classesForGrade = list;
                            _loadingClasses = false;
                            if (list.length == 1) {
                              selectedClassDoc = list.first;
                              selectedClassName = SchoolCacheService.classDisplayName(list.first, value);
                            }
                          });
                          if (list.length == 1 && list.first.isNotEmpty && schoolId!.isNotEmpty) {
                            setState(() => _loadingClassSubjects = true);
                            final cache = sl<SchoolCacheService>();
                            final doc = list.first;
                            final classId = doc['id']?.toString() ?? '';
                            final cName = SchoolCacheService.classDisplayName(doc, value);
                            final subjects = await cache.getClassSubjectsForClass(schoolId!, classId, cName);
                            final subjectDocs = await cache.getSubjects(schoolId!);
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
                          _loadVideosForGrade(value);
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
                          if (doc.isNotEmpty && schoolId!.isNotEmpty) {
                            setState(() => _loadingClassSubjects = true);
                            final cache = sl<SchoolCacheService>();
                            final classId = doc['id']?.toString() ?? '';
                            final list = await cache.getClassSubjectsForClass(schoolId!, classId, className);
                            final subjectDocs = await cache.getSubjects(schoolId!);
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
                      'විෂය',
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
        ],
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Videos'),
            selected: _selectedTabIndex == _tabVideos,
            onSelected: (_) => setState(() => _selectedTabIndex = _tabVideos),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Text('Notes'),
            selected: _selectedTabIndex == _tabNotes,
            onSelected: (_) => setState(() => _selectedTabIndex = _tabNotes),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Text('Classes'),
            selected: _selectedTabIndex == _tabClasses,
            onSelected: (_) => setState(() => _selectedTabIndex = _tabClasses),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context) {
    if (_selectedTabIndex == _tabVideos) return _buildVideosTabContent(context);
    if (_selectedTabIndex == _tabNotes) return _buildNotesTabContent(context);
    return _buildClassesTabContent(context);
  }

  Widget _buildVideosTabContent(BuildContext context) {
    if (schoolId == null || schoolId!.isEmpty) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('School not found.')));
    }
    if (selectedGrade == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('වීඩියෝ නැරබීමට පන්තිය තෝරන්න.')),
      );
    }
    final allowedIds = _allowedClassSubjectIds();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentVideos(schoolId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapshot.data ?? [];
        final list = all.where((item) => _isFreeAndForSelectedClass(item, allowedIds)).toList();
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No free videos for this class/subject'),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: list.map((video) => _buildVideoListItem(context, video)).toList(),
        );
      },
    );
  }

  Widget _buildNotesTabContent(BuildContext context) {
    if (schoolId == null || schoolId!.isEmpty) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('School not found.')));
    }
    final allowedIds = _allowedClassSubjectIds();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentPdfNotes(schoolId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapshot.data ?? [];
        final list = all.where((item) => _isFreeAndForSelectedClass(item, allowedIds)).toList();
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No free notes for this class/subject'),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: list.map((note) => _buildNoteListItem(context, note)).toList(),
        );
      },
    );
  }

  /// Notes list item cell: card with Grade pill, title, description, View & Download buttons.
  /// Uses pdf_notes DB: title, description, pdf_url, grade (if from API).
  Widget _buildNoteListItem(BuildContext context, Map<String, dynamic> note) {
    final title = note['title']?.toString().trim() ?? 'Note';
    final description = note['description']?.toString().trim() ?? '';
    final pdfUrl = (note['pdf_url'] ?? note['file_url'])?.toString().trim() ?? '';
    final grade = note['grade']?.toString().trim();
    final gradeNum = grade?.replaceAll(RegExp(r'[^0-9]'), '')?.trim() ?? '';
    final displayGradeLabel = gradeNum.isNotEmpty ? 'Grade: $gradeNum' : (grade?.isNotEmpty == true ? 'Grade: ${grade!.replaceFirst(RegExp(r'^Grade\s*', caseSensitive: false), '').trim()}' : '');

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
            if (displayGradeLabel.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayGradeLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (pdfUrl.isNotEmpty) {
                        launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 20),
                    label: const Text('View', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (pdfUrl.isNotEmpty) {
                        launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text('Download', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesTabContent(BuildContext context) {
    if (schoolId == null || schoolId!.isEmpty) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('School not found.')));
    }
    final allowedIds = _allowedClassSubjectIds();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentZoomClasses(schoolId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapshot.data ?? [];
        final list = all.where((item) => _isFreeAndForSelectedClass(item, allowedIds)).toList();
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_call, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No free classes for this class/subject'),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: list.map((zoom) => _buildClassListItem(context, zoom)).toList(),
        );
      },
    );
  }

  /// Classes list item cell: card with subject/title, grade, teacher, time, Zoom ID & password boxes, Share Link & Join Now.
  /// Uses zoom_classes DB fields: title, zoom_meeting_id, zoom_password, join_url, class_day, start_time, end_time (+ subject, grade, teacher if from API).
  Widget _buildClassListItem(BuildContext context, Map<String, dynamic> zoom) {
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
            Text(
              displaySubject,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildVideosTab(BuildContext context) {
    if (schoolId == null || schoolId!.isEmpty) {
      return const Center(child: Text('School not found.'));
    }
    if (selectedGrade == null) {
      return const Center(
        child: Text('වීඩියෝ නැරබීමට පන්තිය තෝරන්න.'),
      );
    }
    final allowedIds = _allowedClassSubjectIds();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentVideos(schoolId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final list = all.where((item) => _isFreeAndForSelectedClass(item, allowedIds)).toList();
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No free videos for this class/subject'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return _buildVideoListItem(context, list[index]);
          },
        );
      },
    );
  }

  Widget _buildNotesTab(BuildContext context) {
    if (schoolId == null || schoolId!.isEmpty) {
      return const Center(child: Text('School not found.'));
    }
    final allowedIds = _allowedClassSubjectIds();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentPdfNotes(schoolId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final list = all.where((item) => _isFreeAndForSelectedClass(item, allowedIds)).toList();
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No free notes for this class/subject'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final note = list[index];
            final title = note['title']?.toString() ?? 'Note';
            final pdfUrl = (note['file_url'] ?? note['pdf_url'])?.toString() ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  if (pdfUrl.isNotEmpty) {
                    launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClassesTab(BuildContext context) {
    if (schoolId == null || schoolId!.isEmpty) {
      return const Center(child: Text('School not found.'));
    }
    final allowedIds = _allowedClassSubjectIds();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentZoomClasses(schoolId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final list = all.where((item) => _isFreeAndForSelectedClass(item, allowedIds)).toList();
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_call, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No free classes for this class/subject'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final zoom = list[index];
            final title = zoom['title']?.toString() ?? 'Class';
            final joinUrl = zoom['join_url']?.toString() ?? '';
            final day = zoom['class_day']?.toString() ?? '';
            final startTime = zoom['start_time']?.toString() ?? '';
            final endTime = zoom['end_time']?.toString() ?? '';
            final timeStr = [day, startTime, endTime].where((s) => s.isNotEmpty).join(' • ');
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.video_call, color: Colors.blue),
                title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: timeStr.isNotEmpty ? Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
                onTap: () {
                  if (joinUrl.isNotEmpty) {
                    launchUrl(Uri.parse(joinUrl), mode: LaunchMode.externalApplication);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Video list item cell: thumbnail on top, title, description, grade/subject tags, Watch Video CTA.
  /// Uses DB fields: title, description, grade, subject, video_url, thumb.
  Widget _buildVideoListItem(BuildContext context, Map<String, dynamic> video) {
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
            _navigateToVideoPlayer(context, videoUrl, title: title);
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
            // Content: title, description, tags, Watch Video
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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

  Widget _buildVideoList(BuildContext context, List<Video> videos) {
    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No free videos available'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildVideoCard(context, video);
      },
    );
  }

  Widget _buildVideoCard(BuildContext context, Video video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToVideoPlayer(context, video.youtubeUrl, title: video.title),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YoutubeThumbnailPlayer(
              videoUrl: video.youtubeUrl,
              thumbUrl: video.thumb.isNotEmpty ? video.thumb : null,
              title: video.title,
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
                    video.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (video.grade != null || video.subject != null) ...[
                    Row(
                      children: [
                        if (video.grade != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Grade ${video.grade}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (video.subject != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              video.subject!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 20,
                        color: Colors.red[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Watch Video',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  void _navigateToVideoPlayer(BuildContext context, String youtubeUrl, {String? title}) {
    if (youtubeUrl.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => YoutubeWebViewPlayerPage(
            videoUrl: youtubeUrl,
            title: title,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video URL is not available.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
