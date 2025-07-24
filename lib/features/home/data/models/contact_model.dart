import 'package:equatable/equatable.dart';
import '../../domain/entities/contact.dart';

class ContactModel extends Equatable {
  final String id;
  final String role;
  final String name;
  final String? image;
  final String? phone1;
  final String? phone2;
  final String? email;
  final String? address;
  final String? website;
  final String? youtubeLink;
  final String? facebookLink;
  final String? whatsappLink;
  final String? description;
  final bool isActive;

  const ContactModel({
    required this.id,
    required this.role,
    required this.name,
    this.image,
    this.phone1,
    this.phone2,
    this.email,
    this.address,
    this.website,
    this.youtubeLink,
    this.facebookLink,
    this.whatsappLink,
    this.description,
    this.isActive = true,
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
        youtubeLink,
        facebookLink,
        whatsappLink,
        description,
        isActive,
      ];

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'Unknown',
      name: json['name'] as String? ?? 'No Name',
      image: json['photoUrl'] as String?,
      phone1: json['phone1'] as String?,
      phone2: json['phone2'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      website: json['website'] as String?,
      youtubeLink: json['youtube_link'] as String?,
      facebookLink: json['facebook_link'] as String?,
      whatsappLink: json['whatsapp_link'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'name': name,
      'photoUrl': image,
      'phone1': phone1,
      'phone2': phone2,
      'email': email,
      'address': address,
      'website': website,
      'youtube_link': youtubeLink,
      'facebook_link': facebookLink,
      'whatsapp_link': whatsappLink,
      'description': description,
      'isActive': isActive,
    };
  }

  Contact toEntity() {
    return Contact(
      id: id,
      role: role,
      name: name,
      image: image,
      phone1: phone1,
      phone2: phone2,
      email: email,
      address: address,
      website: website,
      youtubeLink: youtubeLink,
      facebookLink: facebookLink,
      whatsappLink: whatsappLink,
      description: description,
      isActive: isActive,
    );
  }
} 