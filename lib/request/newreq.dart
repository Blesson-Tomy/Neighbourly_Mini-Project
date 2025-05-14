import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class NewRequestPage extends StatefulWidget {
  const NewRequestPage({super.key});

  @override
  NewRequestPageState createState() => NewRequestPageState();
}

class NewRequestPageState extends State<NewRequestPage> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String selectedRequest = "Grocery Shopping";
  String requestAt = "Neighbourhood";
  String selectedGender = "Any";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isLoading = false;

  Future<String> saveRequestToFirebase(
    BuildContext context,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    TextEditingController descriptionController,
    String selectedRequest, String selectedGender,
    String requestAt,
    TextEditingController amountController,
    ) async {

      setState(() => _isLoading = true);

      if (selectedDate == null
        || selectedTime == null
        || descriptionController.text.isEmpty
        || amountController.text.isEmpty) {
        return "Please fill all fields before submitting.";
      }

      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection("homebound")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        List<String> volunteerIds = [];

        if (doc.exists && doc.data() != null) {
          var data = doc.data() as Map<String, dynamic>;
          if (data.containsKey("volunteerId") && data["volunteerId"] is List) {
            volunteerIds = List<String>.from(data["volunteerId"]);
          }
        }

        final prefs = await SharedPreferences.getInstance();
        String neighbourhoodId = prefs.getString('neighbourhoodId') ?? "";

        // Create requestData dynamically based on requestAt
        final requestData = {
          "homeboundId": FirebaseAuth.instance.currentUser!.uid,
          "volunteerId": "",
          "requestType": selectedRequest,
          "description": descriptionController.text,
          "date": "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
          "time": selectedTime.format(context),
          "volunteerGender": selectedGender,
          "requestAt": requestAt,
          "amount": double.tryParse(amountController.text)?.toStringAsFixed(2) ?? "0.00",
          "status": "Waiting",
          "timestamp": FieldValue.serverTimestamp(),
          "tags": [],
        };

        // Add "neighbourhood" only if requestAt contains "Neighbourhood"
        if (requestAt == "Neighbourhood" || requestAt == "Neighbourhood & Priority List") {
          requestData["neighbourhood"] = neighbourhoodId;
        }

        // Add "priority" only if requestAt contains "Priority List"
        if (requestAt == "Priority List" || requestAt == "Neighbourhood & Priority List") {
          requestData["priority"] = volunteerIds;
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return "User not logged in.";
        }

        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          return "No network connection. Try again later.";
        }

        await FirebaseFirestore.instance.collection('current_requests').add(requestData);
        return "success";
      } catch (e) {
        print("Error: $e"); // Debugging output
        return "An error occurred. Try again later.";
      }

    }

  showConfirmationDialog(
    BuildContext context,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    TextEditingController descriptionController,
    String selectedRequest, String selectedGender,
    String requestAt,
    TextEditingController amountController,
    ) {
    
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent user from dismissing the dialog
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                backgroundColor: Styles.mildPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  "Confirm Submission",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                content:  _isLoading
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
                      :const Text(
                  "Are you sure you want to submit this request?",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                actions:  _isLoading
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
                                setState(() => _isLoading = true);
                                String status = await saveRequestToFirebase(
                                  context,
                                  selectedDate,
                                  selectedTime,
                                  descriptionController,
                                  selectedRequest,
                                  selectedGender,
                                  requestAt,
                                  amountController,
                                );

                                if (status == "success" && context.mounted) {
                                    Navigator.of(context).pop(); // Close the dialog
                                }

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                      status == "success"
                                        ? "Request successfully submitted."
                                        : status,
                                      style: const TextStyle(fontSize: 17),
                                      ),
                                      backgroundColor: status == "success" ? Colors.green[400] : Colors.red[400],
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                                    ),
                                  );
                                }
                            },
                              style: TextButton.styleFrom(
                              backgroundColor: Colors.green[500],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                              "Submit Request",
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

  // Function to pick a date
  Future<void> _pickDate(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Function to pick a time
  Future<void> pickTime(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
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
                    child: Text("New Request", style: Styles.titleStyle),
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
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Styles.mildPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown
                    Text("Request Type :", style: Styles.bodyStyle),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Styles.lightPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                        child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRequest,
                          dropdownColor: Styles.lightPurple,
                          borderRadius: BorderRadius.circular(10),
                          style: Styles.bodyStyle,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white), // Changed arrow color to white
                          items: [
                            "Driving",
                            "Grocery Shopping",
                            "Gardening",
                            "Dog Walking",
                            "Technical Support",
                            "House Cleaning",
                            "Meal Delivery",
                            "Medication Pickup",
                            "Companionship Visits",
                            "Mail and Package Handling",
                            "Light Home Repairs",
                            "Wheelchair Assistance",
                          ]
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedRequest = newValue!;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Description TextField
                    Text("Description :", style: Styles.bodyStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: null,
                      style: Styles.bodyStyle,
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.done, // Show checkmark instead of newline
                      decoration: InputDecoration(
                      filled: true,
                      hintText: "Describe what you need...",
                      hintStyle: const TextStyle(color: Styles.offWhite),
                      fillColor: Styles.lightPurple,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Date Picker
                    Text("Select Date :", style: Styles.bodyStyle),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickDate(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Styles.lightPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          selectedDate == null
                              ? "Pick a Date"
                              : "${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}",
                          style: Styles.bodyStyle,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Time Picker
                    Text("Select Time :", style: Styles.bodyStyle),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => pickTime(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Styles.lightPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          selectedTime == null
                              ? "Pick a Time"
                              : selectedTime!.format(context),
                          style: Styles.bodyStyle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text("Volunteer Gender :", style: Styles.bodyStyle),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Styles.lightPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                          setState(() {
                            selectedGender = "Any";
                          });
                          },
                          child: Row(
                          children: [
                            Radio<String>(
                            value: "Any",
                            groupValue: selectedGender,
                            onChanged: (String? value) {
                              setState(() {
                              selectedGender = value!;
                              });
                            },
                            activeColor: Colors.white,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              return Colors.white;
                            }),
                            ),
                            Text("Any", style: Styles.bodyStyle),
                          ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                          setState(() {
                            selectedGender = "Male";
                          });
                          },
                          child: Row(
                          children: [
                            Radio<String>(
                            value: "Male",
                            groupValue: selectedGender,
                            onChanged: (String? value) {
                              setState(() {
                              selectedGender = value!;
                              });
                            },
                            activeColor: Colors.white,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              return Colors.white;
                            }),
                            ),
                            Text("Male", style: Styles.bodyStyle),
                          ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                          setState(() {
                            selectedGender = "Female";
                          });
                          },
                          child: Row(
                          children: [
                            Radio<String>(
                            value: "Female",
                            groupValue: selectedGender,
                            onChanged: (String? value) {
                              setState(() {
                              selectedGender = value!;
                              });
                            },
                            activeColor: Colors.white,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              return Colors.white;
                            }),
                            ),
                            Text("Female", style: Styles.bodyStyle),
                          ],
                          ),
                        ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),
                    Text("Send Request To :", style: Styles.bodyStyle),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Styles.lightPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                        child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: requestAt,
                          dropdownColor: Styles.lightPurple,
                          style: Styles.bodyStyle,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          items: ["Neighbourhood", "Priority List", "Neighbourhood & Priority List"]
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                          }).toList(),
                          onChanged: (String? newValue) {
                          setState(() {
                            requestAt = newValue!;
                          });
                          },
                          borderRadius: BorderRadius.circular(10), // Added rounded corners
                        ),
                        ),
                    ),

                    const SizedBox(height: 15),
                    // Amount Input
                    Text("Amount :", style: Styles.bodyStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: Styles.bodyStyle,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        filled: true,
                        hintText: "Enter the amount...",
                        hintStyle: const TextStyle(color: Styles.offWhite),
                        fillColor: Styles.lightPurple,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                  FocusScope.of(context).requestFocus(FocusNode()); // Remove focus from all text fields
                  setState(() => _isLoading = false);
                  showConfirmationDialog(
                    context, selectedDate,
                    selectedTime,
                    descriptionController,
                    selectedRequest,
                    selectedGender,
                    requestAt,
                    amountController);
                  },
                  style: TextButton.styleFrom(
                  backgroundColor: Colors.green[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Styles.offWhite, width: 2),
                  ),
                  ),
                  child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 26),
                    SizedBox(width: 8),
                    Text(
                    "Submit Request",
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
            ),
            const SizedBox(height: 4,)
          ],
        ),
      ),
    );
  }
}
