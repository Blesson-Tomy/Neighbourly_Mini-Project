import 'package:flutter/services.dart';
import 'package:mini_ui/navbar.dart';
// import 'package:mini_ui/screens/auth_service.dart';
// import 'package:mini_ui/screens/screen_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../styles/custom_style.dart';
import 'package:flutter/material.dart';
import '../../styles/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicesProvided extends StatefulWidget {
  const ServicesProvided({super.key});

  @override
  ServicesProvidedState createState() => ServicesProvidedState();
}

class ServicesProvidedState extends State<ServicesProvided> with CustomStyle {
  // static final _auth = AuthService();
  final Map<String, bool> services = {
    "Driving": false,
    "Grocery Shopping": false,
    "Gardening": false,
    "Dog Walking": false,
    "Technical Support": false,
    "House Cleaning": false,
    "Meal Delivery": false,
    "Medication Pickup": false,
    "Companionship Visits": false,
    "Mail and Package Handling": false,
    "Light Home Repairs": false,
    "Wheelchair Assistance": false,
  };

  bool isLoading = false;

  // static void _goToLogin(BuildContext context) {
  //   Navigator.of(context).pushAndRemoveUntil(
  //     MaterialPageRoute(builder: (context) => const LogInScreen()),
  //     (Route<dynamic> route) => false,
  //   );
  // }

  Future<void> addServices() async {
    List<String> selectedServices = services.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedServices.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');

        if (userId == null) {
          debugPrint("Error: User ID not found in SharedPreferences");
          return;
        }

        DocumentReference volunteerRef =
            FirebaseFirestore.instance.collection('volunteers').doc(userId);

        await volunteerRef.set({
          'services': selectedServices,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await prefs.setStringList('services', selectedServices);

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

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Container(
        color: Styles.darkPurple,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: const BoxDecoration(color: Styles.darkPurple),
            child: Column(
              children: [
                Container(
                  height: deviceHeight * 0.33,
                  alignment: Alignment.center,
                  child: const Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text("Services Provided",
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
                    height: deviceHeight * 0.6,
                    decoration: BoxDecoration(
                      color: Styles.mildPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: deviceHeight * 0.43, // Adjust height as needed
                          child: Scrollbar(
                            thumbVisibility: true, // Always show scrollbar
                            child: SingleChildScrollView(
                              child: Column(
                                children: services.keys.map((service) {
                                  return CheckboxListTile(
                                    title: Text(
                                      service,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    value: services[service],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        services[service] = value ?? false;
                                      });
                                    },
                                    activeColor: Styles.lightPurple,
                                    checkColor: Colors.white,
                                    visualDensity: const VisualDensity(horizontal: -1, vertical: -1), // Slightly larger checkbox
                                    side: const BorderSide(color: Colors.white, width: 2), // White border
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: deviceWidth - 76,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null // Disable button when loading
                                : () {
                                    setState(() {
                                      isLoading = true;
                                    });

                                    addServices().then((_) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
//                     await ServicesProvidedState._auth.signOut(context);
//                     ServicesProvidedState._goToLogin(context);
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
// }
