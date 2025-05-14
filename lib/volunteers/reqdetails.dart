import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_ui/volunteers/homedetails.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/styles.dart';

class ReqDetailsPage extends StatefulWidget {
  final String requestId;

  const ReqDetailsPage({super.key, required this.requestId});

  @override
  State<ReqDetailsPage> createState() => _ReqDetailsPageState();
}

class _ReqDetailsPageState extends State<ReqDetailsPage> {
  Map<String, dynamic>? request;
  String status = "";

  @override
  void initState() {
    super.initState();
    fetchRequest();
  }

  Future<void> fetchRequest() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('current_requests')
          .doc(widget.requestId)
          .get();

      if (doc.exists) {
        setState(() {
          request = doc.data() as Map<String, dynamic>;
          status = request!["status"];
        });
      } else {
        setState(() {
          request = {}; // Empty map if no request found
        });
      }
    } catch (e) {
      setState(() {
        request = null; // Null signifies an error
      });
    }
  }

  void showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Styles.mildPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Confirm Acceptance",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: isLoading
                  ? const SizedBox(
                          height: 80,
                          width: 40,
                          child: Center(
                            child: Column(
                              children: [
                                SizedBox(height: 30,),
                                CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                                ),
                              ],
                            ),
                          ),
                        )
                  : const Text(
                      "Are you sure you want to accept this request?",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
              actions: isLoading
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
                                setState(() => isLoading = true);

                                try {

                                  final SharedPreferences prefs = await SharedPreferences.getInstance();
                                  final String? userId = prefs.getString("userId");

                                  await FirebaseFirestore.instance
                                    .collection("current_requests")
                                      .doc(widget.requestId)
                                      .update({
                                        "status": "Accepted",
                                        "volunteerId": userId, // Store userId as volunteerId
                                      }); // Update status instead of deleting

                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    fetchRequest(); // Close dialog
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Request accepted successfully",
                                          style: TextStyle(fontSize: 17),
                                        ),
                                        backgroundColor: Colors.green[400],
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setState(() => isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: ${e.toString()}"),
                                      backgroundColor: Colors.red,
                                    ),
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
                                "Accept Request",
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
    return Scaffold(
      backgroundColor: Styles.darkPurple,
      body: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.33,
                        child: Stack(
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: Text("Request Details ", style: Styles.titleStyle),
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
                      request == null
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : request!.isEmpty
                            ? const Center(
                                child: Text(
                                  "Request not found",
                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                ),
                              )
                      : Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildInfoContainer(request!["requestType"]),
                            const SizedBox(height: 10),
                            buildInfoContainer('Description:', value: request!["description"]),
                            const SizedBox(height: 10),
                            buildInfoContainer("Date:", value: request!["date"]),
                            const SizedBox(height: 10),
                            buildInfoContainer(
                              "Time:",
                              value: request!["date"] != null
                                  ? (DateTime.tryParse(request!["date"]) != null
                                      ? "${DateTime.parse(request!["date"]).day.toString().padLeft(2, '0')}-${DateTime.parse(request!["date"]).month.toString().padLeft(2, '0')}-${DateTime.parse(request!["date"]).year}"
                                      : "Invalid Date")
                                  : "N/A",
                            ),
                            const SizedBox(height: 10),
                            buildInfoContainer("Amount:", value: "${request!["amount"]} ₹"),
                            const SizedBox(height: 10),
                            buildInfoContainer("Volunteer Preference:", value: request!["volunteerGender"]),
                            const SizedBox(height: 10),
                            buildInfoContainer("Send To:", value: request!["requestAt"]),
                            const SizedBox(height: 10),
                            if (status == "Accepted") ...{
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(6, 4, 0, 4),
                                decoration: Styles.boxDecoration.copyWith(
                                  color: Styles.mildPurple,
                                ),
                                child: TextButton(
                                  onPressed: () async {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              HomeBoundDetailsPage(volunteerId: request!["homeboundId"])),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Home Bound Details",
                                          style: Styles.bodyStyle),
                                      Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),},
                            const SizedBox(height: 10),
                            buildInfoContainer("Status: ", value: request!["status"], isStatus: true),
                            const SizedBox(height: 26),
                            if (status == "Waiting") 
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: TextButton(
                                  onPressed: () {
                                    showConfirmationDialog(context);
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
                                      Icon(Icons.check, color: Colors.white, size: 26),
                                      SizedBox(width: 8),
                                      Text(
                                        "Accept Request",
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
    );
  }

  Widget buildInfoContainer(String title, {String value = '', bool isStatus = false}) {
    Color statusColor = Colors.yellow[500]!;
    String statusText = "";

    if (value == 'Accepted') {
      statusColor = const Color.fromARGB(255, 145, 255, 150);
      statusText = "You have accepted this request.\nComplete the request within specified time.";
    } else if (value == 'Waiting') {
      statusColor = Colors.yellow[500]!;
      statusText = "Waiting for volunteer";
    } else if (value == 'Pending Rating') {
      statusColor = Colors.blue[300]!;
      statusText = "Payment Completed. Waiting for Rating.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 20, 15),
      decoration: BoxDecoration(
        color: Styles.mildPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isStatus ? "Status: $statusText" : (value.isEmpty ? title : "⦿ $title $value"),
        style: value.isEmpty
            ? Styles.bodyStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold)
            : isStatus
                ? Styles.bodyStyle.copyWith(color: statusColor, fontWeight: FontWeight.bold)
                : Styles.bodyStyle,
      ),
    );
  }
}