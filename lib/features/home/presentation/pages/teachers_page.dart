import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/teacher.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../../../core/services/user_session_service.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key, this.embedInHomeShell = false});

  final bool embedInHomeShell;

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  List<Teacher> _teachers = [];
  bool _isLoading = true;
  String? _error;

  String? _schoolId;
  bool _schoolIdLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    final user = await UserSessionService.getCurrentUser();
    if (mounted) {
      final id = user?.teacherId ?? '';
      setState(() {
        _schoolId = id;
        _schoolIdLoading = false;
      });
      if (id.isNotEmpty) {
        await _loadTeachersFromCache(id);
      }
    }
  }

  /// Converts a teacher document from local cache (teachers table) to [Teacher] entity.
  Teacher _teacherFromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    // Firestore schema: full_name, specialization, subjects (array), phone, etc.
    final name = (map['full_name'] ?? map['name'] ?? map['teacher_name'] ?? map['title'])?.toString().trim() ?? '';

    String subject = (map['specialization'] ?? map['subject'] ?? map['subject_name'])?.toString().trim() ?? '';
    if (subject.isEmpty) {
      final subjectsField = map['subjects'];
      if (subjectsField is List && subjectsField.isNotEmpty) {
        subject = subjectsField.first.toString().trim();
      }
    }

    final grade = (map['grade'] ?? map['grade_number'] ?? map['grades'])?.toString().trim() ?? '';
    // Firebase DB column key: profile_image_url (Firebase Storage https URL). Fallbacks for legacy/cache.
    final image = (map['profile_image_url'] ?? map['profileImageUrl'] ?? map['image'] ?? map['photo'] ?? map['image_url'] ?? map['photo_url'])
            ?.toString()
            .trim() ??
        '';
    final phone = (map['phone'] ?? map['phone_number'] ?? map['contact'])?.toString().trim() ?? '';
    final displayId = (map['displayId'] ?? map['display_id'])?.toString().trim() ?? '';
    final qualification = (map['qualification'] ?? map['qualification_name'])?.toString().trim() ?? '';
    final specialization = (map['specialization'] ?? map['specialization_name'])?.toString().trim() ?? '';
    return Teacher(
      id: id,
      name: name.isEmpty ? '—' : name,
      subject: subject,
      grade: grade,
      image: image,
      phone: phone,
      displayId: displayId,
      qualification: qualification,
      specialization: specialization,
    );
  }

  Future<void> _loadTeachersFromCache(String schoolId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await sl<SchoolCacheService>().getTeachers(schoolId);
      if (!mounted) return;
      final teachers = list.map(_teacherFromMap).toList();
      setState(() {
        _teachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to convert gs:// URL to HTTP URL
  String _convertGsUrlToHttp(String url) {
    print('🖼️ TeachersPage: Converting URL - Original: $url');
    
    if (!url.startsWith('gs://')) {
      print('🖼️ TeachersPage: Not a gs:// URL, returning as-is');
      return url; // Return as-is if not a gs:// URL
    }

    try {
      // Remove gs:// prefix
      final withoutPrefix = url.substring(5);
      print('🖼️ TeachersPage: Without prefix: $withoutPrefix');
      
      // Find the first slash to separate bucket and path
      final firstSlashIndex = withoutPrefix.indexOf('/');
      if (firstSlashIndex == -1) {
        print('❌ TeachersPage: Invalid gs:// URL format (no slash found)');
        return url; // Invalid format, return original
      }

      final bucketWithDomain = withoutPrefix.substring(0, firstSlashIndex);
      final path = withoutPrefix.substring(firstSlashIndex + 1);
      print('🖼️ TeachersPage: Bucket with domain: $bucketWithDomain');
      print('🖼️ TeachersPage: Path: $path');

      // Extract bucket name - try both full domain and just the name
      String bucketName = bucketWithDomain;
      if (bucketWithDomain.contains('.')) {
        // For Firebase Storage, try using just the bucket name (before first dot)
        // But also try the full domain if that doesn't work
        bucketName = bucketWithDomain.split('.').first;
      }
      print('🖼️ TeachersPage: Extracted bucket name: $bucketName');

      // URL encode the path properly - Firebase Storage needs each segment encoded separately
      // and then joined with %2F
      final pathSegments = path.split('/');
      final encodedPath = pathSegments.map((segment) => Uri.encodeComponent(segment)).join('%2F');
      print('🖼️ TeachersPage: Encoded path: $encodedPath');

      // Try multiple Firebase Storage URL formats
      // Format 1: Using storage.googleapis.com (simpler format - try this first)
      final httpUrl1 = 'https://storage.googleapis.com/$bucketName/$path';
      
      // Format 2: Standard Firebase Storage REST API
      final httpUrl2 = 'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/$encodedPath?alt=media';
      
      // Format 3: Using the full bucket domain with REST API
      final httpUrl3 = 'https://firebasestorage.googleapis.com/v0/b/$bucketWithDomain/o/$encodedPath?alt=media';
      
      // Format 4: Using storage.googleapis.com with full domain
      final httpUrl4 = 'https://storage.googleapis.com/$bucketWithDomain/$path';
      
      print('🖼️ TeachersPage: Trying URL format 1 (storage.googleapis.com): $httpUrl1');
      print('🖼️ TeachersPage: Trying URL format 2 (firebasestorage REST): $httpUrl2');
      print('🖼️ TeachersPage: Trying URL format 3 (firebasestorage with domain): $httpUrl3');
      print('🖼️ TeachersPage: Trying URL format 4 (storage.googleapis.com with domain): $httpUrl4');
      
      // Try format 1 first (simpler, might work for public files)
      return httpUrl1;
    } catch (e, stackTrace) {
      print('❌ TeachersPage: Error converting gs:// URL: $e');
      print('❌ TeachersPage: Stack trace: $stackTrace');
      return url; // Return original URL on error
    }
  }

  // Helper method to validate image URL
  bool _isValidImageUrl(String url) {
    print('🖼️ TeachersPage: Validating URL: $url');
    
    if (url.isEmpty) {
      print('🖼️ TeachersPage: URL is empty');
      return false;
    }
    
    // Accept gs:// URLs
    if (url.startsWith('gs://')) {
      print('🖼️ TeachersPage: Valid gs:// URL');
      return true;
    }
    
    // Accept http/https URLs
    try {
      final uri = Uri.parse(url);
      final isValid = uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
      print('🖼️ TeachersPage: HTTP/HTTPS URL validation: $isValid');
      return isValid;
    } catch (e) {
      print('🖼️ TeachersPage: Error parsing URL: $e');
      return false;
    }
  }

  // Helper method to get the display URL (converts gs:// to HTTP if needed)
  String _getImageUrl(String url) {
    print('🖼️ TeachersPage: Getting image URL for: $url');
    
    if (url.startsWith('gs://')) {
      final converted = _convertGsUrlToHttp(url);
      print('🖼️ TeachersPage: Converted to: $converted');
      return converted;
    }
    
    print('🖼️ TeachersPage: Returning original URL: $url');
    return url;
  }

  // Helper method to launch WhatsApp
  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Remove any non-digit characters except +
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If phone doesn't start with +, assume it's a local number and add country code
    // You may need to adjust this based on your country code
    final whatsappNumber = cleanPhone.startsWith('+') ? cleanPhone : '+94$cleanPhone';
    
    final whatsappUrl = 'https://wa.me/$whatsappNumber';
    
    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ TeachersPage: Error launching WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolIdLoading) {
      return Scaffold(
        appBar: widget.embedInHomeShell
            ? null
            : AppBar(
                title: const Text('Teachers'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final schoolId = _schoolId ?? '';
    if (schoolId.isEmpty) {
      return Scaffold(
        appBar: widget.embedInHomeShell
            ? null
            : AppBar(
                title: const Text('Teachers'),
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
              title: const Text('Teachers'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadTeachersFromCache(schoolId),
                  tooltip: 'Refresh',
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadTeachersFromCache(schoolId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildTeacherList(context, _teachers),
    );
  }

  Widget _buildTeacherList(BuildContext context, List<Teacher> teachers) {
    if (teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Teachers Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no teachers available at the moment.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        return _buildTeacherCard(context, teacher);
      },
    );
  }

  /// Compact teacher card: circular photo, name, subject (blue), grades, Call + WhatsApp (blue theme).
  Widget _buildTeacherCard(BuildContext context, Teacher teacher) {
    const bluePrimary = Colors.blue;
    final blueShade = Colors.blue.shade700;
    final blueLight = Colors.blue.shade50;

    final gradesDisplay = teacher.grade.trim().isEmpty
        ? '—'
        : teacher.grade.split(RegExp(r'[,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty).map((g) {
            final val = g.replaceAll(RegExp(r'[^0-9]'), '');
            return val.isEmpty ? g : 'Grade $val';
          }).join(', ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular profile picture (supports Firebase Storage https URLs)
            ClipOval(
              child: SizedBox(
                width: 100,
                height: 100,
                child: _isValidImageUrl(teacher.image)
                    ? Image.network(
                        _getImageUrl(teacher.image),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return _teacherPhotoPlaceholder();
                        },
                        errorBuilder: (_, __, ___) => _teacherPhotoPlaceholder(),
                      )
                    : _teacherPhotoPlaceholder(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teacher.subject,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: blueShade,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gradesDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (teacher.qualification.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.school_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            teacher.qualification,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (teacher.specialization.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.psychology_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            teacher.specialization,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Call button – light blue background, blue icon/text
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: teacher.phone.isNotEmpty
                              ? () {
                                  final uri = Uri.parse('tel:${teacher.phone}');
                                  launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: blueLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone, size: 18, color: blueShade),
                                const SizedBox(width: 6),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: blueShade,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // WhatsApp button – solid blue background, white icon/text
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: teacher.phone.isNotEmpty ? () => _launchWhatsApp(teacher.phone) : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: bluePrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat, size: 18, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'WhatsApp',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  Widget _teacherPhotoPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.person, size: 36, color: Colors.grey[600]),
    );
  }
} 