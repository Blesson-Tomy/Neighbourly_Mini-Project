import '../menu.dart';
import 'create.dart';
import 'join.dart';
import 'package:flutter/material.dart';
import '../../styles/styles.dart'; 
import '../../styles/custom_style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


Future<Map<String, dynamic>> getNeighbourhoodDetails(String nhId) async {
  DocumentSnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
      .collection('neighbourhood')
      .doc(nhId)
      .get();
  
  return querySnapshot.data() ?? {};

}

  Future<String> check() async{
  final prefs = await SharedPreferences.getInstance();
  String joindet = prefs.getString('neighbourhoodId') ?? '' ;
  // joined = await check()==''?false:true;
  // return joindet;
  print(joindet);

  return joindet;
}

List<Map<String, dynamic>> contents = [
  {"icon": Icons.group_add, "label": "Join", "Navigation": JoinNeighbourhood()},
  {"icon": Icons.add_home, "label": "Create", "Navigation": CreateNeighbourhood()}
];

class Neighbourhood extends StatefulWidget with CustomStyle {
  Neighbourhood({super.key});

  @override
  _NeighbourhoodState createState() => _NeighbourhoodState();
}

class _NeighbourhoodState extends State<Neighbourhood> {
  bool joined = false;
  bool _isLoading = true;
  String nhId = '';
  Map<String,dynamic> nhdetails={};
  @override
  void initState() {
    super.initState();
    _checkNeighbourhoodStatus();

  }
  @override
    void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  Future<void> _checkNeighbourhoodStatus() async {
    String joindet = await check();
    if(joindet.isNotEmpty){
      Map<String,dynamic> nhdetails1 = await getNeighbourhoodDetails(joindet);
      print(nhdetails1);
      if(nhdetails1.isNotEmpty){
        setState(() {
          nhId = joindet;
          joined = joindet.isNotEmpty;
          nhdetails=nhdetails1;
          _isLoading = false;
        });
      }
      else{
        setState(() {
          joined = false;
          _isLoading = false;
        });
      }
    }
    else{
      setState(() {
        joined = false;
        _isLoading = false;
      });
    }
    

  }

  void removeField() async {
  try {
    setState(() {
      _isLoading = true;
    });
    final user = await SharedPreferences.getInstance();
    String userType=user.getString('userType')??'';
    String userId=user.getString('userId')??'';
    user.remove("neighbourhoodId");
    await FirebaseFirestore.instance
        .collection(userType) // Change to your collection name
        .doc(userId)
        .update({
          'neighbourhoodId': FieldValue.delete(),// Replace 'fieldName' with the actual field name
        });
    await FirebaseFirestore.instance
        .collection('neighbourhood') // Change to your collection name
        .doc(nhId)
        .update({
          userType: FieldValue.increment(-1),// Replace 'fieldName' with the actual field name
        });

    print('Field removed successfully');
    setState(() {
      joined = false;
      _isLoading = false;
    });
  } catch (e) {
    print('Error removing field: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Styles.darkPurple,
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white),),
        ),
      );
    }
    else{
    if (joined) {

      return Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(color: Styles.darkPurple),
          child: Column(
            children: [
              Container(
                height: deviceHeight * 0.33,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text("Your Neighbourhood", style: Styles.titleStyle, textAlign: TextAlign.center),
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
              Expanded(
                flex: 2,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    RequestBox(
                            title: nhdetails['name'] ?? 'Unknown',
                            homebound: nhdetails['homebound']?.toString() ?? '0',
                            volunteer: nhdetails['volunteers']?.toString() ?? '0',
                            address: nhdetails['address'] ?? 'No Address',
                            areacode: nhdetails['zip'] ?? '00000',
                    ),
                  ],
                ),
              ),
              SizedBox(height: deviceHeight * 0.1),
              Center(
                child: SizedBox(
                  width: deviceWidth * 0.9,
                  height: deviceHeight * 0.07,
                  child: ElevatedButton(
                    onPressed: () {
                      // Leave neighbourhood action
                      removeField();
                      if(_isLoading==false){
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Styles.mildPurple,
                        elevation: 10, // Increased elevation for a stronger shadow
                        shadowColor: Colors.black, // Darker and more visible shadow
                        padding: const EdgeInsets.symmetric(vertical: 8), // Removed horizontal padding to fit width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color.fromARGB(255, 209, 209, 209), width: 2),
                        ),
                      ),
                    child: Text(
                      "Leave Neighbourhood",
                      textAlign: TextAlign.center,
                      style: Styles.buttonTextStyle.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(height: deviceHeight * 0.05),
            ],
          ),
        ),
      );
    } else {
      return Home(content: contents, title: "Join or Create\nNeighbourhood", backbutton: true);
    }
    }
  }
}

 


class RequestBox extends StatelessWidget {
  final String title;
  final String homebound;
  final String volunteer;
  final String address;
  final String areacode; // Callback for button press

  const RequestBox({
    super.key,
    required this.title,
    required this.homebound,
    required this.volunteer,
    required this.address,
    required this.areacode, // Allows passing a function when tapped
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 4), // Space between cards
        decoration: Styles.boxDecoration, // Use the same decoration as Profile Page
        padding: const EdgeInsets.all(14), // Internal padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Left side: Request details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: 
                    Text(title, style: Styles.bodyStyle.copyWith(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),),
                  
                ),
                const SizedBox(height: 8),
                // Time and Date Row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPill("Homebound: $homebound"),
                    const SizedBox(width: 5),
                    _buildPill("Volunteer: $volunteer"),
                    const SizedBox(width: 5),
                    _buildPill("Zip code: $areacode"),
                    const SizedBox(width: 5),
                    _buildPill("Address: $address"),
                  ],
                ),
              ],
            ),
            // Right side: Forward arrow icon
            // Padding(
            //   padding: EdgeInsets.fromLTRB(0, 0, 0,0),
            //   child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20)),
          ],
        ),
    );
  }

  // Helper function to create pill-shaped containers
  Widget _buildPill(String text) {
    return Center(
      child: 
        Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      decoration: BoxDecoration(
        color:  Styles.lightPurple, // Dark grey for time and date pills
        borderRadius: BorderRadius.circular(20), // Rounded pill shape
      ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: 
              Text(
        text,
                textAlign: TextAlign.left,
        style: Styles.bodyStyle,
      ),
            
          ),
        ),
      
    );
  }
}


