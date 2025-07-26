import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'class_videos_page.dart';
import 'notes_assignments_page.dart';
import 'schedule_page.dart';
import 'free_videos_page.dart';
import 'add_video_page.dart';
import 'display_contact_details_page.dart';
import '../../../payment/presentation/pages/payment_page.dart';
import '../../../../injection_container.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import 'today_classes_page.dart';
import 'teachers_page.dart';
import 'view_old_videos_page.dart';
import 'old_videos_bloc.dart';
import 'free_videos_bloc.dart';
import 'grades_list_page.dart';
import 'term_test_papers_page.dart';
import '../bloc/term_test_paper_bloc.dart';
import '../../domain/usecases/get_term_test_papers.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _imageUrls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSliderImages();
  }

  Future<void> _fetchSliderImages() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('slider').get();
      final urls = querySnapshot.docs
          .map((doc) => doc.data()['image'] as String?)
          .where((image) => image != null && image.isNotEmpty)
          .cast<String>()
          .toList();
      setState(() {
        if (!mounted) return;
        _imageUrls = urls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        if (!mounted) return;
        _error = 'Failed to load slider images';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schoooly App'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const SignOutSubmitted());
            },
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.isLogout == true) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoading)
                  const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  SizedBox(
                    height: 180,
                    child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  )
                else if (_imageUrls.isEmpty)
                  const SizedBox(
                    height: 180,
                    child: Center(child: Text('No slider images found')),
                  )
                else
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 180,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 1.0,
                      aspectRatio: 16/9,
                      autoPlayInterval: const Duration(seconds: 4),
                    ),
                    items: _imageUrls.map((url) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null));
                            },
                            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                          );
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),


                // Main Menu Grid
                GridView.count(
                  padding: const EdgeInsets.all(16.0),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMenuCard(
                      context,
                      'වීඩියෝ පාඩම්',
                      Icons.play_circle_outline,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (_) => sl<FreeVideosBloc>(),
                            child: const FreeVideosPage(),
                          ),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      'පන්තිවල රෙකෝඩින්',
                      Icons.video_library,
                      Colors.red,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClassVideosPage(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      'අද පැවැත්වෙන පන්ති',
                      Icons.assignment,
                      Colors.purple,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TodayClassesPage(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      'කාල සටහන',
                      Icons.calendar_today,
                      Colors.teal,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GradesListPage(),
                        ),
                      ),
                    ),
                     _buildMenuCard(
                      context,
                      'පන්ති ගාස්තු ගෙවීම්',
                      Icons.payment,
                      Colors.green,
                      () {
                        final authState = context.read<AuthBloc>().state;
                        final userId = authState.user?.userId ?? '1'; // Fallback to '1' if no user
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (_) => sl<PaymentBloc>(),
                              child: PaymentPage(userId: userId),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      'අපේ ගුරුවරු',
                      Icons.people,
                      Colors.indigo,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeachersPage(),
                        ),
                      ),
                    ),
                   _buildMenuCard(
                      context,
                      'පන්ති නිබන්ධන',
                      Icons.note,
                      Colors.orange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotesAssignmentsPage(),
                        ),
                      ),
                    ),
                   _buildMenuCard(
                     context,
                     'වාර විභාග ප්‍රශ්න පත්‍ර',
                     Icons.description,
                     Colors.deepPurple,
                     () => Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => BlocProvider(
                           create: (_) => TermTestPaperBloc(getTermTestPapers: sl<GetTermTestPapers>())..add(FetchTermTestPapers()),
                           child: const TermTestPapersPage(),
                         ),
                       ),
                     ),
                   ),
                    _buildMenuCard(
                      context,
                      'අපි සමඟ සම්බන්ධ වන්න',
                      Icons.contact_page,
                      Colors.blue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DisplayContactDetailsPage(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      'පසුගිය මාසවල රෙකෝඩින්',
                      Icons.video_library,
                      Colors.purple,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (_) => sl<OldVideosBloc>(),
                            child: const ViewOldVideoPage(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 