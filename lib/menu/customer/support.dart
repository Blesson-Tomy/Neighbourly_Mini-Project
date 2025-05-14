import 'package:flutter/material.dart';
import '../../styles/styles.dart';
import '../../styles/custom_style.dart';

class CustomerSupport extends StatelessWidget with CustomStyle {
  const CustomerSupport({super.key});

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
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
                    child: Text("Customer Support",
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
              ),
            ),
            Expanded(
              flex: 4,
              child: ListView(
                padding: EdgeInsets.all(20),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Styles.lightPurple,
                    ),
                    child: ListTile(
                      leading: Icon(Icons.phone, color: Colors.white),
                      title: Text("Call Us        -     +91 1231231230",
                          style: Styles.buttonTextStyle
                              .copyWith(color: Colors.white)),
                      onTap: () {},
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      contentPadding: EdgeInsets.all(15),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Styles.lightPurple,
                    ),
                    child: ListTile(
                      leading: Icon(Icons.email, color: Colors.white),
                      title: Text("Email Us     -     customercare@app.in",
                          style: Styles.buttonTextStyle
                              .copyWith(color: Colors.white)),
                      onTap: () {},
                      tileColor: Styles.lightPurple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      contentPadding: EdgeInsets.all(15),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Styles.lightPurple,
                    ),
                    child: ListTile(
                      leading: Icon(Icons.chat, color: Colors.white),
                      title: Text("Chat            -     +91 1231231230",
                          style: Styles.buttonTextStyle
                              .copyWith(color: Colors.white)),
                      onTap: () {},
                      tileColor: Styles.lightPurple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      contentPadding: EdgeInsets.all(15),
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
