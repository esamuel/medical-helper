import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Privacy Policy',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${DateTime.now().toString().split(' ')[0]}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          
          _buildSection(
            context,
            'Introduction',
            'This Privacy Policy describes how Medical Helper ("we," "our," or "us") collects, uses, and shares your personal information when you use our mobile application.',
          ),
          
          _buildSection(
            context,
            'Information We Collect',
            '''We collect the following types of information:

• Personal Information: Name, email address, and authentication data
• Health Data: Blood pressure, heart rate, weight, and other health metrics
• Medical Information: Medications, dosages, and schedules
• Emergency Contact Information
• Device Information: Device ID, IP address, and usage data''',
          ),
          
          _buildSection(
            context,
            'How We Use Your Information',
            '''We use your information to:

• Provide and improve our services
• Monitor and analyze usage patterns
• Send important notifications and reminders
• Respond to your requests and support needs
• Ensure the security of your account
• Comply with legal obligations''',
          ),
          
          _buildSection(
            context,
            'Data Storage and Security',
            '''We implement industry-standard security measures:

• Encryption of sensitive data
• Secure cloud storage
• Regular security audits
• Access controls and authentication
• Regular backups

Your health data is stored securely and encrypted both in transit and at rest.''',
          ),
          
          _buildSection(
            context,
            'Data Sharing',
            '''We do not share your personal information except:

• With your explicit consent
• With emergency contacts you designate
• To comply with legal requirements
• With service providers who assist in app operations
• In anonymized, aggregated form for analytics''',
          ),
          
          _buildSection(
            context,
            'Your Rights',
            '''You have the right to:

• Access your personal information
• Correct inaccurate data
• Delete your account and data
• Export your data
• Opt-out of non-essential data collection
• Withdraw consent at any time''',
          ),
          
          _buildSection(
            context,
            'Data Retention',
            'We retain your data for as long as your account is active or as needed to provide services. You can request deletion of your data at any time through the app settings.',
          ),
          
          _buildSection(
            context,
            'Children\'s Privacy',
            'Our service is not directed to children under 13. We do not knowingly collect information from children under 13. If you believe we have collected information from a child under 13, please contact us.',
          ),
          
          _buildSection(
            context,
            'Changes to Privacy Policy',
            'We may update this Privacy Policy periodically. We will notify you of any material changes through the app or via email.',
          ),
          
          _buildSection(
            context,
            'Contact Us',
            'If you have questions about this Privacy Policy or your data, please contact us at:\nsupport@medicalhelper.com',
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
} 