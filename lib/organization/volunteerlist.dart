import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../styles/styles.dart';
import 'volunteer.dart';

class VolunteerListPage extends StatefulWidget {
  const VolunteerListPage({super.key});

  @override
  _VolunteerListPageState createState() => _VolunteerListPageState();
}

class _VolunteerListPageState extends State<VolunteerListPage> {
  List<Map<String, dynamic>> requests=[];
  // Placeholder for userId
  bool isLoading = true; // Loading state for the page
  @override
  void initState() {
    super.initState();
    // Simulate a network call to fetch data
    fetchdata();
  }

  Future<void> fetchdata() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId')??"";
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('volunteers')
          .where('orgId', isEqualTo: userId)
          .get();
      requests = querySnapshot.docs.map((doc) 
                      => 
                      // Convert the document data to a Map<String, dynamic>
                      // and cast it to the appropriate type
                      // Use doc.data() as Map<String, dynamic> to ensure type safety
                      // and avoid runtime errors.
                      // This is a workaround for the null safety issue in Dart.
                      // You can also use doc.data()! if you are sure that the data is not null.
                      // But using doc.data() as Map<String, dynamic> is safer.
                doc.data() as Map<String,dynamic>
                      
                      ).toList();
      print(requests);
        setState(() {
      isLoading = false; // Update loading state
    });
      
    } catch (e) {
      debugPrint("Error fetching Firestore data: $e");
    } // Simulate network delay
  
  }
  // Dummy JSON list of requests
  

  @override
  Widget build(BuildContext context) {
  if(isLoading) {
    return const Scaffold(
      backgroundColor: Styles.darkPurple, // Set background color
      body: Center(
        child: CircularProgressIndicator(color: Styles.mildPurple), // Loading indicator
      ),
    );
  }
  else{
    return Scaffold(
      backgroundColor: Styles.darkPurple, // Set background color
      body: Stack(
        children: [
          // Scrollable Request List
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Avoid overlapping with button
            child: Column(
              children: [
                // Title Section
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.33,
                  child: const Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Volunteers",
                          style: Styles.titleStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Request Cards Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                  child: Column(
                    children: requests.map((request) {
                      return VolunteerBox(
                                 title: request["name"]?.toString() ?? "Unknown",
                                  age: request["age"]?.toString() ?? "N/A",
                                  gender: request["gender"]?.toString() ?? "N/A",
                                  rating: request["rating"]?.toString() ?? "0",
                                  userId: request["uid"]?.toString() ?? "Unknown",
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );}
  }
}

class VolunteerBox extends StatelessWidget {
  final String title;
  final String age;
  final String gender;
  final String rating;
  final VoidCallback? onTap;
  final String userId;// Callback for button press

  const VolunteerBox({
    super.key,
    required this.title,
    required this.age,
    required this.gender,
    required this.rating,
    this.onTap,
    required this.userId // Allows passing a function when tapped
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VolunteerDetailsPage(volunteerId:userId)),
        );
      }, // Trigger the callback when tapped
      child: Container(
        decoration: Styles.boxDecoration, // Use the same decoration as Profile Page
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10), // Internal padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Request details (Flexible)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Styles.nameStyle,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  // Time, Date, and Status Pills (Auto-wrap)
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 5, // Space between pills
                    runSpacing: 5, // Space between wrapped rows
                    children: [
                      buildPill("Age: $age", Styles.mildPurple),
                      buildPill(gender, Styles.mildPurple),
                      buildPill("Rating: $rating", Styles.mildPurple,
                          isRating: true),
                    ],
                  ),
                ],
              ),
            ),

            // Right side: Fixed-size Forward arrow icon
            const SizedBox(
              width: 30, // Set fixed width for arrow
              child: Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildPill(String text, Color color, {bool isRating = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
    decoration: BoxDecoration(
      color: color, // Use the passed color for background
      borderRadius: BorderRadius.circular(20), // Rounded pill shape
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: Styles.buttonTextStyle
              .copyWith(fontSize: 14, color: Colors.white),
        ),
        if (isRating) ...[
          const SizedBox(width: 4),
          const Icon(Icons.star, color: Colors.yellow, size: 14),
        ],
      ],
    ),
  );
}