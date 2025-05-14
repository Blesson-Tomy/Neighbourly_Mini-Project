import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mini_ui/menu/organization/navigation.dart';
import '../../styles/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
class OrgDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orgDetails;
  final String nav ;
  const OrgDetailsPage({super.key, required this.orgDetails, required this.nav});

  @override
  State<OrgDetailsPage> createState() => _OrgDetailsPageState();
}

class _OrgDetailsPageState extends State<OrgDetailsPage> {
  bool _isLoading = false;

void removeField() async {
  setState(() => _isLoading = true);
  try {
    final prefs = await SharedPreferences.getInstance();
    String userType = prefs.getString('userType') ?? '';
    String userId = prefs.getString('userId') ?? '';

    if (userId.isEmpty || userType.isEmpty) {
      throw Exception("User data missing!");
    }

    await prefs.remove('orgId');
    await FirebaseFirestore.instance.collection(userType).doc(userId).update({
      'orgId': FieldValue.delete(),
    });

    print('Field removed successfully');
                              ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("You have left the organization!")),
                          );
                        Navigator.pop(context);
  } catch (e) {
    print("Error removing field: $e");
  } 
}


  void showConfirmationDialog(BuildContext context1, String orgId) {
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
                      "Are you sure you want to apply to this organization?",
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
                                await joinNeighbourhood(orgId);
                                if (mounted) {
                                  int popCount = 0;
                                  Navigator.of(context).popUntil((route) => popCount++ == 2);
                                  Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const OrganizationNavigation()),
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
    if(widget.nav =='join'){
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
                    child: Text("Organization Details", style: Styles.titleStyle),
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
                    widget.orgDetails["orgName"],
                  ),
                  const SizedBox(height: 10),
                  buildInfoContainer(
                    'Id: ',
                    value: widget.orgDetails["organizationId"],
                  ),
                  const SizedBox(height: 10),
                  // Created Time
                  buildInfoContainer("Organization Type:", value: widget.orgDetails["organizationType"]),
                  const SizedBox(height: 10),
                  // End Time
                 
                  // Join Neighbourhood Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () {
                        setState(() => _isLoading = false);
                        showConfirmationDialog(context, widget.orgDetails["uid"]);
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
                            "Join Organization",
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
    );}
    else{
      if(_isLoading
      ==true){  return const Scaffold(
        backgroundColor: Styles.darkPurple,
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white),),
        ),
      );
      }
      else{
           return Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(color: Styles.darkPurple),
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.33,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text("Your Organization", style: Styles.titleStyle, textAlign: TextAlign.center),
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
              Expanded(
                flex: 2,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                     buildInfoContainer(
                    widget.orgDetails["orgName"],
                  ),
                  const SizedBox(height: 10),
                  buildInfoContainer(
                    'Id: ',
                    value: widget.orgDetails["organizationId"],
                  ),
                  const SizedBox(height: 10),
                  // Created Time
                  buildInfoContainer("Organization Type:", value: widget.orgDetails["organizationType"]),
                  const SizedBox(height: 10),
                  // End Time
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.07,
                  child: ElevatedButton(
                    onPressed: () {
                      // Leave neighbourhood action
                      removeField();

                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Styles.mildPurple,
                        elevation: 10, // Increased elevation for a stronger shadow
                        shadowColor: Colors.black, // Darker and more visible shadow
                        padding: const EdgeInsets.symmetric(vertical: 8), // Removed horizontal padding to fit width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color.fromARGB(255, 209, 209, 209), width: 2),
                        ),
                      ),
                    child: Text(
                      "Leave Organization",
                      textAlign: TextAlign.center,
                      style: Styles.buttonTextStyle.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            ]
          )
        )
     );
    }}
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
Future<void> joinNeighbourhood(String neighbourhoodId) async {
  final prefs = await SharedPreferences.getInstance();
  final _userType = prefs.getString('userType') ?? "User"; // Fallback if not found
  print ("User Name: $_userType");
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User not logged in");
      return;
    }

    DocumentReference userDocRef = FirebaseFirestore.instance.collection(_userType).doc(user.uid);

    // Update the user document by adding the field
    await userDocRef.set({'orgId': neighbourhoodId}, SetOptions(merge: true));
    await prefs.setString('orgId', neighbourhoodId);
    await FirebaseFirestore.instance
        .collection('organization') // Change to your collection name
        .doc(neighbourhoodId)
        .update({
          _userType: FieldValue.increment(1), // Increment by 1
        });

    print("Org ID added successfully");
  } catch (e) {
    print("Error joining Org: $e");
  }
}
