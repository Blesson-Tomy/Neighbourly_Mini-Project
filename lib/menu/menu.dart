import 'package:flutter/material.dart';
import '../styles/styles.dart';
import '../styles/custom_style.dart';

class Home extends StatelessWidget with CustomStyle {
  final List<Map<String, dynamic>> content;
  final String title;
  final bool backbutton;
  Home(
      {super.key,
      required this.content,
      required this.title,
      required this.backbutton});
  
  Widget createbackButton(bool val, BuildContext context) {
    if (val == true) {
      return Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(title,
                style: Styles.titleStyle, textAlign: TextAlign.center),
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
      );
    } else {
      return Align(
        alignment: Alignment.center,
        child:
            Text(title, style: Styles.titleStyle, textAlign: TextAlign.center),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Styles.darkPurple,
      body: DecoratedBox(
        decoration: BoxDecoration(color: Styles.darkPurple),
        child: SingleChildScrollView(
          child: Column(
              children: [
                Container(
                  height: deviceHeight * 0.33,
                  alignment: Alignment.topCenter,
                  color: Colors.transparent,
                  child: createbackButton(backbutton, context),
                ),
                SizedBox(
                  width: deviceWidth * 0.9,
                  child: SingleChildScrollView(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 30,
                      direction: Axis.horizontal,
                      children: content.map((contents) {
                        return ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => contents["Navigation"],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.lightPurple,
                            padding: EdgeInsets.all(8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: const Color.fromARGB(10, 255, 255, 255),
                                width: 2,
                              ),
                            ),
                            minimumSize: Size(120, 110),
                            maximumSize: Size(150, 140),
                          ),
                          child: Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    contents["icon"],
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  contents["label"],
                                  textAlign: TextAlign.center,
                                  style: descriptionStyle,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}