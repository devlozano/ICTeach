import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TrainerHomePage extends StatelessWidget {
  const TrainerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ICTeach Trainer"),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // HEADER
            const Text(
              "Welcome, TESDA Trainer",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              "Monitor trainee performance, validate competencies, "
              "and support Computer Systems Servicing NC II training.",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 25),

            _sectionTitle("Learning Management"),

            _trainerCard(
              context,
              title: "Training Modules",
              subtitle: "View and manage CSS NC II learning materials.",
              icon: Icons.menu_book,
              onTap: () {},
            ),

            _trainerCard(
              context,
              title: "Instructional Videos",
              subtitle: "Manage practical demonstrations and training videos.",
              icon: Icons.video_library,
              onTap: () {},
            ),

            const SizedBox(height: 20),

            _sectionTitle("Assessment Management"),

            _trainerCard(
              context,
              title: "Quizzes and Assessments",
              subtitle: "Create and review knowledge assessments.",
              icon: Icons.quiz,
              onTap: () {},
            ),

            _trainerCard(
              context,
              title: "Performance Activities",
              subtitle: "Create and review hands-on CSS activities.",
              icon: Icons.assignment,
              onTap: () {},
            ),

            const SizedBox(height: 20),

            _sectionTitle("Competency Monitoring"),

            _trainerCard(
              context,
              title: "Trainee Progress",
              subtitle: "Monitor student learning progress and completion.",
              icon: Icons.analytics,
              onTap: () {},
            ),

            _trainerCard(
              context,
              title: "Competency Validation",
              subtitle: "Evaluate trainee readiness for CSS NC II assessment.",
              icon: Icons.verified,
              onTap: () {},
            ),

            const SizedBox(height: 20),

            _sectionTitle("Communication"),

            _trainerCard(
              context,
              title: "Discussion Forum",
              subtitle: "Communicate with teachers and students.",
              icon: Icons.forum,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Text(
        title,

        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _trainerCard(
    BuildContext context, {

    required String title,

    required String subtitle,

    required IconData icon,

    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,

      margin: const EdgeInsets.only(bottom: 14),

      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        leading: CircleAvatar(radius: 25, child: Icon(icon)),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Text(subtitle),

        trailing: const Icon(Icons.arrow_forward_ios, size: 18),

        onTap: onTap,
      ),
    );
  }
}
