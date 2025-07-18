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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo.jpg',
                          height: 100,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Welcome to Schoooly App',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Access your study materials and manage your subscriptions',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14,color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                
                // Main Menu Grid
                GridView.count(
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