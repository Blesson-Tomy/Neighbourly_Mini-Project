import 'package:flutter/material.dart';
import '../styles/styles.dart';
import 'reqdetails.dart';
import 'newreq.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  RequestsPageState createState() => RequestsPageState();
}

class RequestsPageState extends State<RequestsPage> {
  List<Map<String, dynamic>> requests = []; // State variable to store fetched requests
  bool isLoading = true; // State to track loading status
  String errorMessage = ""; // State to store error message

  @override
  void initState() {
    super.initState();
    fetchAllRequests(); // Call the function when the page is rendered
  }

  Future<void> fetchAllRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          errorMessage = "User not logged in";
          isLoading = false;
        });
      }
      return;
    }

    // Check for internet connection
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        setState(() {
          errorMessage = "No network connection. Try again later.";
          isLoading = false;
        });
      }
      return;
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('current_requests')
          .where('homeboundId', isEqualTo: user.uid)
          .get();

      if (mounted) {
        setState(() {
          requests = querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .toList();

          // Sort the requests by timestamp in descending order
          requests.sort((a, b) {
            final timestampA = a['timestamp'] ?? 0;
            final timestampB = b['timestamp'] ?? 0;
            return timestampB.compareTo(timestampA);
          });

          isLoading = false;
          errorMessage = requests.isEmpty ? "No current requests." : "success"; // Show message if no requests
        });
      }
    } catch (e) {
      debugPrint("Error while fetching data: $e");
      if (mounted) {
        setState(() {
          errorMessage = "An error occurred. Try again later.";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.darkPurple, // Set background color
      body: Stack(
        children: [
          // Scrollable Request List wrapped in RefreshIndicator
          RefreshIndicator(
            onRefresh: fetchAllRequests, // Call fetchAllRequests when pulled to refresh
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100), // Avoid overlapping with button
              physics: const AlwaysScrollableScrollPhysics(), // Ensure scrollable even if content is less
              child: Column(
                children: [
                  // Title Section
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.33,
                    child: const Center(
                      child: Text("Requests", style: Styles.titleStyle),
                    ),
                  ),

                  // Request Cards Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ) // Show loading indicator
                        : errorMessage == "success"
                            ? Column(
                                children: requests.map((request) {
                                  return RequestBox(request: request,onRefresh: fetchAllRequests,);
                                }).toList(),
                              )
                            : Center(
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Styles.mildPurple,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    errorMessage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed "New Request" Button Above Navbar
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0), // Adjust position above navbar
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 24, // Full screen width minus 20 pixels
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Make the column take maximum width
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NewRequestPage()),
                        ).then((_) {
                          if (mounted) {
                            setState(() {
                              isLoading = true;
                            });
                          }
                          // Reload the data when returning to this page
                          fetchAllRequests();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Styles.mildPurple,
                        elevation: 10, // Increased elevation for a stronger shadow
                        shadowColor: Colors.black, // Darker and more visible shadow
                        padding: const EdgeInsets.symmetric(vertical: 8), // Removed horizontal padding to fit width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color.fromARGB(255, 209, 209, 209), width: 3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min, // Keep button size compact
                        mainAxisAlignment: MainAxisAlignment.center, // Center text and icon
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 40), // Plus icon
                          SizedBox(width: 8), // Space between icon and text
                          Text("New Request", style: Styles.buttonTextStyle),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width, // Full device width
                      height: 10, // Fixed height
                      color: Styles.darkPurple, // Dark purple color
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RequestBox extends StatelessWidget {
  final Map<String, dynamic> request; // Request object containing all data
  final VoidCallback? onTap;
  final VoidCallback onRefresh; // Callback for button press

  const RequestBox({
    super.key,
    required this.request,
    this.onTap,
    required this.onRefresh, // Allows passing a function when tapped
  });

  @override
  Widget build(BuildContext context) {
    final String title = request["requestType"] ?? "Unknown";
    final String time = request["time"] ?? "N/A";
    final String date = request["date"] != null
        ? (DateTime.tryParse(request["date"]) != null
            ? "${DateTime.parse(request["date"]).day.toString().padLeft(2, '0')}-${DateTime.parse(request["date"]).month.toString().padLeft(2, '0')}-${DateTime.parse(request["date"]).year.toString().substring(2)}"
            : "Invalid Date")
        : "N/A";
    final String status = request["status"] ?? "Unknown";
    final String amount = "${request["amount"] ?? "0.00"} ₹";
    final String requestId = request["id"] ?? "";

    return TextButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReqDetailsPage(requestId: requestId),
          ),
        );
        if (context.mounted) {
          onRefresh(); // Call the callback when returning
        }
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
                  Text(title, style: Styles.nameStyle, softWrap: true, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  // Time, Date, and Status Pills (Auto-wrap)
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 5, // Space between pills
                    runSpacing: 5, // Space between wrapped rows
                    children: [
                      Styles.buildPill("Time: $time", Styles.mildPurple),
                      Styles.buildPill("Date: $date", Styles.mildPurple),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 5, // Space between pills
                    runSpacing: 5, // Space between wrapped rows
                    children: [
                      Styles.buildPill("Amount: $amount", Styles.mildPurple),
                      Styles.buildPill(status, status == "Accepted" 
                        ? Colors.green[500]! 
                        : status == "Pending Rating" 
                            ? Colors.blue[300]! 
                            : Colors.orange[600]!,),
                    ],
                  ),
                ],
              ),
            ),

            // Right side: Fixed-size Forward arrow icon
            const SizedBox(
              width: 30, // Set fixed width for arrow
              child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
