import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mini_ui/menu/neighbourhood/neighbourhood.dart';
import '../../styles/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ReqDetailsPage extends StatefulWidget {
  final Map<String, dynamic> requestDetails;
  const ReqDetailsPage({super.key, required this.requestDetails});

  @override
  State<ReqDetailsPage> createState() => _ReqDetailsPageState();
}

class _ReqDetailsPageState extends State<ReqDetailsPage> {
  bool _isLoading = false;
  Future<void> joinNeighbourhood(String neighbourhoodId) async {
    setState(() {
      _isLoading = true;
    });
  final prefs = await SharedPreferences.getInstance();
  final _userType = prefs.getString('userType') ?? ""; // Fallback if not found
  print ("User Name: $_userType");
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User not logged in");
      return;
    }

    DocumentReference userDocRef = FirebaseFirestore.instance.collection(_userType).doc(user.uid);

    // Update the user document by adding the field
    await userDocRef.set({'neighbourhoodId': neighbourhoodId}, SetOptions(merge: true));
    await prefs.setString('neighbourhoodId', neighbourhoodId);
    await FirebaseFirestore.instance
        .collection('neighbourhood') // Change to your collection name
        .doc(neighbourhoodId)
        .update({
          _userType: FieldValue.increment(1), // Increment by 1
        });

    print("Neighbourhood ID added successfully to $_userType");
  } catch (e) {
    print("Error joining neighborhood: $e");
  }
  setState(() {
    _isLoading = false;
  });
}


  void showConfirmationDialog(BuildContext context1, String neighbourhoodId) {
    showDialog(
      context: context1,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Styles.mildPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Confirmation ",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: _isLoading
                  ? const SizedBox(
                      height: 80,
                      width: 40,
                      child: Center(
                        child: Column(
                          children: [
                            SizedBox(height: 30),
                            CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Text(
                      "Are you sure you want to join this neighbourhood?",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
              actions: _isLoading
                  ? []
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
                                setStateDialog(() => _isLoading = true);
                                await joinNeighbourhood(neighbourhoodId);
                                if (mounted) {
                                  int popCount = 0;
                                  Navigator.of(context).popUntil((route) => popCount++ == 3);
                                  Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => Neighbourhood()),
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
                    child: Text("Neighbourhood Details", style: Styles.titleStyle),
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
                  // Title and Description Container
                  buildInfoContainer(
                    widget.requestDetails["name"],
                  ),
                  const SizedBox(height: 10),
                  buildInfoContainer(
                    'Description: ',
                    value: widget.requestDetails["description"],
                  ),
                  const SizedBox(height: 10),
                  // Created Time
                  buildInfoContainer("Address:", value: widget.requestDetails["address"]),
                  const SizedBox(height: 10),
                  // End Time
                  buildInfoContainer("City:", value: widget.requestDetails["city"]),
                  const SizedBox(height: 10),
                  // Amount
                  buildInfoContainer("State:", value: widget.requestDetails["state"]),
                  const SizedBox(height: 10),
                  // Status Container
                  buildInfoContainer(
                    "Zip:",
                    value: widget.requestDetails["zip"],
                  ),
                  const SizedBox(height: 14),
                  // Join Neighbourhood Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () {
                        setState(() => _isLoading = false);
                        showConfirmationDialog(context, widget.requestDetails["id"]);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Styles.offWhite, width: 2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.thumb_up, color: Colors.white, size: 26),
                          SizedBox(width: 8),
                          Text(
                            "Join Neighbourhood",
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
  Widget buildInfoContainer(String title, {String value = '', bool isStatus = false}) {
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

// Function to add neighbourhood ID to the current user's collection
