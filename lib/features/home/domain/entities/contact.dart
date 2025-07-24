import 'package:equatable/equatable.dart';

class Contact extends Equatable {
  final String id;
  final String role;
  final String name;
  final String? image;
  final String? phone1;
  final String? phone2;
  final String? email;
  final String? address;
  final String? website;
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? linkedin;
  final String? description;
  final bool isActive;
  final String? youtubeLink;
  final String? facebookLink;
  final String? whatsappLink;

  const Contact({
    required this.id,
    required this.role,
    required this.name,
    this.image,
    this.phone1,
    this.phone2,
    this.email,
    this.address,
    this.website,
    this.facebook,
    this.instagram,
    this.twitter,
    this.linkedin,
    this.description,
    this.isActive = true,
    this.youtubeLink,
    this.facebookLink,
    this.whatsappLink,
  });

  @override
  List<Object?> get props => [
        id,
        role,
        name,
        image,
        phone1,
        phone2,
        email,
        address,
        website,
        facebook,
        instagram,
        twitter,
        linkedin,
        description,
        isActive,
        youtubeLink,
        facebookLink,
        whatsappLink,
      ];
} 