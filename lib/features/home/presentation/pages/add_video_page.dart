import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/add_video.dart';
import 'add_video_bloc.dart';

class AddVideoPage extends StatelessWidget {
  const AddVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddVideoBloc(
        addVideo: sl<AddVideo>(),
      ),
      child: const AddVideoView(),
    );
  }
}

class AddVideoView extends StatelessWidget {
  const AddVideoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Video'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<AddVideoBloc, AddVideoState>(
        listener: (context, state) {
          if (state.status == FormzStatus.submissionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (state.status == FormzStatus.submissionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to add video'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add New Class Video',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildVideoForm(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoForm(BuildContext context) {
    return BlocBuilder<AddVideoBloc, AddVideoState>(
      builder: (context, state) {
        return Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Video Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                onChanged: (value) {
                  context.read<AddVideoBloc>().add(VideoTitleChanged(value));
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                onChanged: (value) {
                  context.read<AddVideoBloc>().add(VideoDescriptionChanged(value));
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // YouTube URL Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'YouTube URL *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://www.youtube.com/watch?v=...',
                ),
                onChanged: (value) {
                  context.read<AddVideoBloc>().add(VideoUrlChanged(value));
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a YouTube URL';
                  }
                  if (!value.contains('youtube.com') && !value.contains('youtu.be')) {
                    return 'Please enter a valid YouTube URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Thumbnail URL Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Thumbnail URL *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                  hintText: 'https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg',
                ),
                onChanged: (value) {
                  context.read<AddVideoBloc>().add(VideoThumbChanged(value));
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a thumbnail URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Grade Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Grade (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grade),
                  hintText: 'e.g., Grade 10, Grade 11',
                ),
                onChanged: (value) {
                  context.read<AddVideoBloc>().add(VideoGradeChanged(value));
                },
              ),
              const SizedBox(height: 16),

              // Subject Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Subject (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                  hintText: 'e.g., Mathematics, Science',
                ),
                onChanged: (value) {
                  context.read<AddVideoBloc>().add(VideoSubjectChanged(value));
                },
              ),
              const SizedBox(height: 16),

              // Access Level Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Access Level',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                value: state.accessLevel,
                items: const [
                  DropdownMenuItem(
                    value: 'free',
                    child: Text('Free'),
                  ),
                  DropdownMenuItem(
                    value: 'paid',
                    child: Text('Paid'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    context.read<AddVideoBloc>().add(VideoAccessLevelChanged(value));
                  }
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: state.status == FormzStatus.submissionInProgress
                    ? null
                    : () {
                        context.read<AddVideoBloc>().add(AddVideoSubmitted());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: state.status == FormzStatus.submissionInProgress
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add Video',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
} 