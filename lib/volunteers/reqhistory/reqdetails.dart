import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../styles/styles.dart';

class VolReqDetailsPage extends StatefulWidget {
  final String requestId;

  const VolReqDetailsPage({super.key, required this.requestId});

  @override
  _VolReqDetailsPageState createState() => _VolReqDetailsPageState();
}

class _VolReqDetailsPageState extends State<VolReqDetailsPage> {
  Map<String, dynamic>? requestDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  Future<void> _fetchRequestDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("completed_requests")
          .doc(widget.requestId)
          .get();

      if (doc.exists) {
        setState(() {
          requestDetails = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          requestDetails = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        requestDetails = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.darkPurple, // Set background color
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : requestDetails == null
              ? const Center(
                  child: Text(
                    "Request details not found.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Title Section (Top One-Third)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.33,
                        child: Stack(
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: Text("Request Details", style: Styles.titleStyle),
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
                            buildInfoContainer(requestDetails!["requestType"] ?? "No Title"),
                            const SizedBox(height: 10),
                            buildInfoContainer("Description:", value: requestDetails!["description"] ?? "No Description"),
                            const SizedBox(height: 10),
                            buildInfoContainer("Request Created:", value: requestDetails!["date"] ?? "Unknown"),
                            const SizedBox(height: 10),
                            buildInfoContainer("Time:", value: requestDetails!["time"] ?? "Unknown"),
                            const SizedBox(height: 10),
                            buildInfoContainer("Amount:", value: "${requestDetails!["amount"] ?? "0"} ₹"),
                            const SizedBox(height: 10),
                            buildInfoContainer("Status:", value: requestDetails!["status"] ?? "Unknown", isStatus: true),
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

    if (value == 'Completed') {
      statusColor = const Color.fromARGB(255, 145, 255, 150);
    } else if (value == 'Cancelled') {
      statusColor = const Color.fromARGB(255, 255, 103, 92);
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
            ? Styles.bodyStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold)
            : isStatus
                ? Styles.bodyStyle.copyWith(color: statusColor, fontWeight: FontWeight.bold)
                : Styles.bodyStyle,
      ),
    );
  }
}
