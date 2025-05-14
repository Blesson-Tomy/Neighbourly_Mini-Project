import 'package:flutter/services.dart';
import 'package:mini_ui/navbar.dart';
import 'package:mini_ui/splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../styles/custom_style.dart';
import 'package:flutter/material.dart';
import '../../styles/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectHomeBound extends StatefulWidget {
  const ConnectHomeBound({super.key});

  @override
  ConnectHomeBoundState createState() => ConnectHomeBoundState();
}

class ConnectHomeBoundState extends State<ConnectHomeBound> with CustomStyle {
  final TextEditingController homeboundEmailController= TextEditingController();
  final TextEditingController addressController = TextEditingController();
  bool isLoading = false;
  String organizationType = "NSS"; // Default value for dropdown
  bool isCancelling = false;
  bool isPageLoading = true; // Flag to indicate if the page is loading
  bool hasSent = false;
  String sentEmail = "";

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hasSent = prefs.getBool('hasSent') ?? false;
      sentEmail = prefs.getString('sentEmail') ?? "";
    });
    hasAlreadySent();
  }

  Future<void> hasAlreadySent() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      debugPrint("Error: User ID not found in SharedPreferences");
      return;
    }

    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('guardian_requests')
          .where('guardianId', isEqualTo: userId)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        setState(() {
          hasSent = true;
          sentEmail = doc['homeboundEmail'] ?? "";
        });

        // Save to SharedPreferences as well
        await prefs.setBool('hasSent', true);
        await prefs.setString('sentEmail', sentEmail);
      }
    } catch (e) {
      debugPrint("Error checking existing request: $e");
    } finally {
      setState(() {
        isPageLoading = false; // Set loading to false after checking
      });
    }
  }

  Future<void> sendRequest() async {
    String email = homeboundEmailController.text.trim();

    if (email.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        final userName = prefs.getString('userName');

        if (userId == null) {
          debugPrint("Error: User ID not found in SharedPreferences");
          return;
        }

        // Check if the homebound email exists
        QuerySnapshot homeboundQuery = await FirebaseFirestore.instance
            .collection('homebound')
            .where('email', isEqualTo: email)
            .get();

        if (homeboundQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No account found with this email.')),
          );
          return;
        }

        // Check if a request has already been sent to this homebound email by anyone
        QuerySnapshot existingRequestQuery = await FirebaseFirestore.instance
            .collection('guardian_requests')
            .where('homeboundEmail', isEqualTo: email)
            .get();

        if (existingRequestQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Someone else already sent a request.')),
          );
          return;
        }

        // Proceed to send the request
        await FirebaseFirestore.instance.collection('guardian_requests').add({
          'guardianId': userId,
          'guardianName': userName,
          'homeboundEmail': email,
          'homeboundId': "",
          'timestamp': FieldValue.serverTimestamp(),
        });

        await prefs.setBool('hasSent', true);
        await prefs.setString('sentEmail', email);
        setState(() {
          hasSent = true;
          sentEmail = email;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent successfully!')),
        );
      } catch (e) {
        debugPrint("Error sending request: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown error occurred. Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email.')),
      );
    }
  }

Future<void> removeRequest(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final sentEmail = prefs.getString('sentEmail');
  final userId = prefs.getString('userId');

  if (sentEmail != null && userId != null) {
    try {
      final query = await FirebaseFirestore.instance
          .collection('guardian_requests')
          .where('homeboundEmail', isEqualTo: sentEmail)
          .get();

      if (query.docs.isEmpty) {
        // No request found, reset prefs
        await prefs.remove('sentEmail');
        await prefs.setBool('hasSent', false);
        setState(() {
          hasSent = false;
        });
        return;
      }

      for (var doc in query.docs) {
        final data = doc.data();
        if (data.containsKey('homeboundId') && data['homeboundId'].toString().isNotEmpty) {
          // Already accepted, show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This request has already been accepted."),
              backgroundColor: Styles.lightPurple,
            ),
          );
          return;
        }

        await FirebaseFirestore.instance
            .collection('guardian_requests')
            .doc(doc.id)
            .delete();
      }

      await prefs.remove('sentEmail');
      await prefs.setBool('hasSent', false);
    } catch (e) {
      debugPrint("Error deleting request from Firestore: $e");
    }
  }
}

  Future<void> continueRequest() async {
    try {

      setState(() {
        isLoading = true; // Set loading to true while fetching data
      });
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId');

      if (uid == null || uid.isEmpty) {
        debugPrint("No guardian id found in SharedPreferences.");
        return;
      }

      // Search for the request document using the stored email
      final query = await FirebaseFirestore.instance
          .collection('guardian_requests')
          .where('guardianId', isEqualTo: uid)
          .get();

      if (query.docs.isEmpty) {
        debugPrint("No matching request found.");
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();

      print(data);

      if (data['homeboundId'] != "") {

        await prefs.setString('guardianId', data['guardianId'] ?? '');
        await prefs.setString('guardianName', data['guardianName'] ?? '');
        await prefs.setString('homeboundId', data['homeboundId'] ?? '');
        // Pop all previous pages and go to SplashScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request has not been accepted yet.'),
        backgroundColor: Styles.lightPurple,),
        );
        debugPrint("Request found but not yet accepted.");
      }

      setState(() {
        isLoading = false; // Set loading to false after fetching data
      });
    } catch (e) {
      debugPrint("Error continuing request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
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
          keyboardType: TextInputType.emailAddress, // Email structure keyboard
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email, color: Colors.white),
            hintText: 'homebound@email.com',
            hintStyle: const TextStyle(color: Colors.white54),
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
                          child: Text("Connect with HomeBound",
                              style: Styles.titleStyle,
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      alignment: Alignment.center,
                      height: deviceHeight * 0.4,
                      decoration: BoxDecoration(
                        color: Styles.mildPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                      child: isPageLoading? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 4,
                        ),
                      )
                      :Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hasSent) ...[
                            const Text(
                              "Enter email of the homebound's account.\nThen go to the profile in the homebound's account and accept the request.",
                              style: TextStyle(fontSize: 17, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            _buildPrompt("Homebound Email:", homeboundEmailController),
                          ] else ...[
                            const SizedBox(height: 30),
                            Text(
                              'The request has been sent to HomeBound with email "$sentEmail"\nAccept the request in the homebound\'s Profile Page and press Continue.',
                              style: const TextStyle(fontSize: 17, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const Spacer(),
                          if (!hasSent) ...[
                            Center(
                              child: SizedBox(
                                width: deviceWidth - 76,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            isLoading = true;
                                          });

                                          sendRequest().then((_) {
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
                                      : const Text(
                                          "Send Request",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                            ),
                          ] else ...[
                            if(!isCancelling)
                            Center(
                              child: SizedBox(
                                width: deviceWidth - 76,
                                child: ElevatedButton(
                                  onPressed: isLoading? null: continueRequest,
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
                                      : const Text(
                                          "Continue",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if(!isLoading)
                            Center(
                              child: SizedBox(
                                width: deviceWidth - 76,
                                child: ElevatedButton(
                                  onPressed: isCancelling
                                      ? null
                                      : () {
                                          setState(() {
                                            isCancelling = true;
                                          });

                                          removeRequest(context).then((_) {
                                            setState(() {
                                              isCancelling = false;
                                              hasSent = false;
                                              sentEmail = "";
                                            });
                                          });
                                        },
                                  style: TextButton.styleFrom(
                                    textStyle: buttonTextStyle,
                                    backgroundColor: Colors.red[400],
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: isCancelling
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "Cancel Request",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}