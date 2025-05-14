import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mini_ui/menu/priority/prioritylist.dart';
import '../../styles/styles.dart';

class Volremove extends StatelessWidget {
  final Map<String, dynamic> requestDetails;
  const Volremove({Key? key, required this.requestDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String volunteerId = requestDetails["volunteerId"] ?? "";
    return Scaffold(
      backgroundColor: Styles.darkPurple,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.33,
              child: Stack(
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text("Volunteer Details", style: Styles.titleStyle),
                  ),
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
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildProfileHeader(requestDetails),
                  const SizedBox(height: 10),
                  buildInfoContainer(
                      "Age:", requestDetails["age"]?.toString() ?? "N/A"),
                  buildInfoContainer(
                      "Gender:", requestDetails["gender"] ?? "N/A"),
                  buildInfoContainer(
                    "Rating:",
                    requestDetails["rating"]?.toString() ?? "N/A",
                  ),

                  buildInfoContainer(
                      "Address:", requestDetails["address"] ?? "N/A"),
                  buildRemoveButton(context, requestDetails),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileHeader(Map<String, dynamic> details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Styles.mildPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Styles.white,
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              details["name"] ?? "Name not available",
              style: Styles.bodyStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoContainer(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Styles.mildPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$title $value",
        style: Styles.bodyStyle,
      ),
    );
  }

  Widget buildRemoveButton(BuildContext context, Map<String, dynamic> details) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton(
        onPressed: () => showConfirmationDialog(context, details),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[500],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Styles.offWhite, width: 2),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text("Remove Volunteer",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }
}

void showConfirmationDialog(
    BuildContext context, Map<String, dynamic> details) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          bool isLoading = false; // Local loading state

          return AlertDialog(
            backgroundColor: Styles.mildPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Confirm Removal",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 80,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                else
                  const Text(
                    "Are you sure you want to remove this volunteer?",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
              ],
            ),
            actions: isLoading
                ? [] // Disable actions while loading
                : [
                    Column(
                      children: [
                        buildDialogButton(
                          context,
                          "Do Not Remove",
                          Styles.lightPurple,
                          () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 10),
                        buildDialogButton(
                          context,
                          "Remove Volunteer",
                          Colors.red[500]!,
                          () async {
                            setStateDialog(
                                () => isLoading = true); // Show loader
                            await removeVolunteer(details["volunteerId"] ?? "");

                            if (context.mounted) {
                              int popCount = 0;
                              Navigator.of(context)
                                  .popUntil((route) => popCount++ == 2);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PriorityPage()),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
          );
        },
      );
    },
  );
}

Widget buildDialogButton(
    BuildContext context, String text, Color color, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    ),
  );
}

Future<void> removeVolunteer(String volunteerId) async {
  if (volunteerId.isEmpty) return;
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("Error: User not logged in");
      return;
    }
    await FirebaseFirestore.instance
        .collection("homebound")
        .doc(user.uid)
        .update({
      'volunteerId': FieldValue.arrayRemove([volunteerId]),
    });
    debugPrint("Volunteer removed successfully");
  } catch (e) {
    debugPrint("Error removing volunteer: $e");
  }
}
