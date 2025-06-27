import 'package:equatable/equatable.dart';

class Video extends Equatable {
  final String id;
  final String title;
  final String description;
  final String youtubeUrl;
  final String thumb;
  final String? grade;
  final String? subject;
  final String accessLevel;
  final int? month;
  final int? year;

  const Video({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.thumb,
    this.grade,
    this.subject,
    this.accessLevel = 'free',
    this.month,
    this.year,
  });

  @override
  List<Object?> get props => [id, title, description, youtubeUrl, thumb, grade, subject, accessLevel, month, year];
} 