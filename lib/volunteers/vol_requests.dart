import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/styles.dart';
import 'reqdetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// final config = Config();
String apiKey = 'AIzaSyCGeJBG4e82liskoLF4cqY-vDXz1wJUexQ';  //config.apiKey;

const String geminiEndpoint = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent';

class VolRequestsPage extends StatefulWidget {
  const VolRequestsPage({super.key});

  @override
  RequestsPageState createState() => RequestsPageState();
}

class RequestsPageState extends State<VolRequestsPage> {
  final ValueNotifier<List<Map<String, dynamic>>> requestsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<String> errorMessageNotifier = ValueNotifier("");

  @override
  void initState() {
    super.initState();
    fetchAllRequests();
  }

  Future<void> fetchAllRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      errorMessageNotifier.value = "User not logged in";
      isLoadingNotifier.value = false;
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      errorMessageNotifier.value = "No network connection. Try again later.";
      isLoadingNotifier.value = false;
      return;
    }

    try {
        final prefs = await SharedPreferences.getInstance();
  String? neighbourhoodId = prefs.getString('neighbourhoodId') ?? "";
  List<String> selectedServices = prefs.getStringList('services') ?? [];
  String? userId = prefs.getString('userId') ?? "";
  // Fetch neighbourhood-matching requests
  QuerySnapshot querySnapshot1 = await FirebaseFirestore.instance
      .collection('current_requests')
      .where('neighbourhood', isEqualTo: neighbourhoodId)
      .get();

  // Fetch priority list-matching requests
  QuerySnapshot querySnapshot2 = await FirebaseFirestore.instance
      .collection('current_requests')
      .where('priority', arrayContains: userId)
      .get();

  // Use a Set to track unique document IDs
  Set<String> documentIds = {};
  List<Map<String, dynamic>> fetchedRequests = [];

  // Add documents from the first query
  for (var doc in querySnapshot1.docs) {
    if (documentIds.add(doc.id)) { // Ensures uniqueness
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      fetchedRequests.add(data);
    }
  }

  // Add documents from the second query (avoiding duplicates)
  for (var doc in querySnapshot2.docs) {
    if (documentIds.add(doc.id)) { // Ensures uniqueness
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      fetchedRequests.add(data);
    }
  }

  // fetchedRequests.where((doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return selectedServices.contains(data['requestType']);
  // });

  fetchedRequests = fetchedRequests
    .where((doc) => selectedServices.contains(doc['requestType']))
    .toList();

  fetchedRequests = fetchedRequests
    .where((doc) => selectedServices.contains(doc['requestType']) &&
                    (doc['volunteerId'] == "" || doc['volunteerId'] == userId))
    .toList();



  // Sort by timestamp (newest first)
  fetchedRequests.sort((a, b) {
    final timestampA = a['timestamp'] ?? 0;
    final timestampB = b['timestamp'] ?? 0;
    return timestampB.compareTo(timestampA);
  });

  // Update UI
  requestsNotifier.value = fetchedRequests;
  errorMessageNotifier.value = fetchedRequests.isEmpty ? "No new requests." : "success";
} catch (e) {
  errorMessageNotifier.value = "An error occurred. Try again later.";
}



    finally {
      isLoadingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.darkPurple,
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchAllRequests();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.33,
                child: const Center(
                  child: Text("Requests", style: Styles.titleStyle),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isLoadingNotifier,
                builder: (context, isLoading, _) {
                  return isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : ValueListenableBuilder<String>(
                          valueListenable: errorMessageNotifier,
                          builder: (context, errorMessage, _) {
                            return errorMessage == "success"
                                ? ValueListenableBuilder<List<Map<String, dynamic>>>(
                                    valueListenable: requestsNotifier,
                                    builder: (context, requests, _) {
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                                        child: Column(
                                          children: requests.map((request) {
                                            return RequestBox(request: request, onRefresh: fetchAllRequests,);
                                          }).toList(),
                                        ),
                                      );
                                    },
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
                                  );
                          },
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestBox extends StatefulWidget {
  final Map<String, dynamic> request; // Request object containing all data
  final VoidCallback? onTap; // Callback for button press
  final VoidCallback onRefresh;

  const RequestBox({
    super.key,
    required this.request,
    this.onTap, // Allows passing a function when tapped
    required this.onRefresh,
  });

  @override
  State<RequestBox> createState() => _RequestBoxState();
}

class _RequestBoxState extends State<RequestBox> {
  bool isLoading = true; // State to track loading status
  List<String>? keywords; // Variable to store extracted keywords

  Future<List<String>> extractKeywords(String inputText) async {
    WidgetsFlutterBinding.ensureInitialized();

    final payload = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  " Example 1: I need help to buy groceries from the towncenter. The keywords here are: Buy, Groceries, Towncenter. Example 2: I need help to fetch my pet from the vet. The keywords here are: Fetch, Pet, Vet. Based on the given example, extract keywords(at most 4 keywords, first letter should be upper case) from the following text and return them in a JSON list: \"$inputText\"",
            },
          ],
        },
      ],
    };

    final headers = {'Content-Type': 'application/json'};

    try {
      
      if (widget.request['tags'] is List && (widget.request['tags'] as List).isNotEmpty) {
        return List<String>.from(widget.request['tags']);
      }

      final response = await http.post(
        Uri.parse('$geminiEndpoint?key=$apiKey'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final keywords = List<String>.from(
          data["candidates"][0]["content"]["parts"][0]["text"]
              .replaceAll(RegExp(r'^```json|```|\[|\]'), '')
              .replaceAll('"', '')
              .split(','),
        );

        if (keywords.isNotEmpty) {
          final userDocRef = FirebaseFirestore.instance
          .collection("current_requests")
          .doc(widget.request["id"]);
          await userDocRef.set({'tags': keywords}, SetOptions(merge: true));
        }
        return keywords.map((keyword) => keyword.trim()).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    extractKeywords(widget.request["description"] ?? "Error").then((result) {
      if (mounted) {
        setState(() {
          keywords = result; // Save the extracted keywords in the list
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.request["requestType"] ?? "Unknown";
    final String time = widget.request["time"] ?? "N/A";
    final String date = _formatDate(widget.request["date"]);
    final String status = widget.request["status"] ?? "Unknown";
    final String amount = "${widget.request["amount"] ?? "0.00"} ₹";
    final String requestId = widget.request["id"] ?? "";

    return TextButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReqDetailsPage(requestId: requestId),
          ),
        );
        if (context.mounted) {
          widget.onRefresh(); // Call the callback when returning
        }
      },
      child: Container(
        width: double.infinity,
        decoration: Styles.boxDecoration,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(title),
                  const SizedBox(height: 8),
                  _buildPillsRow(["Time: $time", "Date: $date"]),
                  const SizedBox(height: 8),
                  _buildPillsRow([
                    "Amount: $amount",
                    status,
                  ], statusColor: status == "Accepted" 
                      ? Colors.green[500]! 
                      : status == "Pending Rating" 
                          ? Colors.blue[300]! 
                          : Colors.orange[600]!,
                  ),
                  const SizedBox(height: 4),
                  const Divider(color: Colors.white, thickness: 1),
                  _buildTagsSection(),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return "N/A";
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) return "Invalid Date";
    return "${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year.toString().substring(2)}";
  }

  // void _navigateToDetails(BuildContext context, String requestId) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ReqDetailsPage(requestId: requestId),
  //     ),
  //   );
  // }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: Styles.nameStyle,
      softWrap: true,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPillsRow(List<String> pills, {Color? statusColor}) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 5,
      runSpacing: 5,
      children: pills.map((pill) {
        final isStatus = pill == pills.last && statusColor != null;
        return Styles.buildPill(pill, isStatus ? statusColor : Styles.mildPurple);
      }).toList(),
    );
  }

  Widget _buildTagsSection() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: SizedBox(
        height: 15,
        width: 15,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
          ),
        ),
      );
    } else if (keywords != null && keywords!.isNotEmpty) {
      return Wrap(
        spacing: 5,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            "AI tags:",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          ...keywords!.map((keyword) => Styles.buildPill(keyword.trim(), Styles.mildPurple)),
        ],
      );
    } else {
      return const Center(
        child: Text(
          "Unable to load AI tags.",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    }
  }
}
