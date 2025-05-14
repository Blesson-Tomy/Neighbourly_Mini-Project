import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_ui/menu/neighbourhood/nbdetails.dart';

import 'package:mini_ui/styles/styles.dart';
import '../../styles/custom_style.dart';


class JoinNeighbourhood extends StatelessWidget with CustomStyle {
  JoinNeighbourhood({super.key});

  final TextEditingController searchController = TextEditingController();
  final ValueNotifier<List<dynamic>> filteredItems = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  void fetchFilteredData(String query) async {
    if (query.isEmpty) {
      filteredItems.value = [];
      return;
    }

    isLoading.value = true;
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('neighbourhood')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      filteredItems.value = querySnapshot.docs.map((doc) {
                        return{ 
                      'id': doc.id,     
                      ...doc.data() as Map<String,dynamic>};}
                      
                      ).toList();
      print(filteredItems.value);
      
    } catch (e) {
      debugPrint("Error fetching Firestore data: $e");
    } finally {
      isLoading.value = false;
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
                    const Align(
                      alignment: Alignment.center,
                      child: Text("Join new\nNeighbourhood", style: Styles.titleStyle, textAlign: TextAlign.center),
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
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    fetchFilteredData(value);
                  },
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: "Enter neighbourhood name",
                    hintStyle: const TextStyle(color: Styles.offWhite),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
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
              Expanded(
                flex: 2,
                child: ValueListenableBuilder(
                  valueListenable: isLoading,
                  builder: (context, bool loading, child) {
                    if (loading) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    return ValueListenableBuilder(
                      valueListenable: filteredItems,
                      builder: (context, List<dynamic> items, child) {
                        if (searchController.text.isEmpty) {
                          return Container(
                            alignment: Alignment.topCenter,
                            child: _buildPill("Enter name to search", deviceWidth, 50,context),
                          );
                        }
                        return items.isNotEmpty
                            ? ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                                  child: _buildPill(items[index]['name'], deviceWidth, 50,context,index:index),
                                ),
                              )
                            : Container(
                                alignment: Alignment.topCenter,
                                child: _buildPill("No matching neighbourhood found", deviceWidth, 60,context),
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
        Navigator.push(context, MaterialPageRoute(builder: (context)=>ReqDetailsPage(requestDetails: filteredItems.value[index])));
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