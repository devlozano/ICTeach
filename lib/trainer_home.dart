import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TrainerHomePage extends StatelessWidget {
  const TrainerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trainer Dashboard"),

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
            const Text(
              "TESDA Trainer Portal",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              "Manage training content, assessments, and trainee competency progress.",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 25),

            _sectionTitle("Training Management"),

            _trainerCard(
              context,
              title: "Create Training Module",
              subtitle: "Create lessons, topics, and learning materials.",
              icon: Icons.menu_book,
              onTap: () {
                // TODO:
                // Navigate to create module page
              },
            ),

            _trainerCard(
              context,
              title: "Manage Simulations",
              subtitle: "Create hands-on ICT activities and simulations.",
              icon: Icons.computer,
              onTap: () {
                // TODO:
                // Navigate simulation builder
              },
            ),

            const SizedBox(height: 20),

            _sectionTitle("Assessment Management"),

            _trainerCard(
              context,
              title: "Create Quiz",
              subtitle: "Build quizzes and knowledge assessments.",
              icon: Icons.quiz,
              onTap: () {
                // TODO:
                // Quiz builder
              },
            ),

            _trainerCard(
              context,
              title: "Create Assignment",
              subtitle: "Create tasks and performance activities.",
              icon: Icons.assignment,
              onTap: () {
                // TODO:
                // Assignment creation
              },
            ),

            const SizedBox(height: 20),

            _sectionTitle("Trainee Monitoring"),

            _trainerCard(
              context,
              title: "Student Progress",
              subtitle: "Monitor learning progress and completion.",
              icon: Icons.analytics,
              onTap: () {
                // TODO:
                // Progress monitoring
              },
            ),

            _trainerCard(
              context,
              title: "Competency Validation",
              subtitle: "Validate TESDA skills and competencies.",
              icon: Icons.verified,
              onTap: () {
                // TODO:
                // Competency validation
              },
            ),

            const SizedBox(height: 20),

            _sectionTitle("Communication"),

            _trainerCard(
              context,
              title: "Training Forum",
              subtitle: "Interact with trainees and answer discussions.",
              icon: Icons.forum,
              onTap: () {
                // TODO:
                // Forum page
              },
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
