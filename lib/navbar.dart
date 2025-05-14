import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemNavigator.pop()
import 'package:mini_ui/menu/organization/navigation.dart';
import 'package:mini_ui/profile/profilewithguard.dart';
import 'package:mini_ui/volunteers/reqhistory/reqhistory.dart';
import 'package:mini_ui/volunteers/volwallet.dart';
import 'profile/profile.dart';
import 'request/requestpage.dart';
import 'styles/styles.dart';
import 'menu/menu.dart';
import 'menu/reqhistory/reqhistory.dart';
import 'menu/neighbourhood/neighbourhood.dart';
import 'menu/customer/support.dart';
import 'menu/wallet/wallet.dart';
import 'menu/priority/prioritylist.dart';
import 'organization/volunteerlist.dart'; // Ensure this contains your colors
import 'package:shared_preferences/shared_preferences.dart';
import 'volunteers/vol_requests.dart';

List<Map<String, dynamic>> contentsHomebound=[
        {"icon":Icons.history,"label":"Request\nHistory","Navigation": const ReqHistoryPage()},
        {"icon":Icons.location_city,"label":"Neighbourhood","Navigation":Neighbourhood()},
        {"icon":Icons.priority_high,"label":"Volunteer\nPriority List","Navigation": const PriorityPage()},
        {"icon":Icons.support_agent,"label":"Customer\nCare","Navigation": const CustomerSupport()},
        {"icon":Icons.wallet,"label":"Wallet","Navigation":Wallet()}
  ];

List<Map<String, dynamic>> contentsVolunteer=[
        {"icon":Icons.history,"label":"Request\nHistory","Navigation": const VolReqHistoryPage()},
        {"icon":Icons.location_city,"label":"Neighbourhood","Navigation":Neighbourhood()},
        {"icon":Icons.group,"label":"Organization","Navigation": const OrganizationNavigation()},
        {"icon":Icons.support_agent,"label":"Customer\nCare","Navigation": const CustomerSupport()},
        {"icon":Icons.wallet,"label":"Wallet","Navigation":VolWallet()}
  ];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int selectedIndex = 0; // Default to Home
  List<Widget> pages = [const Center(child: CircularProgressIndicator())]; // Default page to avoid empty list
  List<BottomNavigationBarItem> navItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.error), label: 'Loading'), // Default nav item
    const BottomNavigationBarItem(icon: Icon(Icons.error), label: 'Loading') // Second default nav item
  ]; // Default navigation items to avoid empty list

  @override
  void initState() {
    super.initState();
    _initializeNavBar();
  }

  Future<void> _initializeNavBar() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType') ?? 'homebound';

    if (userType == 'organization') {
      // Set pages and nav items for organizations
      pages = [
        const VolunteerListPage(), // Replace with Volunteers Page
        const ProfilePage(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Volunteers'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (userType == 'homebound') {
      final guardianId = prefs.getString('guardianId') ?? '';
      // Set pages and nav items for homebound
      if (guardianId == '') {
        pages = [
          const RequestsPage(),
          Home(content: contentsHomebound, title: "Menu", backbutton: false),
          const ProfilePage(),
        ];
        navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
      } else {
        pages = [
          const RequestsPage(),
          const ProfilePageWithGuard(),
        ];
        navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
      }
    } else if (userType == 'volunteers') {
      // Set pages and nav items for homebound
      pages = [
        const VolRequestsPage(),
        Home(content: contentsVolunteer, title: "Menu", backbutton: false),
        const ProfilePage(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Requests'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Menu'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (userType == 'guardians') {
      // Set pages and nav items for homebound
      pages = [
        const RequestsPage(),
        Home(content: contentsHomebound, title: "Menu", backbutton: false),
        const ProfilePage(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Requests'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Menu'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    }

    setState(() {}); // Update the UI after setting pages and nav items
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents default back behavior
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop(); // Close the app
        }
      },
      child: Scaffold(
        body: pages.isNotEmpty ? pages[selectedIndex] : const Center(child: CircularProgressIndicator()), // Display selected page or loading indicator
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          backgroundColor: Styles.darkPurple, // Use dark purple
          selectedItemColor: Colors.white, // Highlight selected item
          unselectedItemColor: Colors.grey.shade400, // Dim unselected items
          type: BottomNavigationBarType.fixed, // Ensures all labels are shown
          items: navItems, // Dynamically set navigation items
        ),
      ),
    );
  }
}
