import 'package:firebase_auth/firebase_auth.dart';
import 'package:mini_ui/navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../styles/custom_style.dart';
import 'package:flutter/material.dart';
import '../../styles/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> joinNeighbourhood(String neighbourhoodId) async {
  final prefs = await SharedPreferences.getInstance();
  final userType = prefs.getString('userType') ?? ""; // Fallback if not found
  print ("User Name: $userType");
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User not logged in");
      return;
    }

    DocumentReference userDocRef = FirebaseFirestore.instance.collection(userType).doc(user.uid);

    // Update the user document by adding the field
    await userDocRef.set({'neighbourhoodId': neighbourhoodId}, SetOptions(merge: true));
    await prefs.setString('neighbourhoodId', neighbourhoodId);

    await FirebaseFirestore.instance
        .collection('neighbourhood') // Change to your collection name
        .doc(neighbourhoodId)
        .update({
          userType: FieldValue.increment(1), // Increment by 1
        });

    print("Neighbourhood ID added successfully to $userType");
  } catch (e) {
    print("Error joining neighborhood: $e");
  }
}


class CreateNeighbourhood extends StatelessWidget with CustomStyle {
  CreateNeighbourhood({super.key});
    Future<void> addNhood() async{
    String name= nameController.text.trim();
    String address = addressController.text.trim();
    String city = cityController.text.trim();
    String state = stateController.text.trim();
    String zip =zipController.text.trim();
    String description=descriptionController.text.trim();

    if(name.isNotEmpty && address.isNotEmpty && city.isNotEmpty
    && state.isNotEmpty && zip.isNotEmpty && description.isNotEmpty)
      {try
        {
          DocumentReference neighborhoodRef= await FirebaseFirestore.instance.collection('neighbourhood').add({
            'name':name,
            'address':address,
            'city':city,
            'state':state,
            'zip':zip,
            'description':description,
            'timestamp':FieldValue.serverTimestamp(),
            'volunteers': 0,
            'homebound': 0,
          });
          String nhId = neighborhoodRef.id;
          joinNeighbourhood(nhId);

          print("neighbourhood created");}
          catch(e){print("error: $e");}
        }
      
      }
  

  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Widget _buildPrompt(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(label, style: descriptionStyle,),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.edit, color: Colors.white),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.white, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.white, width: 1),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;

    return Container(
      color: Styles.darkPurple,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: BoxDecoration(color: Styles.darkPurple),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: deviceHeight * 0.33,
                  alignment: Alignment.center,
                  child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text("Create new\nNeighbourhood", style: Styles.titleStyle, textAlign: TextAlign.center),
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
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Styles.mildPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                    child: Column(
                      children: [
                        _buildPrompt("Neighbourhood Name :", nameController),
                        _buildPrompt("Street Address :", addressController),
                        _buildPrompt("City :", cityController),
                        _buildPrompt("State :", stateController),
                        _buildPrompt("PIN Code :", zipController),
                        _buildPrompt("Description :", descriptionController, maxLines: 4),
                        SizedBox(height: 40),
                        SizedBox(
                          width: deviceWidth-76,
                          child: ElevatedButton(
                            onPressed: () {
                              showConfirmationDialog(context);
                            },
                            style: TextButton.styleFrom(
                              textStyle: buttonTextStyle,
                              backgroundColor: Styles.lightPurple,
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text("Create", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


// Confirmation Dialog Function
void showConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context1) {
      return AlertDialog(
        backgroundColor: Styles.mildPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Create Neighbourhood",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to create this neighbourhood?",
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
                  onPressed: () {
                    addNhood();    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Neighbourhood added successfully!")),
                          );
                    Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MainScreen()),
                          (route) => false, // Removes all previous routes
                        ); 
                    // Navigator.pop(context1);
                    // Navigator.pop(context);
                   
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Styles.lightPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Create",
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
}