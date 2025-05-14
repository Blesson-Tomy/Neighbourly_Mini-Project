import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_ui/navbar.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../styles/styles.dart';
import 'package:flutter/services.dart';



class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userProfile  ;
  const EditProfilePage({super.key, required this.userProfile});
  
  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  String _selectedGender = "Male";
  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userProfile['userName'];

    _genderController.text = widget.userProfile['gender']??"none";
    _addressController.text = widget.userProfile['userAddress'];
  }
  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    await FirebaseFirestore.instance
        .collection(widget.userProfile['userType']) // Change to your collection name
        .doc(widget.userProfile['userId']) // Replace 'documentId' with the actual document ID
        .update({
          'name': _nameController.text.trim(),
          'gender': _selectedGender,

          'address': _addressController.text.trim(),
        });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userName', _nameController.text.trim());

    prefs.setString('userAddress', _addressController.text.trim());
    prefs.setString('gender', _selectedGender);

    // Update the user profile in the database or API
    // ...

    setState(() {
      _isLoading = false;
    });
  }


  @override
  void dispose() {
    _nameController.dispose();

    _genderController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
  return const Scaffold(
        backgroundColor: Styles.darkPurple,
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white),),
        ),
      );
    }
    else{
    return Scaffold(
      backgroundColor: Styles.darkPurple,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.33,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text("Edit Profile", style: Styles.titleStyle),
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
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Styles.mildPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text("Name :", style: TextStyle(color: Colors.white, fontSize: 16),),
                  ),
                  SizedBox(height: 10),
                  TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: Styles.inputDecoration,
                  ),
                 
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text("Gender :", style: TextStyle(color: Colors.white, fontSize: 16),),
                  ),
                  SizedBox(height: 10),
                  Container(
                  child: _buildDropdownField(),

                  )
          
                    ,
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text("Address :", style: TextStyle(color: Colors.white, fontSize: 16),),
                  ),
                  SizedBox(height: 10),
                  TextField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: Styles.inputDecoration,
                  maxLines: null, // Allows the TextField to expand with content
                  ),
                  // if(widget.userProfile['userType'] == "volunteers") ...
                  // {
                  // SizedBox(height: 20),
                  // Padding(
                  //   padding: const EdgeInsets.only(left: 8),
                  //   child: Text("Services :", style: TextStyle(color: Colors.white, fontSize: 16),),
                  // ),
                  // SizedBox(height: 10),
                  // TextField(
                  // controller: _preferenceController,
                  // style: const TextStyle(color: Colors.white),
                  // decoration: Styles.inputDecoration,
                  // maxLines: null, // Allows the TextField to expand with content
                  // ),},
                  SizedBox(height: 30),
                  Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Styles.lightPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    onPressed: () {
                      showConfirmationDialog(context);
                    },
                    child: Text('Save Changes', style: Styles.buttonTextStyle),
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
  }
  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: widget.userProfile["gender"]??"Male",
        dropdownColor: Styles.lightPurple,
        items: ["Male", "Female", "Other"].map((gender) {
          return DropdownMenuItem(
            value: gender,
            child: Text(gender, style: const TextStyle(color: Styles.white)),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedGender = value!),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white), // Set arrow color to white
        decoration: InputDecoration(
          
          labelStyle: const TextStyle(color: Styles.white),
          prefixIcon: const Icon(Icons.person, color: Styles.white),
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
    );
  }


void showConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Styles.mildPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Confirm Changes",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to apply the changes?",
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
                    _updateProfile();
                    if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MainScreen()), 
                                  (route) => false, // Removes all routes
                                
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
                    "Apply Changes",
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
}}