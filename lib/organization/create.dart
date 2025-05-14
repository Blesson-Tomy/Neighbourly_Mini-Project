// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:mini_ui/navbar.dart';
// import 'package:mini_ui/screens/auth_service.dart';
// import 'package:mini_ui/screens/screen_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../styles/custom_style.dart';
import 'package:flutter/material.dart';
import '../../styles/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateOrganization extends StatefulWidget {
  const CreateOrganization({super.key});

  @override
  CreateOrganizationState createState() => CreateOrganizationState();
}

class CreateOrganizationState extends State<CreateOrganization> with CustomStyle {
  final TextEditingController organizationIdController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  bool isLoading = false;
  // static final _auth = AuthService();
  String organizationType = "NSS"; // Default value for dropdown

  // static void _goToLogin(BuildContext context) {
  //   Navigator.of(context).pushAndRemoveUntil(
  //     MaterialPageRoute(builder: (context) => const LogInScreen()),
  //     (Route<dynamic> route) => false,
  //   );
  // }

  Future<void> addOrganization() async {
    String orgId = organizationIdController.text.trim();
    String address = addressController.text.trim();

    if (orgId.isNotEmpty && address.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');

        if (userId == null) {
          debugPrint("Error: User ID not found in SharedPreferences");
          return;
        }

        DocumentReference organizationRef =
            FirebaseFirestore.instance.collection('organization').doc(userId);

        String orgName = "$organizationType $orgId";

        await organizationRef.set({
          'organizationType': organizationType,
          'organizationId': orgId,
          'address': address,
          'orgName': orgName,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await prefs.setString('orgName', orgName);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );

      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            "Organization Type:",
            style: descriptionStyle,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: DropdownButtonFormField<String>(
            value: organizationType,
            items: ["NSS", "NCC", "Red Cross","Other"]
              .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, style: const TextStyle(color: Colors.white)),
                ))
              .toList(),
            onChanged: (value) {
              if (value != null) {
              setState(() {
                organizationType = value;
              });
              }
            },
            dropdownColor: Styles.lightPurple,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white), // Set arrow color to white
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.white, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.white, width: 1),
              ),
            ),
            ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPrompt(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            label,
            style: descriptionStyle,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.edit, color: Colors.white),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.white, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.white, width: 1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false, // Prevents default back behavior
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop(); // Close the app
        }
      },
      child: Container(
        color: Styles.darkPurple,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: const BoxDecoration(color: Styles.darkPurple),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: deviceHeight * 0.33,
                    alignment: Alignment.center,
                    child: const Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text("Add Organization\nDetails",
                              style: Styles.titleStyle,
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Container(
                      height: deviceHeight * 0.62,
                      decoration: BoxDecoration(
                        color: Styles.mildPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                      child: Column(
                        children: [
                          _buildDropdown(),
                          _buildPrompt("Organization ID/Number:",
                              organizationIdController),
                          _buildPrompt("Address:", addressController),
                          SizedBox(height: (deviceHeight * 0.14)),
                          SizedBox(
                            width: deviceWidth - 76,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null // Disable button when loading
                                  : () {
                                      setState(() {
                                        isLoading = true;
                                      });

                                      addOrganization().then((_) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      });
                                    },
                              style: TextButton.styleFrom(
                                textStyle: buttonTextStyle,
                                backgroundColor: Styles.lightPurple,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text("Continue", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // const SizedBox(height: 20),
                  // SizedBox(
                  //   width: deviceWidth - 40,
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       showLogOutDialog(context);
                  //     },
                  //     style: TextButton.styleFrom(
                  //       textStyle: buttonTextStyle,
                  //       backgroundColor: Colors.red[400],
                  //       padding: const EdgeInsets.symmetric(
                  //           horizontal: 40, vertical: 18),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(20),
                  //       ),
                  //     ),
                  //     child: const Text("Log Out",
                  //         style: TextStyle(color: Colors.white)),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Confirmation Dialog Function
//   void showConfirmationDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context1) {
//         return AlertDialog(
//           backgroundColor: Styles.mildPurple,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: const Text(
//             "Confirm Organization Details",
//             style: TextStyle(
//                 fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
//           ),
//           content: const Text(
//             "Continue with the details?",
//             style: TextStyle(color: Colors.white, fontSize: 18),
//           ),
//           actions: [
//             Column(
//               children: [
//                 SizedBox(
//                   width: double.infinity,
//                   child: TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: TextButton.styleFrom(
//                       backgroundColor: Styles.lightPurple,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                     child: const Text(
//                       "Cancel",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 SizedBox(
//                   width: double.infinity,
//                   child: TextButton(
//                     onPressed: () {
//                       addOrganization();
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                             content: Text("Organization added successfully!")),
//                       );
//                       Navigator.pushAndRemoveUntil(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const MainScreen()),
//                         (route) => false, // Removes all previous routes
//                       );
//                     },
//                     style: TextButton.styleFrom(
//                       backgroundColor: Styles.lightPurple,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                     child: const Text(
//                       "Create",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// void showLogOutDialog(BuildContext context) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         backgroundColor: Styles.mildPurple,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         title: const Text(
//           "Confirm Log Out",
//           style: TextStyle(
//               fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         content: const Text(
//           "Are you sure you want to log out?",
//           style: TextStyle(color: Colors.white, fontSize: 18),
//         ),
//         actions: [
//           Column(
//             children: [
//               SizedBox(
//                 width: double.infinity,
//                 child: TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: TextButton.styleFrom(
//                     backgroundColor: Styles.lightPurple,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                   child: const Text(
//                     "Cancel",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 width: double.infinity,
//                 child: TextButton(
//                   onPressed: () async {
//                     await CreateOrganizationState._auth.signOut(context);
//                     CreateOrganizationState._goToLogin(context);
//                   },
//                   style: TextButton.styleFrom(
//                     backgroundColor: Colors.red[400],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                   child: const Text(
//                     "Log Out",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       );
//     },
//   );
}