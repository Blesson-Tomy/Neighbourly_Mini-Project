import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../styles/styles.dart';
import 'reqdetails.dart';

class VolReqHistoryPage extends StatefulWidget {
  const VolReqHistoryPage({super.key});

  @override
  VolReqHistoryPageState createState() => VolReqHistoryPageState();
}

class VolReqHistoryPageState extends State<VolReqHistoryPage> {
  List<DocumentSnapshot> requests = [];
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");

    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("completed_requests")
        .where("volunteerId", isEqualTo: userId)
        .get();

    setState(() {
      requests = snapshot.docs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.darkPurple, // Set background color
      body: Column(
        children: [
          // Title Section (Top One-Third)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.33,
            child: Stack(
              children: [
                // Title (Centered)
                const Align(
                  alignment: Alignment.center,
                  child: Text("Request History", style: Styles.titleStyle),
                ),
                // Back Button (Bottom-Left)
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

          // Request List Section (Bottom Two-Thirds)
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : requests.isEmpty
                    ? const Center(
                        child: Text(
                          "No completed requests found.",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                        child: ListView.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            var request = requests[index];
                            return RequestBox(
                              title: request["requestType"],
                              date: request["date"],
                              status: request["status"],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VolReqDetailsPage(requestId: request.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class RequestBox extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final VoidCallback? onTap;

  const RequestBox({
    super.key,
    required this.title,
    required this.date,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: Styles.boxDecoration,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Styles.nameStyle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Styles.buildPill("Date: $date", Styles.mildPurple),
                    const SizedBox(width: 5),
                    Styles.buildPill(status, status == "Completed" ? Colors.green[600]! : Colors.red[400]!),
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
