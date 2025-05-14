import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_ui/organization/volunteer.dart';
import 'package:mini_ui/request/rating.dart';
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
  bool isLoading = false;

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

  Future<void> moveToHistory() async {
    try {
      setState(() {
        isLoading = true;
      });
      // Reference to the current request document
      DocumentReference requestDoc = FirebaseFirestore.instance
          .collection("current_requests")
          .doc(widget.requestId);

      // Get the document data
      DocumentSnapshot snapshot = await requestDoc.get();

      if (snapshot.exists) {
        // Get the request data and update the status
        Map<String, dynamic> requestData = snapshot.data() as Map<String, dynamic>;
        requestData["status"] = "Completed";

        // Move the document to completed_requests with updated status
        await FirebaseFirestore.instance
            .collection("completed_requests")
            .doc(snapshot.id)
            .set(requestData);

        // Delete the original document from current_requests
        await requestDoc.delete();
      }
    } catch (e) {
      print("Error moving request to history: $e");
    }
  }


  void showPaymentDialog(BuildContext context,String amount,String volunteerId) {
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
                "Confirm Payment",
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
                      "Are you sure you want to pay the specified amount?",
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
                                  int amountInt = double.parse(amount).toInt();

                                  // Get userId from SharedPreferences
                                  final prefs = await SharedPreferences.getInstance();
                                  String? userId = prefs.getString("userId");

                                  if (userId != null) {
                                    // Reference to the user's document in Firestore
                                    DocumentReference userDoc = FirebaseFirestore.instance.collection("homebound").doc(userId);

                                    // Get the current amount from Firestore
                                    DocumentSnapshot snapshot = await userDoc.get();
                                    if (snapshot.exists) {
                                      int currentAmount = (snapshot.get("amount") ?? 0).toInt();

                                      // Calculate the new amount
                                      int newAmount = currentAmount - amountInt;

                                      // Update Firestore
                                      await userDoc.update({"amount": newAmount});

                                      // Update SharedPreferences
                                      await prefs.setInt("amount", newAmount);
                                    }

                                    DocumentReference requestDoc = FirebaseFirestore.instance.collection("current_requests").doc(widget.requestId);

                                    // Get the current amount from Firestore
                                    DocumentSnapshot requestsnapshot = await userDoc.get();
                                    if(requestsnapshot.exists) {
                                      await requestDoc.update({"status": "Pending Rating"});
                                    }
                                    // Reference to the volunteer's document in Firestore (volunteers)
                                    DocumentReference volunteerDoc = FirebaseFirestore.instance.collection("volunteers").doc(volunteerId);

                                    // Get the current amount from Firestore for volunteer
                                    DocumentSnapshot volunteerSnapshot = await volunteerDoc.get();
                                    if (volunteerSnapshot.exists) {
                                      int volunteerAmount = (volunteerSnapshot.get("amount") ?? 0).toInt();

                                      // Calculate the new amount (adding instead of subtracting)
                                      int updatedVolunteerAmount = volunteerAmount + amountInt;

                                      // Update Firestore for volunteer
                                      await volunteerDoc.update({"amount": updatedVolunteerAmount});
                                    }
                                  }
                                //   await FirebaseFirestore.instance
                                //       .collection("current_requests")
                                //       .doc(widget.requestId)
                                //       .delete();

                                //   if(context.mounted) {
                                //       Navigator.of(context).pop();
                                //   }

                                  if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        "Payment successfull.",
                                      style: TextStyle(fontSize: 17),
                                      ),
                                      backgroundColor:Colors.green[400],
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                                    ),
                                  );
                                  // setState(() => isLoading = false);
                                }
                                } catch (e) {
                                  setState(() => isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: ${e.toString()}"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  fetchRequest(); // Refresh the request data
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.green[400],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                "Pay ₹ $amount",
                                style: const TextStyle(
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
                "Confirm Cancellation",
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
                      "Are you sure you want to cancel this request?",
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
                                "Do Not Cancel",
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
                                  await FirebaseFirestore.instance
                                      .collection("current_requests")
                                      .doc(widget.requestId)
                                      .delete();

                                  if(context.mounted) {
                                      Navigator.of(context).pop();
                                  }

                                  if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        "Request cancelled successfully",
                                      style: TextStyle(fontSize: 17),
                                      ),
                                      backgroundColor:Colors.green[400],
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
                                backgroundColor: Colors.red[400],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Cancel Request",
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
                      (request == null || isLoading)
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
                            buildInfoContainer("Amount:", value: "₹ ${request!["amount"]}"),
                            const SizedBox(height: 10),
                            buildInfoContainer("Volunteer Preference:", value: request!["volunteerGender"]),
                            const SizedBox(height: 10),
                            buildInfoContainer("Send To:", value: request!["requestAt"]),
                            const SizedBox(height: 10),
                            buildInfoContainer("Status: ", value: request!["status"], isStatus: true),
                            const SizedBox(height: 10),
                            if (status == "Accepted" || status == "Pending Rating") ...{
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
                                              VolunteerDetailsPage(volunteerId: request!["volunteerId"])),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Volunteer Details",
                                          style: Styles.bodyStyle),
                                      Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),},
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: () {
                                if (status == "Waiting") {
                                  return TextButton(
                                    onPressed: () => showConfirmationDialog(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: const BorderSide(color: Styles.offWhite, width: 2),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.cancel, color: Colors.white, size: 26),
                                        SizedBox(width: 8),
                                        Text(
                                          "Cancel Request",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (status == "Accepted") {
                                  return TextButton(
                                    onPressed: () => showPaymentDialog(context, request!["amount"], request!["volunteerId"]),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[500],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: const BorderSide(color: Styles.offWhite, width: 2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.payment, color: Colors.white, size: 26),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Pay ₹ ${request!["amount"]}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (status == "Pending Rating") {
                                  return TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RateVolunteerPage(volunteerId: request!["volunteerId"]),
                                        ),
                                      ).then((_) async {
                                        await moveToHistory();
                                        if (mounted) {
                                          Navigator.pop(context);
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[300],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: const BorderSide(color: Styles.offWhite, width: 2),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, color: Colors.white, size: 26),
                                        SizedBox(width: 8),
                                        Text(
                                          "Rate Volunteer",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  return const SizedBox.shrink(); // Return an empty widget if no condition matches
                                }
                              }(),
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
      statusText = "Accepted by a volunteer";
    } else if (value == 'Waiting') {
      statusColor = Colors.yellow[500]!;
      statusText = "Waiting for volunteer";
    } else if (value == 'Pending Rating') {
      statusColor = Colors.blue[300]!;
      statusText = "Request & Payment completed";
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