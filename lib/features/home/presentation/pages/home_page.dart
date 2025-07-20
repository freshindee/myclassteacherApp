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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<String> imageUrls = [
    'https://firebasestorage.googleapis.com/v0/b/tuition-class-management-app.firebasestorage.app/o/images%2Fs1.jpg?alt=media&token=2af50d6a-47cb-45ce-9fb4-10cd8a2693c5',
    'https://firebasestorage.googleapis.com/v0/b/tuition-class-management-app.firebasestorage.app/o/images%2Fs2.jpg?alt=media&token=f2773fa3-620f-4542-8fd6-c397ad24f5aa',
    'https://firebasestorage.googleapis.com/v0/b/tuition-class-management-app.firebasestorage.app/o/images%2Fs3.jpg?alt=media&token=b550627d-4a7c-43ff-a13b-c964a5df80ee',
  ];

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
                // Welcome Card
                  // Main Menu Grid
                CarouselSlider(
                  options: CarouselOptions(
                    height: 180,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 1.0,
                    aspectRatio: 16/9,
                    autoPlayInterval: const Duration(seconds: 4),
                  ),
                  items: imageUrls.map((url) {
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
                      'Free Videos',
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
                      'Class Recordings',
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
                      'Today\'s Classes',
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
                      'Timetable',
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
                      'Pay Fees',
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
                      'Our Teachers',
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
                      'Notes & Assignments',
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
                     'Term Test Papers',
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
                      'Contact Us',
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
                      'Old Videos',
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