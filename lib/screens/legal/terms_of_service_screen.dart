import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Terms of Service',
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
            'Acceptance of Terms',
            'By accessing or using Medical Helper, you agree to be bound by these Terms of Service. If you disagree with any part of these terms, you may not access the service.',
          ),
          
          _buildSection(
            context,
            'Medical Disclaimer',
            '''IMPORTANT: Medical Helper is not a substitute for professional medical advice, diagnosis, or treatment.

• The app is for informational purposes only
• Always seek professional medical advice
• Do not disregard professional medical advice based on app information
• If you suspect a medical emergency, call your doctor or emergency services immediately''',
          ),
          
          _buildSection(
            context,
            'User Account',
            '''By creating an account, you agree to:

• Provide accurate and complete information
• Maintain the security of your account
• Not share your account credentials
• Notify us immediately of any security breaches
• Take responsibility for all activities under your account''',
          ),
          
          _buildSection(
            context,
            'User Responsibilities',
            '''You agree to:

• Use the app responsibly and legally
• Keep your medical information accurate and up-to-date
• Maintain accurate emergency contact information
• Not misuse or attempt to harm the service
• Not use the app for emergency medical services''',
          ),
          
          _buildSection(
            context,
            'Data Usage',
            '''By using the app, you grant us permission to:

• Store and process your health data
• Send notifications and reminders
• Share data with designated emergency contacts
• Use anonymized data for service improvement
• Back up your data for security purposes''',
          ),
          
          _buildSection(
            context,
            'Service Availability',
            '''We strive to provide uninterrupted service, however:

• We do not guarantee 100% uptime
• We may perform maintenance or updates
• Service may be affected by factors beyond our control
• We reserve the right to modify or discontinue features''',
          ),
          
          _buildSection(
            context,
            'Intellectual Property',
            'All content, features, and functionality are owned by Medical Helper and protected by international copyright, trademark, and other laws.',
          ),
          
          _buildSection(
            context,
            'Limitation of Liability',
            '''To the maximum extent permitted by law:

• We are not liable for any indirect damages
• We are not responsible for medical decisions
• We do not guarantee accuracy of all information
• Total liability is limited to amounts paid for the service''',
          ),
          
          _buildSection(
            context,
            'Termination',
            '''We may terminate or suspend your account if you:

• Violate these terms
• Provide false information
• Engage in unauthorized activities
• Fail to comply with legal requirements

You may terminate your account at any time through settings.''',
          ),
          
          _buildSection(
            context,
            'Changes to Terms',
            'We may modify these terms at any time. Continued use of the app after changes constitutes acceptance of new terms.',
          ),
          
          _buildSection(
            context,
            'Governing Law',
            'These terms are governed by the laws of the jurisdiction in which the company operates, without regard to its conflict of law provisions.',
          ),
          
          _buildSection(
            context,
            'Contact',
            'For questions about these Terms of Service, please contact us at:\nsupport@medicalhelper.com',
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