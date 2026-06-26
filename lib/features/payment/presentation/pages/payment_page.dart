import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../../../../core/utils/month_utils.dart';
import '../../../../core/services/master_data_service.dart';
import '../../../../core/widgets/grade_selector.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/resolved_firebase_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class PaymentPage extends StatefulWidget {
  final String userId;
  final String schoolId;
  final bool embedInHomeShell;

  const PaymentPage({
    super.key,
    required this.userId,
    required this.schoolId,
    this.embedInHomeShell = false,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  /// From app_config "payment_type": "subject" = pay per subject (show subject list), "class" = pay per class (no subject).
  String? _paymentType;
  bool _paymentTypeLoading = true;

  String? selectedGrade;
  String? selectedClassName;
  Map<String, dynamic>? selectedClassDoc;
  List<Map<String, dynamic>> _classesForGrade = [];
  bool _loadingClasses = false;
  List<Map<String, dynamic>> _classSubjectsForSelectedClass = [];
  bool _loadingClassSubjects = false;
  Map<String, String> _subjectIdToName = {};
  String? selectedSubject;
  String? selectedClassSubjectId;
  String? selectedMonth;
  PlatformFile? selectedFile;
  UploadTask? uploadTask;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  double _calculatedAmount = 0.0;

  final List<String> months = MonthUtils.getAllMonthNames();

  static const String _entireClassSubjectLabel = 'Entire Class';

  /// True when required fields are set and we can confirm. payment_type "subject" needs subject; "class" does not.
  bool _canConfirmPayment(dynamic state) {
    if (state is PaymentLoading || _isUploading) return false;
    if (selectedGrade == null || selectedClassName == null || selectedMonth == null || selectedFile == null) return false;
    if (_paymentType == 'subject' && selectedSubject == null) return false;
    return true;
  }

  /// True when payment_type is "class" (pay per class, no subject selection).
  bool get _isPayPerClass => _paymentType == 'class';

  @override
  void initState() {
    super.initState();
    selectedMonth = MonthUtils.getMonthName(DateTime.now().month);
    context.read<PaymentBloc>().add(LoadPayAccountDetails(widget.schoolId));
    _loadPaymentType();
  }

  /// On page load: read payment_type from cached app_config (SQLite). "subject" → subject payment UI; "class" → class payment UI.
  Future<void> _loadPaymentType() async {
    if (widget.schoolId.isEmpty) {
      if (mounted) setState(() { _paymentType = 'subject'; _paymentTypeLoading = false; });
      return;
    }
    try {
      final docs = await sl<SchoolCacheService>().getAppConfig(widget.schoolId);
      final first = docs.isNotEmpty ? docs.first : null;
      final value = (first?['payment_type'] ?? first?['paymentType'])?.toString().trim().toLowerCase();
      if (mounted) {
        setState(() {
          _paymentType = (value == 'class' || value == 'subject') ? value : 'subject';
          _paymentTypeLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _paymentType = 'subject'; _paymentTypeLoading = false; });
    }
  }

  /// Resolve subject display name from subjects table (by subject_id in class_subject doc). Do not display class_subject id.
  String _subjectDisplayName(Map<String, dynamic> classSubjectItem) {
    final subjectId = classSubjectItem['subject_id']?.toString() ??
        classSubjectItem['subjectId']?.toString() ??
        classSubjectItem['subject']?.toString();
    if (subjectId == null || subjectId.isEmpty) return '—';
    return _subjectIdToName[subjectId] ?? '—';
  }

  /// Parse fee/price from a doc (fee, price, amount, monthly_fee, etc.). Used for classes and class_subjects.
  double? _feeFromDoc(Map<String, dynamic> doc) {
    final raw = doc['fee'] ?? doc['price'] ?? doc['amount'] ?? doc['monthly_fee'] ?? doc['amount_fee'];
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final s = raw.toString().trim().replaceAll(RegExp(r'[^\d.]'), '');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  Future<void> _calculateAmount() async {
    try {
      // 1) Subject payment mode + subject selected: fee must come from class_subjects (selected class_subject_id doc)
      if (!_isPayPerClass &&
          selectedClassSubjectId != null &&
          _classSubjectsForSelectedClass.isNotEmpty) {
        Map<String, dynamic>? selectedDoc;
        for (final d in _classSubjectsForSelectedClass) {
          final id = d['id']?.toString();
          if (id != null && id == selectedClassSubjectId) {
            selectedDoc = d;
            break;
          }
        }
        if (selectedDoc != null) {
          final fee = _feeFromDoc(selectedDoc);
          if (fee != null && fee >= 0) {
            setState(() => _calculatedAmount = fee);
            return;
          }
        }
      }

      // 2) Class payment mode or no subject selected: fee from classes collection (selectedClassDoc)
      if (selectedClassDoc != null && selectedClassDoc!.isNotEmpty) {
        final fee = _feeFromDoc(selectedClassDoc!);
        if (fee != null && fee >= 0) {
          setState(() => _calculatedAmount = fee);
          return;
        }
      }

      // 3) Fallback: master data (requires grade + subject)
      if (selectedGrade == null || selectedSubject == null) {
        setState(() => _calculatedAmount = 0.0);
        return;
      }
      String gradeValue = selectedGrade!.replaceAll(RegExp(r'[^0-9]'), '');
      final price = await MasterDataService.getPricing(selectedSubject!, gradeValue);
      if (price != null) {
        setState(() => _calculatedAmount = price.toDouble());
        return;
      }
      final gradeWithPrefix = selectedGrade!.contains('Grade') ? selectedGrade! : 'Grade ${selectedGrade!}';
      final priceWithPrefix = await MasterDataService.getPricing(selectedSubject!, gradeWithPrefix);
      if (priceWithPrefix != null) {
        setState(() => _calculatedAmount = priceWithPrefix.toDouble());
      } else {
        setState(() => _calculatedAmount = 0.0);
      }
    } catch (e) {
      setState(() => _calculatedAmount = 0.0);
    }
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
        withData: true, // Ensures we get file bytes
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file size (10MB limit)
        if (file.size > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size too large. Please select a file smaller than 10MB.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Validate file extension
        final validExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
        if (!validExtensions.contains(file.extension?.toLowerCase())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid file type. Please select an image (JPG, PNG) or PDF file.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        setState(() {
          selectedFile = file;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: ${file.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> uploadFile() async {
    if (selectedFile == null) return null;
    
    try {
      // Validate file size (e.g., max 10MB)
      if (selectedFile!.size > 10 * 1024 * 1024) {
        throw Exception('File size too large. Maximum size is 10MB.');
      }
      
      // Create a unique file path with user ID and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${widget.userId}_${timestamp}_${selectedFile!.name}';
      final path = 'payment_slips/${widget.userId}/$fileName';
      
      final ref = FirebaseStorage.instance.ref().child(path);
      
      // Get file bytes
      Uint8List? fileBytes = selectedFile!.bytes;
      if (fileBytes == null && selectedFile!.readStream != null) {
        final bytes = await selectedFile!.readStream!.reduce((a, b) => a + b);
        fileBytes = Uint8List.fromList(bytes);
      }
      
      if (fileBytes == null) {
        throw Exception('Could not read file data');
      }
      
      // Set metadata for better organization
      final metadata = SettableMetadata(
        contentType: selectedFile!.extension == 'pdf' 
            ? 'application/pdf' 
            : 'image/${selectedFile!.extension}',
        customMetadata: {
          'userId': widget.userId,
          'originalName': selectedFile!.name,
          'uploadedAt': DateTime.now().toIso8601String(),
          'fileSize': selectedFile!.size.toString(),
        },
      );
      
      // Upload with metadata
      uploadTask = ref.putData(fileBytes, metadata);
      
      // Listen to upload progress
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      uploadTask!.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        // You can update UI here to show progress
      }).onDone(() {
        setState(() {
          _isUploading = false;
        });
      });
      
      // Wait for upload to complete
      final snapshot = await uploadTask!.whenComplete(() {});
      
      // Get download URL
      final url = await snapshot.ref.getDownloadURL();
      
      print('File uploaded successfully: $url');
      return url;
      
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: widget.embedInHomeShell
          ? null
          : AppBar(
              title: const Text('පන්ති ගාස්තු ගෙවීම'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('මුදල් ගෙවීමේ රිසිට්පත යොමුකිරිම සාර්ථකයි, පැය 6ක් ඇතුලත ඔබට අදාළ තොරතුරු නැරබිය හැකියි.'),
                backgroundColor: Colors.green,
              ),
            );
            // Pop when this page was pushed (e.g. notes → payment). When this
            // route is the shell root (Payments tab), there is nothing to pop.
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
          if (state is PaymentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_paymentTypeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          // UI style: clean, minimalistic, light palette, rounded corners
          final labelStyle = TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          );
          final inputDecoration = InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            labelStyle: TextStyle(color: Colors.grey[700]),
          );
          const accentBlue = Color(0xFF64B5F6);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (Navigator.of(context).canPop())
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'පන්තිය සහ ගෙවීම් තොරතුරු ලබා දෙන්න',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                          // Grade: common GradeSelector (1–13)
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
                                selectedClassSubjectId = null;
                                _classesForGrade = [];
                                _classSubjectsForSelectedClass = [];
                                _subjectIdToName = {};
                              });
                              if (value != null && value.isNotEmpty && widget.schoolId.isNotEmpty) {
                                setState(() => _loadingClasses = true);
                                final cache = sl<SchoolCacheService>();
                                final list = await cache.getClassesByGradeNumber(widget.schoolId, value);
                                if (mounted) {
                                  setState(() {
                                    _classesForGrade = list;
                                    _loadingClasses = false;
                                    if (list.length == 1) {
                                      selectedClassDoc = list.first;
                                      selectedClassName = SchoolCacheService.classDisplayName(list.first, value);
                                    }
                                  });
                                  if (!_isPayPerClass && list.length == 1 && list.first.isNotEmpty && widget.schoolId.isNotEmpty) {
                                    setState(() => _loadingClassSubjects = true);
                                    final cache = sl<SchoolCacheService>();
                                    final doc = list.first;
                                    final classId = doc['id']?.toString() ?? '';
                                    final cName = SchoolCacheService.classDisplayName(doc, value);
                                    final subjects = await cache.getClassSubjectsForClass(
                                        widget.schoolId, classId, cName);
                                    final subjectDocs = await cache.getSubjects(widget.schoolId);
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
                                  await _calculateAmount();
                                }
                              }
                            },
                          ),
                          // Class name: selectable when multiple classes for this grade
                          if (selectedGrade != null && selectedGrade!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            if (_loadingClasses)
                              const SizedBox(
                                height: 48,
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_classesForGrade.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'මෙම පන්තිය සඳහා පන්ති නොමැත',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                value: selectedClassName != null &&
                                        _classesForGrade.any((c) =>
                                            SchoolCacheService.classDisplayName(c, selectedGrade!) == selectedClassName)
                                    ? selectedClassName
                                    : null,
                                decoration: inputDecoration.copyWith(labelText: 'පන්තියේ නම'),
                                hint: const Text('පන්තිය තෝරන්න'),
                                items: _classesForGrade.map((c) {
                                  final name = SchoolCacheService.classDisplayName(c, selectedGrade!);
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(name),
                                  );
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
                                    selectedClassSubjectId = null;
                                    _classSubjectsForSelectedClass = [];
                                    _subjectIdToName = {};
                                  });
                                  if (doc.isNotEmpty && widget.schoolId.isNotEmpty) {
                                    if (!_isPayPerClass) {
                                      setState(() => _loadingClassSubjects = true);
                                      final cache = sl<SchoolCacheService>();
                                      final classId = doc['id']?.toString() ?? '';
                                      final list = await cache.getClassSubjectsForClass(
                                          widget.schoolId, classId, className);
                                      final subjectDocs = await cache.getSubjects(widget.schoolId);
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
                                    await _calculateAmount();
                                  } else {
                                    _calculateAmount();
                                  }
                                },
                              ),
                            const SizedBox(height: 8),
                          ],
                          // Class subjects list – only when "Select subject" tab
                          if (!_isPayPerClass && selectedClassDoc != null && selectedClassName != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'විෂය',
                              style: labelStyle,
                            ),
                            const SizedBox(height: 8),
                            if (_loadingClassSubjects)
                              const SizedBox(
                                height: 48,
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_classSubjectsForSelectedClass.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'මෙම පන්තිය සඳහා විෂය නොමැත',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _classSubjectsForSelectedClass.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = _classSubjectsForSelectedClass[index];
                                  final title = _subjectDisplayName(item);
                                  final subtitle = item['description']?.toString() ?? item['code']?.toString();
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        setState(() {
                                          selectedSubject = title;
                                          selectedClassSubjectId = item['id']?.toString();
                                        });
                                        await _calculateAmount();
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 14),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300!),
                                          borderRadius: BorderRadius.circular(12),
                                          color: selectedSubject == title
                                              ? accentBlue.withOpacity(0.12)
                                              : Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.menu_book_outlined,
                                              size: 24,
                                              color: accentBlue,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (subtitle != null && subtitle.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      subtitle,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (selectedSubject == title)
                                              Icon(
                                                Icons.check_circle,
                                                color: accentBlue,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 16),
                          
                          // Month Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedMonth,
                            decoration: inputDecoration.copyWith(labelText: 'මාසය'),
                            items: months.map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedMonth = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Upload receipt – dashed-style area (light blue border, paperclip + text)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: pickFile,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accentBlue,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.attach_file, size: 24, color: accentBlue),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        'මුදල් තැම්පත් කල රිසිට්පත තෝරන්න',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: accentBlue,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (selectedFile != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(selectedFile!.extension == 'pdf' ? Icons.picture_as_pdf : Icons.image, size: 20, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Expanded(child: Text(selectedFile!.name, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  
                  // Confirm payment button – pill-shaped, light blue-grey, bold dark text
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _canConfirmPayment(state)
                        ? () async {
                            try {
                              String? slipUrl;
                              if (selectedFile != null) {
                                slipUrl = await uploadFile();
                                if (slipUrl == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to upload payment slip. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                              }
                              final gradeNumber = selectedGrade!.replaceAll(RegExp(r'[^0-9]'), '');
                              final isPayPerClass = _isPayPerClass;
                              context.read<PaymentBloc>().add(
                                CreatePaymentRequested(
                                  userId: widget.userId,
                                  teacherId: widget.schoolId,
                                  grade: gradeNumber,
                                  className: selectedClassName ?? '',
                                  classSubjectId: isPayPerClass ? '' : (selectedClassSubjectId ?? ''),
                                  subject: isPayPerClass ? _entireClassSubjectLabel : (selectedSubject ?? ''),
                                  month: selectedMonth!,
                                  year: DateTime.now().year,
                                  amount: _calculatedAmount,
                                  slipUrl: slipUrl,
                                ),
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
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB0BEC5),
                      foregroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isUploading
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                'Uploading: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                                style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        : (state is PaymentLoading
                            ? SizedBox(height: 24, child: CircularProgressIndicator(color: Colors.grey[800]))
                            : Text(
                                'ඔබගේ ගෙවීම තහවුරු කරන්න : Rs ${_calculatedAmount.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                              )),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'SECURE PAYMENT PROCESSING',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),


                    // Payment Summary Card – light, rounded, subtle border
                  if (selectedGrade != null && selectedClassName != null && selectedMonth != null &&
                      (selectedSubject != null || _isPayPerClass))
                    Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'මුදල් ගෙවීමේ රිසිට්පත යොමුකිරිම',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('පන්තිය : ${selectedClassName ?? (selectedGrade != null && selectedGrade!.contains('Grade') ? selectedGrade : 'Grade $selectedGrade')}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                            Text(
                              'විෂය : ${_isPayPerClass ? _entireClassSubjectLabel : selectedSubject}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            Text('මාසය : $selectedMonth ${DateTime.now().year}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            Text(
                              'මුදල : Rs ${_calculatedAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                           

                  // Add spacing before the image
                  const SizedBox(height: 32),
                  
                  // Display the dynamic account image from database
                  BlocBuilder<PaymentBloc, PaymentState>(
                    builder: (context, state) {
                      if (state is PayAccountDetailsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (state is PayAccountDetailsLoaded) {
                        final images = state.bankDetailImages.where((s) => s.trim().isNotEmpty).toList();
                        if (images.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No bank details available',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: images.map((imageUrl) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ResolvedFirebaseImage(
                                reference: imageUrl,
                                fit: BoxFit.contain,
                              ),
                            );
                          }).toList(),
                        );
                      } else if (state is PayAccountDetailsError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<PaymentBloc>().add(LoadPayAccountDetails(widget.schoolId));
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Show a placeholder or loading state
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Loading account details...',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 