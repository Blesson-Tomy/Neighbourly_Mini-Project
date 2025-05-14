import 'package:flutter/material.dart';
import '../styles/styles.dart';

class ChangeRolePage extends StatelessWidget {
  const ChangeRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.darkPurple, // Set background color
      body: SingleChildScrollView( // Allows scrolling if content overflows
        child: Column(
          children: [
            // Title Section (Top One-Third)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.33,
              child: Stack(
                children: [
                  // Title (Centered)
                  const Align(
                    alignment: Alignment.center,
                    child: Text("Change Role", style: Styles.titleStyle),
                  ),

                  // Back Button (Bottom-Left)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: BackButton(
                      color: Styles.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),

            // Cards Section (Bottom Two-Thirds)
            const ChangeRoleCardSection()
          ],
        ),
      ),
    );
  }
}

class ChangeRoleCardSection extends StatefulWidget {
  const ChangeRoleCardSection({super.key});

  @override
  ChangeRoleCardSectionState createState() => ChangeRoleCardSectionState();
}

class ChangeRoleCardSectionState extends State<ChangeRoleCardSection> {
  String selectedRole = 'Home Bound';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          RoleCard(
            role: 'Home Bound',
            description: 'Full access to all settings and data.',
            icon: Icons.home,
            isSelected: selectedRole == 'Home Bound',
            onTap: () {
              setState(() {
                selectedRole = 'Home Bound';
              });
            },
          ),
          const SizedBox(height: 16),
          RoleCard(
            role: 'Volunteer',
            description: 'Can edit content but has limited access to settings.',
            icon: Icons.volunteer_activism,
            isSelected: selectedRole == 'Volunteer',
            onTap: () {
              setState(() {
                selectedRole = 'Volunteer';
              });
            },
          ),
          const SizedBox(height: 16),
          RoleCard(
            role: 'Guardian',
            description: 'Can view content but cannot make changes.',
            icon: Icons.security,
            isSelected: selectedRole == 'Guardian',
            onTap: () {
              setState(() {
                selectedRole = 'Guardian';
              });
            },
          ),
          // SizedBox(height: 16),
          // RoleCard(
          //   role: 'Organization',
          //   description: 'Can view content but cannot make changes.',
          //   icon: Icons.group,
          //   isSelected: selectedRole == 'Organization',
          //   onTap: () {
          //     setState(() {
          //       selectedRole = 'Organization';
          //     });
          //   },
          // ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.24),
          Container(
            decoration: BoxDecoration(
              color: Styles.lightPurple,
              borderRadius: BorderRadius.circular(20.0),
            ),
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                showConfirmationDialog(context);
                // Handle change role action
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: BorderSide( color: Color.fromARGB(255, 241, 241, 241), width: 2.0)
                  
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, color: Styles.white, size: 26,),
                  SizedBox(width: 10,),
                  Text(
                    'Change',
                    style: TextStyle(
                      color: Styles.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String role;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleCard({super.key, 
    required this.role,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // Specify the height of the card
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Card(
          shape: isSelected
              ? RoundedRectangleBorder(
                  side: const BorderSide(color: const Color.fromARGB(255, 241, 241, 241), width: 3.0),
                  borderRadius: BorderRadius.circular(20.0),
                )
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
          color: isSelected? Styles.lightPurple : const Color.fromARGB(255, 99, 75, 138),
          child: Center(
            child: ListTile(
              leading: Icon(icon, color: Styles.white),
              title: Text(role, style: const TextStyle(color: Styles.white, fontSize: 20, fontWeight: FontWeight.bold)),
              trailing: isSelected ? const Icon(Icons.check, color: Styles.white,) : null,
            ),
          ),
        ),
      ),
    );
  }
}

// Confirmation Dialog Function
void showConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Styles.mildPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Confirm Role Change",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to change your role?",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Styles.lightPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Styles.lightPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Change Role",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
