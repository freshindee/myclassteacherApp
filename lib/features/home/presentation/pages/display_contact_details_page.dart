import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/contact.dart';
import 'contact_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DisplayContactDetailsPage extends StatelessWidget {
  const DisplayContactDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ContactBloc>()..add(LoadContacts()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contact Us'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // WhatsApp group and call section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'පන්ති පිළිබද ගැටළුවක් ඇත්නම් දැනුම් දෙන්න.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 28),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 16)),
                    onPressed: () async {
                      const url = 'https://chat.whatsapp.com/IDFUtbhTWeZDAywAeCVJIF';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'අපිට කතාකරන්න',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.phone, size: 26),
                    label: const Text('Call 0777316215', style: TextStyle(fontSize: 16)),
                    onPressed: () async {
                      const phone = 'tel:0777316215';
                      if (await canLaunchUrl(Uri.parse(phone))) {
                        await launchUrl(Uri.parse(phone));
                      }
                    },
                  ),
                ],
              ),
            ),
            // Expanded contact list
            Expanded(
              child: BlocBuilder<ContactBloc, ContactState>(
                builder: (context, state) {
                  if (state is ContactInitial) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ContactLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading contact information...'),
                        ],
                      ),
                    );
                  } else if (state is ContactLoaded) {
                    return _buildContactList(context, state.contacts);
                  } else if (state is ContactError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error:  [${state.message}]'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ContactBloc>().add(LoadContacts());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contact_page, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No contact information available'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactList(BuildContext context, List<Contact> contacts) {
    if (contacts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_page, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No contact information available'),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ContactBloc>().add(LoadContacts());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _buildContactCard(context, contact);
        },
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, Contact contact) {
    print('Contact debug: id=${contact.id}, name=${contact.name}, youtubeLink=${contact.youtubeLink}, facebookLink=${contact.facebookLink}, whatsappLink=${contact.whatsappLink}');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image and name
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: contact.image != null && contact.image!.isNotEmpty
                      ? NetworkImage(contact.image!)
                      : null,
                  child: contact.image == null || contact.image!.isEmpty
                      ? Icon(Icons.person, size: 30, color: Colors.blue[600])
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(contact.role),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          contact.role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (contact.description != null && contact.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                contact.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Contact Information
            if (contact.email != null && contact.email!.isNotEmpty)
              _buildContactInfo(Icons.email, 'Email', contact.email!, () => _launchEmail(contact.email!)),
            if (contact.phone1 != null && contact.phone1!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 24, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _launchPhone(contact.phone1!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            contact.phone1!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (contact.phone2 != null && contact.phone2!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 24, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _launchPhone(contact.phone2!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            contact.phone2!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (contact.address != null && contact.address!.isNotEmpty)
              _buildContactInfo(Icons.location_on, 'Address', contact.address!, null),
            
            if (contact.website != null && contact.website!.isNotEmpty)
              _buildContactInfo(Icons.language, 'Website', contact.website!, () => _launchUrl(contact.website!)),
            
            const SizedBox(height: 16),
            
            // Social Media Links
            if (_hasSocialMedia(contact) || contact.youtubeLink != null || contact.facebookLink != null || contact.whatsappLink != null) ...[
              const Text(
                'Follow Us',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (contact.facebook != null && contact.facebook!.isNotEmpty)
                    _buildSocialButton(Icons.facebook, Colors.blue[600]!, () => _launchUrl(contact.facebook!)),
                  if (contact.instagram != null && contact.instagram!.isNotEmpty)
                    _buildSocialButton(Icons.camera_alt, Colors.purple[400]!, () => _launchUrl(contact.instagram!)),
                  if (contact.twitter != null && contact.twitter!.isNotEmpty)
                    _buildSocialButton(Icons.flutter_dash, Colors.lightBlue[400]!, () => _launchUrl(contact.twitter!)),
                  if (contact.linkedin != null && contact.linkedin!.isNotEmpty)
                    _buildSocialButton(Icons.work, Colors.blue[700]!, () => _launchUrl(contact.linkedin!)),
                  if (contact.youtubeLink != null && contact.youtubeLink!.isNotEmpty)
                    _buildSocialButton(
                      FontAwesomeIcons.youtube,
                      Colors.red,
                      () => _launchUrl(contact.youtubeLink!),
                    ),
                  if (contact.facebookLink != null && contact.facebookLink!.isNotEmpty)
                    _buildSocialButton(
                      FontAwesomeIcons.facebook,
                      Colors.blue,
                      () => _launchUrl(contact.facebookLink!),
                    ),
                  if (contact.whatsappLink != null && contact.whatsappLink!.isNotEmpty)
                    _buildSocialButton(
                      FontAwesomeIcons.whatsapp,
                      Colors.green,
                      () => _launchUrl(contact.whatsappLink!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String label, String value, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: onTap != null ? Colors.blue[600] : Colors.black87,
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'support':
        return Colors.orange;
      case 'sales':
        return Colors.green;
      case 'technical':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      case 'teacher':
        return Colors.blue;
      case 'manager':
        return Colors.indigo;
      case 'coordinator':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  bool _hasSocialMedia(Contact contact) {
    return (contact.facebook != null && contact.facebook!.isNotEmpty) ||
           (contact.instagram != null && contact.instagram!.isNotEmpty) ||
           (contact.twitter != null && contact.twitter!.isNotEmpty) ||
           (contact.linkedin != null && contact.linkedin!.isNotEmpty);
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
} 