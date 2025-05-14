import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_ui/menu/priority/prioritylist.dart';
import 'package:mini_ui/menu/priority/voldetails.dart';
import 'package:mini_ui/styles/styles.dart';

import '../../styles/custom_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class SearchVolunteerPage extends StatelessWidget with CustomStyle {
  SearchVolunteerPage({super.key}) {
    loadJsonData();
  }

  final ValueNotifier<List<dynamic>> filteredData = ValueNotifier([]);
  final TextEditingController searchController = TextEditingController();
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<void> filterSearch(String query) async {
    if (query.isEmpty) {
      filteredData.value = [];
      return;
    }

    isLoading.value = true;
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('volunteers')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      filteredData.value = querySnapshot.docs.map((doc) {
                        return{ 
                      'id': doc.id,     
                      ...doc.data() as Map<String,dynamic>};}
                      
                      ).toList();
      print(filteredData.value);
    } catch (e) {
      debugPrint("Error fetching Firestore data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadJsonData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/data.json');
      filteredData.value = json.decode(jsonString);
    } catch (e) {
      debugPrint("Error loading JSON data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;
    return Container(
      color: Styles.darkPurple,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: BoxDecoration(color: Styles.darkPurple),
          child: Column(
            children: [
              Container(
                height: deviceHeight / 3,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text("Add new\nVolunteer",
                          style: Styles.titleStyle,
                          textAlign: TextAlign.center),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    filterSearch(value);
                  },
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: "Enter volunteer name",
                    hintStyle: const TextStyle(color: Styles.offWhite),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder(
                  valueListenable: isLoading,
                  builder: (context, bool loading, child) {
                    if (loading) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white));
                    }
                    return ValueListenableBuilder(
                      valueListenable: filteredData,
                      builder: (context, List<dynamic> items, child) {
                        if (searchController.text.isEmpty) {
                          return Container(
                            alignment: Alignment.topCenter,
                            child: _buildPill("Enter name to search",
                                deviceWidth, 50, context),
                          );
                        }
                        return items.isNotEmpty
                            ? ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, index) => Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 10),
                                  child: _buildPill(items[index]['name'],
                                      deviceWidth, 50, context,
                                      index: index),
                                ),
                              )
                            : Container(
                                alignment: Alignment.topCenter,
                                child: _buildPill(
                                    "No matching volunteer found",
                                    deviceWidth,
                                    60,
                                    context),
                              );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String text, double deviceWidth, double height, BuildContext context,{int? index}) {
    if(index!=null){
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>VolDetails(requestDetails: filteredData.value[index])));
      },
      child: Container(
        height: height,
        width: deviceWidth-40,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Styles.lightPurple,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: buttonTextStyle.copyWith(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
           const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
  else{
    return Container(
        height: height,
        width: deviceWidth - 40,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Styles.lightPurple,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: buttonTextStyle.copyWith(fontSize: 18, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
  }
  }
}