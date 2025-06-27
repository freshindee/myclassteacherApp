import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/video.dart';

class VideoModel extends Equatable {
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

  const VideoModel({
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
  List<Object?> get props => [
        id,
        title,
        description,
        youtubeUrl,
        thumb,
        grade,
        subject,
        accessLevel,
        month,
        year
      ];

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? 'No Description',
      youtubeUrl: json['youtube_url'] as String? ?? json['youtube_url'] as String? ?? '',
      thumb: json['thumb'] as String? ?? '',
      grade: json['grade'] as String?,
      subject: json['subject'] as String?,
      accessLevel: json['accessLevel'] as String? ?? 'free',
      month: json['month'] as int?,
      year: json['year'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'youtube_url': youtubeUrl,
      'thumb': thumb,
      'grade': grade,
      'subject': subject,
      'accessLevel': accessLevel,
      'month': month,
      'year': year,
    };
  }

  Video toEntity() {
    return Video(
      id: id,
      title: title,
      description: description,
      youtubeUrl: youtubeUrl,
      thumb: thumb,
      grade: grade,
      subject: subject,
      accessLevel: accessLevel.isNotEmpty ? accessLevel : 'free',
      month: month,
      year: year,
    );
  }
} 