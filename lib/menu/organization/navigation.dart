import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_ui/menu/organization/orgdetails.dart';
import 'package:mini_ui/menu/organization/orgjoin.dart';
import 'package:mini_ui/styles/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrganizationNavigation extends StatefulWidget {
  const OrganizationNavigation({super.key});

  @override
  _OrganizationNavigationState createState() => _OrganizationNavigationState();
}

class _OrganizationNavigationState extends State<OrganizationNavigation> {
  int selectedIndex = 1;
  bool isLoading = true;
  Map<String, dynamic> orgDetails = {};
  @override
  void initState() {
    super.initState();
    _initializeOrg();
  }

  
  Future<void> _initializeOrg() async {
    final prefs = await SharedPreferences.getInstance();
    final orgId = prefs.getString('orgId') ?? '';
    print(orgId);
    if (orgId.isEmpty) {
      setState(() {
        selectedIndex = 1;
        isLoading = false;
      });
    } 
    else {
      orgDetails = await getOrgDetails(orgId);
      setState(() {
        selectedIndex = 2;
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> getOrgDetails(String orgId) async {
  DocumentSnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
      .collection('organization')
      .doc(orgId)
      .get();
  
  return querySnapshot.data() ?? {};

}
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
        return const Scaffold(
        backgroundColor: Styles.darkPurple,
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white),),
        ),
      );
    } 
    
    else if (selectedIndex == 1) {
    return JoinOrganization();
    } 
    
    else {

      return OrgDetailsPage(orgDetails: orgDetails, nav: "joined");
    }
  }
}
