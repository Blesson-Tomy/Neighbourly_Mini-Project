import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_ui/profile/changeservice.dart';
import 'package:mini_ui/screens/auth_service.dart';
import 'package:mini_ui/screens/screen_login.dart';
import 'package:mini_ui/splash.dart';
import 'editprofile.dart' as edit;
import '../styles/styles.dart';
import '../styles/custom_style.dart';// import 'roles.dart' as roles;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> with CustomStyle{

  static final _auth = AuthService();
  String _userName = "Loading..."; // Default until data loads
  String userType = "";
  String uid=""; // Default user type
  Map<String, dynamic> allData={};
  String guardianName = "";
  String requestId = "";
  bool hasRequest = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    fetchRequest();
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
  
  Map<String, dynamic> tempData = {}; // Temporary storage

  for (String key in prefs.getKeys()) {
    tempData[key] = prefs.get(key);
  }

    setState(() {
      _userName = prefs.getString('userName') ?? "User";
      userType = prefs.getString('userType')??"";
      uid = prefs.getString('userId')??""; 
      allData=tempData;// Fallback if not found
    });
  }

  Future<void> fetchRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');

    if (email == null || email.isEmpty) {
      debugPrint("No user email found in SharedPreferences.");
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('guardian_requests')
          .where('homeboundEmail', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        if(data['homeboundId'] != "") {
          setState(() {
            hasRequest = false;
            isLoading = false;
          });
          return;
        }
        setState(() {
          guardianName = data['guardianName'] ?? "Guardian";
          hasRequest = true;
          requestId = doc.id;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching guardian request: $e");
    }
  }

  Future<void> acceptRequest() async {
    try {
      setState(() {
        isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || requestId.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('guardian_requests').doc(requestId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        setState(() {
          hasRequest = false;
          isLoading = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This request has already been cancelled"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }

        return;
      }

      await docRef.update({'homeboundId': userId});

      final data = docSnapshot.data();
      await prefs.setString('guardianId', data?['guardianId'] ?? '');
      await prefs.setString('guardianName', data?['guardianName'] ?? '');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (Route<dynamic> route) => false,
      );

    } catch (e) {
      debugPrint("Error accepting request: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> rejectRequest() async {
    try {
      setState(() {
        isLoading = true;
      });
      if (requestId.isEmpty) {
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('guardian_requests').doc(requestId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        setState(() {
          hasRequest = false;
        });
        return;
      }

      await docRef.delete();

      setState(() {
        hasRequest = false;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error rejecting request: $e");
    }
  }

  static void _goToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LogInScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Styles.darkPurple,
      body: Stack(
        children:[ RefreshIndicator(
          onRefresh: fetchRequest,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Title Section
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.33,
                  child: const Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text("Profile", style: Styles.titleStyle),
                      ),
                    ],
                  ),
                ),
          
                if(hasRequest)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      alignment: Alignment.center,
                      height: deviceHeight * 0.3,
                      decoration: BoxDecoration(
                        color: Styles.lightPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                      child: isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 4,
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 30),
                                Text(
                                  'Accept "$guardianName" as guardian?',
                                  style: const TextStyle(fontSize: 18, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const Spacer(),
                                Center(
                                  child: SizedBox(
                                    width: deviceWidth - 76,
                                    child: ElevatedButton(
                                      onPressed: acceptRequest,
                                      style: TextButton.styleFrom(
                                        textStyle: buttonTextStyle,
                                        backgroundColor: Colors.green[400],
                                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Text(
                                        "Accept",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: SizedBox(
                                    width: deviceWidth - 76,
                                    child: ElevatedButton(
                                      onPressed: rejectRequest,
                                      style: TextButton.styleFrom(
                                        textStyle: buttonTextStyle,
                                        backgroundColor: Colors.red[400],
                                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Text(
                                        "Reject",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                    ),
                  ),
          
                if(hasRequest)
                const SizedBox(height: 20), // Space between the request box and the profile section
          
          
                // Content Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      // Profile Section Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: Styles.boxDecoration,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Profile Picture
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Styles.white,
                                  ),
                                  child: const Icon(Icons.person,
                                      size: 40, color: Colors.grey),
                                ),
                                const SizedBox(width: 16),
          
                                // Display logged-in user's name dynamically
                                Text(_userName, style: Styles.nameStyle),
                              ],
                            ),
          
                            // Edit Button
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          edit.EditProfilePage(userProfile: allData,)),
                                );
                              },
                              child: const Row(
                                children: [
                                  Text("Edit", style: Styles.buttonTextStyle),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios,
                                      size: 20, color: Styles.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
          
                      // Settings Section Box (Unchanged)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: Styles.boxDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Details",
                                style: Styles.settingsTitleStyle),
                            const SizedBox(height: 10),
                            Column(
                              children: [
                                buildInfoContainer("Name: ",value: _userName),
                                const SizedBox(height: 10),
                                buildInfoContainer("User Type: ",value: userType),
                                const SizedBox(height: 10),
                                buildInfoContainer("Email: ",value: allData["userEmail"]??""),
                                const SizedBox(height: 10),
                                buildInfoContainer("Address: ",value: allData["userAddress"]??""),
                                const SizedBox(height: 10),
                                userType=="volunteers"?buildInfoContainer("Services:",services: allData["services"]??[]):Container(),
          
                              ],
                            ),
                          ],
                        ),
                      ),
          
                      const SizedBox(height: 20),
          
                    if (userType == "volunteers") ...{
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        decoration: Styles.boxDecoration.copyWith(
                          color: Styles.lightPurple,
                        ),
                        child: TextButton(
                          onPressed: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ServicesProvided2()),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Change Services",
                                  style: TextStyle( fontSize: 16, color: Colors.white)),
                              Icon(Icons.change_circle, size: 26, color: Colors.white),
                            ],
                          ),
                        ),
                      ),},
          
                    const SizedBox(height: 20),
                      // Logout Section Box (Unchanged)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        decoration: Styles.boxDecoration.copyWith(
                          color: Styles.lightPurple,
                        ),
                        child: TextButton(
                          onPressed: () async {
                            showConfirmationDialog(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Log Out",
                                  style: Styles.buttonTextStyle
                                      .copyWith(fontSize: 16)),
                              Icon(Icons.logout, size: 26, color: Colors.red[400]),
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
        ),]
      ),
    );
  }
}

  // Function to build info container dynamically
Widget buildInfoContainer(String title, {String value = '', bool isRating = false, List<dynamic>? services}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: Styles.mildPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: services == null
            ? Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              runSpacing: 5,
              children: [
              Text(
                "$title ",
                style: Styles.bodyStyle,
              ),
              if (isRating)
                Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                  value,
                  style: Styles.bodyStyle,
                  ),
                  const SizedBox(width: 5),
                  Icon(
                  Icons.star,
                  color: Colors.yellow[500],
                  size: 20,
                  ),
                ],
                )
              else
                Text(
                value,
                style: Styles.bodyStyle,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$title ",
                  style: Styles.bodyStyle,
                ),
                const SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: services.map((service) => Text("• $service", style: Styles.bodyStyle)).toList(),
                ),
              ],
            ),
    );
  }


// Function to Create Buttons (Unchanged)
Widget settingsButton(String text) {
  return TextButton(
    onPressed: () {},
    style: Styles.settingsButtonStyle,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: Styles.buttonTextStyle),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Styles.white),
      ],
    ),
  );
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
          "Confirm Log Out",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to log out?",
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
                  onPressed: () async {
                    await ProfilePageState._auth.signOut(context);
                    ProfilePageState._goToLogin(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Log Out",
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

