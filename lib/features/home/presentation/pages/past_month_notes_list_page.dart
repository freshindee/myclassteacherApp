import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/school_cache_service.dart';

/// Shows list of notes for a selected (paid) month. Same card UI as PastMonthsNotesPage notes list.
class PastMonthNotesListPage extends StatefulWidget {
  final String schoolId;
  final String grade;
  final int month;
  final String subject;
  final List<Map<String, dynamic>> classSubjectsForSelectedClass;
  final Map<String, String> subjectIdToName;

  const PastMonthNotesListPage({
    super.key,
    required this.schoolId,
    required this.grade,
    required this.month,
    required this.subject,
    required this.classSubjectsForSelectedClass,
    required this.subjectIdToName,
  });

  @override
  State<PastMonthNotesListPage> createState() => _PastMonthNotesListPageState();
}

class _PastMonthNotesListPageState extends State<PastMonthNotesListPage> {
  String _subjectDisplayName(Map<String, dynamic> classSubjectItem) {
    final subjectId = classSubjectItem['subject_id']?.toString() ??
        classSubjectItem['subjectId']?.toString() ??
        classSubjectItem['subject']?.toString();
    if (subjectId == null || subjectId.isEmpty) return '—';
    return widget.subjectIdToName[subjectId] ?? '—';
  }

  Set<String> _allowedClassSubjectIds() {
    final allowed = <String>{};
    for (final doc in widget.classSubjectsForSelectedClass) {
      if (_subjectDisplayName(doc) != widget.subject) continue;
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

  /// Resolves month from cached pdf_note row (API may use different key casings).
  static int? _monthNumberFromPdfNote(Map<String, dynamic> item) {
    const keys = ['month', 'Month', 'month_number', 'monthNumber'];
    for (final k in keys) {
      final v = item[k];
      if (v == null) continue;
      final n = v is int ? v : int.tryParse(v.toString());
      if (n != null && n >= 1 && n <= 12) return n;
    }
    return null;
  }

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  Widget _buildNotesFromCache(BuildContext context) {
    final allowedIds = _allowedClassSubjectIds();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentPdfNotes(widget.schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final byMonth = all.where((item) {
          final monthNum = _monthNumberFromPdfNote(item);
          if (monthNum == null) return false;
          return monthNum == widget.month;
        }).toList();
        final freeList = byMonth.where((item) => _isFreeAndForSelectedClass(item, allowedIds)).toList();
        final paidList = byMonth.where((item) => _isPaidAndForSelectedClass(item, allowedIds)).toList();
        final combined = [...freeList, ...paidList];
        if (combined.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No notes for this month / subject'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: combined.length,
          itemBuilder: (context, index) {
            final note = combined[index];
            final isFree = _isFreeAndForSelectedClass(note, allowedIds);
            return _buildNoteListItem(context, note, isFree: isFree);
          },
        );
      },
    );
  }

  Widget _buildNoteListItem(BuildContext context, Map<String, dynamic> note, {bool isFree = true}) {
    final title = note['title']?.toString().trim() ?? 'Note';
    final description = note['description']?.toString().trim() ?? '';
    final pdfUrl = (note['pdf_url'] ?? note['file_url'])?.toString().trim() ?? '';
    final grade = note['grade']?.toString().trim();
    final gradeNum = grade?.replaceAll(RegExp(r'[^0-9]'), '')?.trim() ?? '';
    final displayGradeLabel = gradeNum.isNotEmpty
        ? 'Grade: $gradeNum'
        : (grade?.isNotEmpty == true ? 'Grade: ${grade!.replaceFirst(RegExp(r'^Grade\s*', caseSensitive: false), '').trim()}' : '');

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
              children: [
                if (displayGradeLabel.isNotEmpty)
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isFree ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isFree ? 'Free' : 'Paid',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFree ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (displayGradeLabel.isNotEmpty) const SizedBox(height: 10),
            if (displayGradeLabel.isEmpty) const SizedBox(height: 4),
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

  @override
  Widget build(BuildContext context) {
    final monthName = _monthNames[widget.month - 1];
    final year = DateTime.now().year;
    return Scaffold(
      appBar: AppBar(
        title: Text('$monthName $year - ${widget.subject}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _buildNotesFromCache(context),
    );
  }
}
