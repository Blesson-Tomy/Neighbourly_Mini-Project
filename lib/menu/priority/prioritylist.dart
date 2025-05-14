import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore package
import 'package:mini_ui/menu/menu.dart';
import 'package:mini_ui/menu/priority/volremove.dart';
import 'package:mini_ui/navbar.dart';
import 'package:mini_ui/organization/volunteerlist.dart';
import '../../../styles/styles.dart';
import 'searchvol.dart';

class PriorityPage extends StatefulWidget {
  const PriorityPage({super.key});

  @override
  _PriorityPageState createState() => _PriorityPageState();
}

class _PriorityPageState extends State<PriorityPage> {
  late Future<List<Map<String, String>>> _volunteersFuture;

  @override
  void initState() {
    super.initState();
    _volunteersFuture = fetchVolunteers();
  }

  Future<void> _refreshVolunteers() async {
    setState(() {
      _volunteersFuture = fetchVolunteers();
    });
  }

  Future<List<Map<String, String>>> fetchVolunteers() async {
    List<Map<String, String>> volunteers = [];
    try {
      // Fetch homebound collection
      QuerySnapshot homeboundSnapshot =
          await FirebaseFirestore.instance.collection('homebound').get();

      // Extract volunteer IDs
      List<String> volunteerIds = homeboundSnapshot.docs
          .where((doc) =>
              doc.data() != null &&
              (doc.data() as Map<String, dynamic>)
                  .containsKey('volunteerId')) // Check if field exists
          .expand((doc) {
            var ids = (doc['volunteerId'] as List<dynamic>?) ?? [];
            return ids.map((id) => id.toString());
          })
          .toSet() // Remove duplicates
          .toList();

      // Fetch volunteer details for each ID
      for (String id in volunteerIds) {
        DocumentSnapshot volunteerDoc = await FirebaseFirestore.instance
            .collection('volunteers')
            .doc(id)
            .get();

        if (volunteerDoc.exists) {
          Map<String, dynamic> data =
              volunteerDoc.data() as Map<String, dynamic>;
          volunteers.add({
            "name": data['name'] ?? 'Unknown',
            "age": data['age']?.toString() ?? 'N/A',
            "gender": data['gender'] ?? 'N/A',
            "rating": data['rating']?.toString()??'N/A', // Dummy rating
            "address": data['address'] ?? 'Address not available',
            "volunteerId":
                volunteerDoc.id, // Use the volunteer ID from the document
          });
        }
      }
    } catch (e) {
      print("Error fetching volunteers: $e");
    }
    return volunteers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.darkPurple, // Set background color
      body: Stack(
        children: [
          Column(
            children: [
              // Title Section
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.33,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Volunteer\nPriority List",
                        style: Styles.titleStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: BackButton(
                        color: Styles.white,
                        onPressed: () {
                          Navigator.pop(
                            context);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Request Cards Section
              Expanded(
                child: FutureBuilder<List<Map<String, String>>>(
                  future: _volunteersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Center the CircularProgressIndicator with adjusted position
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(flex: 2), // Push the indicator slightly up
                          const CircularProgressIndicator(),
                          Spacer(flex: 3), // Balance the remaining space
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text("Error loading data"),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("No volunteers found"),
                      );
                    }

                    List<Map<String, String>> requests = snapshot.data!;

                    return RefreshIndicator(
                      onRefresh: _refreshVolunteers,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                            bottom: 100), // Avoid overlapping with button
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Volremove(requestDetails: request),
                                ),
                              ).then((_) => _refreshVolunteers());
                            },
                            child: VolunteerBox(
                              title: request["name"]!,
                              age: request["age"]!,
                              gender: request["gender"]!,
                              rating: request["rating"]!,
                              address: request["address"]!,
                              volunteerId: request["volunteerId"]!,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Fixed "New Request" Button Above Navbar
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                  bottom: 30), // Adjust position above navbar
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 30,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SearchVolunteerPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.mildPurple,
                    elevation: 10, // Increased elevation for a stronger shadow
                    shadowColor: Colors.black, // Darker and more visible shadow
                    padding: const EdgeInsets.symmetric(
                        vertical:
                            10), // Removed horizontal padding to fit width
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                          color: Color.fromARGB(255, 209, 209, 209), width: 3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Keep button size compact
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center text and icon
                    children: [
                      const Icon(Icons.add,
                          color: Colors.white, size: 40), // Plus icon
                      const SizedBox(width: 8), // Space between icon and text
                      const Text("Add Volunteer",
                          style: Styles.buttonTextStyle),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VolunteerBox extends StatelessWidget {
  final String title;
  final String age;
  final String gender;
  final String rating;
  final String address;
  final String volunteerId; // Dummy volunteer ID
  final VoidCallback? onTap; // Callback for button press

  const VolunteerBox({
    super.key,
    required this.title,
    required this.age,
    required this.gender,
    required this.rating,
    required this.address,
    required this.volunteerId, // Dummy volunteer ID
    this.onTap, // Allows passing a function when tapped
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Volremove(requestDetails: {
                    "volunteerId": volunteerId,
                    "name": title,
                    "age": age,
                    "gender": gender,
                    "rating": rating,
                    "address": address,
                  })),
        );
      }, // Trigger the callback when tapped
      child: Container(
        decoration:
            Styles.boxDecoration, // Use the same decoration as Profile Page
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
              child:
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
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
