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
import '../bloc/slider_bloc.dart';
import '../../../auth/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Class Teacher'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
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
                // Slider Section with BlocBuilder
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final teacherId = authState.user?.teacherId;
                    if (teacherId == null || teacherId.isEmpty) {
                      return const SizedBox(
                        height: 180,
                        child: Center(child: Text('Please login to view slider images')),
                      );
                    }
                    
                    return BlocProvider(
                      create: (context) => sl<SliderBloc>()..add(LoadSliderImages(teacherId)),
                      child: BlocBuilder<SliderBloc, SliderState>(
                        builder: (context, sliderState) {
                          if (sliderState is SliderLoading) {
                            return const SizedBox(
                              height: 180,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else if (sliderState is SliderError) {
                            return SizedBox(
                              height: 180,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                    const SizedBox(height: 8),
                                    Text(
                                      sliderState.message,
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.read<SliderBloc>().add(LoadSliderImages(teacherId));
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (sliderState is SliderLoaded) {
                            if (sliderState.sliderImages.isEmpty) {
                              return const SizedBox(
                                height: 180,
                                child: Center(child: Text('No slider images found for this teacher')),
                              );
                            }
                            
                            return CarouselSlider(
                              options: CarouselOptions(
                                height: 180,
                                autoPlay: true,
                                enlargeCenterPage: true,
                                viewportFraction: 1.0,
                                aspectRatio: 16/9,
                                autoPlayInterval: const Duration(seconds: 4),
                              ),
                              items: sliderState.sliderImages.map((sliderImage) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return Image.network(
                                      sliderImage.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: progress.expectedTotalBytes != null 
                                                ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) 
                                                : null
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.broken_image, size: 64, color: Colors.grey)
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          } else {
                            return const SizedBox(
                              height: 180,
                              child: Center(child: Text('Loading slider images...')),
                            );
                          }
                        },
                      ),
                    );
                  },
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
                        final teacherId = authState.user?.teacherId ?? ''; // Get teacherId from auth state
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (_) => sl<PaymentBloc>(),
                              child: PaymentPage(userId: userId, teacherId: teacherId),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          switch (index) {
            case 0: // Home - already on home page
              break;
            case 1: // Contact Us
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DisplayContactDetailsPage(),
                ),
              );
              break;
            case 2: // Profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_page),
            label: 'Contact Us',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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
                fontSize: 14,
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