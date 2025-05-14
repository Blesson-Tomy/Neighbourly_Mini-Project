import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mini_ui/menu/priority/prioritylist.dart';
import '../../styles/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VolDetails extends StatelessWidget {
  final Map<String, dynamic> requestDetails;
  const VolDetails({super.key, required this.requestDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.darkPurple, // Set background color
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Title Section (Top One-Third)
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
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Icon and Name in a Single Line
                  Container(
                    padding: const EdgeInsets.all(
                        12), // Add padding inside the container
                    decoration: BoxDecoration(
                      color: Styles
                          .mildPurple, // Background color for the container
                      borderRadius:
                          BorderRadius.circular(20), // Rounded corners
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
                          child:
                              Icon(Icons.person, size: 40, color: Colors.grey),
                        ), // Profile Icon
                        const SizedBox(
                            width: 10), // Spacing between icon and name
                        Expanded(
                          child: Text(
                            requestDetails["name"] ?? "Name not available",
                            style: Styles.bodyStyle.copyWith(
                              fontSize:
                                  18, // Adjust font size to match the design
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .white, // Ensure text color matches the design
                            ),
                            overflow: TextOverflow
                                .ellipsis, // Handle long names gracefully
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10), // Add spacing below the container
                  const SizedBox(height: 10),
                  buildInfoContainer(
                    'Age: ',
                    value: requestDetails["age"]?.toString() ?? "N/A",
                  ),
                  const SizedBox(height: 10),
                  buildInfoContainer(
                    "Gender:",
                    value: requestDetails["gender"] ?? "N/A",
                  ),
                  const SizedBox(height: 10),
                  buildInfoContainer(
                    "Rating:",
                    value: requestDetails["rating"]?.toString() ?? "N/A",
                  ),
                  const SizedBox(height: 10),
                  // Amount
                  buildInfoContainer(
                    "Address:",
                    value: requestDetails["address"] ?? "Address not available",
                  ),
                  const SizedBox(height: 10),
                  // Status Container
                  buildInfoContainer(
                    "Requests Completed:",
                    value: '55', // Assuming this is hardcoded
                  ),
                  const SizedBox(height: 10),
                  buildInfoContainer("Services:",
                      value: 'Services'),
                  const SizedBox(height: 14),
                  // Join Neighbourhood Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () {
                        showConfirmationDialog(context, requestDetails["id"]);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(
                              color: Styles.offWhite, width: 2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.thumb_up, color: Colors.white, size: 26),
                          SizedBox(width: 8),
                          Text(
                            "Add Volunteer",
                            style: TextStyle(
                              color: Colors.white,
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
            ),
          ],
        ),
      ),
    );
  }

  // Function to build info container dynamically
  Widget buildInfoContainer(String title,
      {String value = '', bool isStatus = false}) {
    Color statusColor = Colors.yellow[500]!;

    if (value == 'Accepted by a volunteer') {
      statusColor = const Color.fromARGB(255, 145, 255, 150);
    } else if (value == 'Waiting for volunteer') {
      statusColor = Colors.yellow[500]!;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Styles.mildPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value.isEmpty ? title : "$title $value",
        style: value.isEmpty
            ? Styles.bodyStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )
            : isStatus
                ? Styles.bodyStyle.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  )
                : Styles.bodyStyle,
      ),
    );
  }
}

// Confirmation Dialog Function
void showConfirmationDialog(BuildContext context, String volunteerId) {
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
              "Confirmation",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            content: isLoading
                ? const SizedBox(
                    height: 80,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : const Text(
                    "Are you sure you want to add the volunteer?",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
            actions: isLoading
                ? [] // Disable actions while loading
                : [
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
                            onPressed: () async {
                              setStateDialog(
                                  () => isLoading = true); // Show loader
                              await addVolunteers(volunteerId);

                              if (context.mounted) {
                                int popCount = 0;
                                Navigator.of(context)
                                    .popUntil((route) => popCount++ == 3);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PriorityPage()),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Confirm",
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
    },
  );
}

// Function to add neighbourhood ID to the current user's collection
Future<void> addVolunteers(String volunteerId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User not logged in");
      return;
    }

    DocumentReference userDocRef =
        FirebaseFirestore.instance.collection("homebound").doc(user.uid);

    // Use Firestore's arrayUnion to add the volunteerId to the list
    await userDocRef.set({
      'volunteerId': FieldValue.arrayUnion([volunteerId])
    }, SetOptions(merge: true));

    print("Volunteer ID added successfully");
  } catch (e) {
    print("Error adding Volunteer: $e");
    // Retry logic
    Future.delayed(Duration(seconds: 5), () => addVolunteers(volunteerId));
  }
}


// Widget buildInfoContainer(String title, {String value = '', bool isRating = false, List<dynamic>? services}) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
//       decoration: BoxDecoration(
//         color: Styles.mildPurple,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: services == null
//             ? Wrap(
//               crossAxisAlignment: WrapCrossAlignment.start,
//               runSpacing: 5,
//               children: [
//               Text(
//                 "$title ",
//                 style: Styles.bodyStyle,
//               ),
//               if (isRating)
//                 Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                   value,
//                   style: Styles.bodyStyle,
//                   ),
//                   const SizedBox(width: 5),
//                   Icon(
//                   Icons.star,
//                   color: Colors.yellow[500],
//                   size: 20,
//                   ),
//                 ],
//                 )
//               else
//                 Text(
//                 value,
//                 style: Styles.bodyStyle,
//                 ),
//               ],
//             )
//           : Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "$title ",
//                   style: Styles.bodyStyle,
//                 ),
//                 const SizedBox(height: 5),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: services.map((service) => Text("• $service", style: Styles.bodyStyle)).toList(),
//                 ),
//               ],
//             ),
//     );
//   }