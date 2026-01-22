import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/teacher.dart';
import '../../../../core/services/master_data_service.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  List<Teacher> _teachers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to get teachers from master data
      final masterData = await MasterDataService.getTeacherMasterData();
      if (masterData != null && masterData.teachers.isNotEmpty) {
        setState(() {
          _teachers = masterData.teachers;
          _isLoading = false;
        });
        print('📦 TeachersPage: Loaded ${_teachers.length} teachers from master data');
        for (var teacher in _teachers) {
          print('📦 TeachersPage: Teacher: ${teacher.name}, Image URL: ${teacher.image}');
        }
      } else {
        // Fallback to getTeachers method
        final teachers = await MasterDataService.getTeachers();
        setState(() {
          _teachers = teachers;
          _isLoading = false;
        });
        print('📦 TeachersPage: Loaded ${_teachers.length} teachers from separate storage');
        for (var teacher in _teachers) {
          print('📦 TeachersPage: Teacher: ${teacher.name}, Image URL: ${teacher.image}');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ TeachersPage: Error loading teachers: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeachers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTeachers,
                        child: const Text('Retry'),
                      ),
                    ],
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

  Widget _buildTeacherCard(BuildContext context, Teacher teacher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            // You can add navigation to teacher details page here
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Teacher: ${teacher.name}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Teacher Photo Section (Top)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.shade50,
                      Colors.blue.shade100,
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _isValidImageUrl(teacher.image)
                      ? Builder(
                          builder: (context) {
                            final imageUrl = _getImageUrl(teacher.image);
                            print('🖼️ TeachersPage: Loading image for teacher ${teacher.name}');
                            print('🖼️ TeachersPage: Original URL: ${teacher.image}');
                            print('🖼️ TeachersPage: Final URL: $imageUrl');
                            
                            return Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  print('🖼️ TeachersPage: Image loaded successfully for ${teacher.name}');
                                  return child;
                                }
                                final progress = loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1);
                                print('🖼️ TeachersPage: Loading image for ${teacher.name}: ${(progress * 100).toStringAsFixed(1)}%');
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Loading...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('❌ TeachersPage: Error loading image for ${teacher.name}');
                                print('❌ TeachersPage: Original URL: ${teacher.image}');
                                print('❌ TeachersPage: Final URL: $imageUrl');
                                print('❌ TeachersPage: Error: $error');
                                print('❌ TeachersPage: Stack trace: $stackTrace');
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Photo\nUnavailable',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 300),
                                  child: child,
                                );
                              },
                            );
                          },
                        )
                      : Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No\nPhoto',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              
              // Teacher Details Section (Bottom)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Teacher Name
                    Text(
                      teacher.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subject Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        teacher.subject,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Grade and Phone Info - Stacked vertically
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Grade Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.grade,
                                  size: 20,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Grade ${teacher.grade}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Phone and WhatsApp Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.phone,
                                  size: 20,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  teacher.phone.isNotEmpty ? teacher.phone : 'No phone number',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (teacher.phone.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                // WhatsApp Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _launchWhatsApp(teacher.phone),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF25D366), // WhatsApp green
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.chat,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'WhatsApp',
                                            style: TextStyle(
                                              fontSize: 14,
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
                            ],
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
      ),
    );
  }
} 