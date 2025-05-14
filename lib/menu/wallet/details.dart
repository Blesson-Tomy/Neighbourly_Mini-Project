import 'package:flutter/material.dart';
import '../../styles/styles.dart';
import '../../styles/custom_style.dart';


class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  CardListScreenState createState() => CardListScreenState();
}

class CardListScreenState extends State<CardListScreen> with CustomStyle {
  List<Map<String, String>> savedCards = [
    {
      "cardNumber": "4242 4242 4242 4242",
      "expiry": "12/26",
      "cardHolder": "John Doe",
    }
  ];

  void _showAddCardDialog() {
    TextEditingController cardNumberController = TextEditingController();
    TextEditingController expiryController = TextEditingController();
    TextEditingController cardHolderController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Styles.lightPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text("Add Card", style: titleStyle.copyWith(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(cardNumberController, "Card Number", TextInputType.number),
                _buildTextField(expiryController, "Expiry Date (MM/YY)", TextInputType.datetime),
                _buildTextField(cardHolderController, "Card Holder Name", TextInputType.text),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: buttonTextStyle.copyWith(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Styles.darkPurple),
              onPressed: () {
                if (cardNumberController.text.isNotEmpty &&
                    expiryController.text.isNotEmpty &&
                    cardHolderController.text.isNotEmpty) {
                  setState(() {
                    savedCards.add({
                      "cardNumber": cardNumberController.text,
                      "expiry": expiryController.text,
                      "cardHolder": cardHolderController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: Text("Submit", style: buttonTextStyle.copyWith(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles.darkPurple)),
        ),
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _deleteCard(int index) {
    setState(() {
      savedCards.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(color: Styles.darkPurple),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.33,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text("Saved Cards", style: Styles.titleStyle),
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
              child: ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: savedCards.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Styles.lightPurple,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: ListTile(
                      leading: Icon(Icons.credit_card, color: Colors.white),
                      title: Text(
                        "**** **** **** ${savedCards[index]["cardNumber"]!.substring(savedCards[index]["cardNumber"]!.length - 4)}",
                        style: buttonTextStyle.copyWith(color: Colors.white),
                      ),
                      subtitle: Text(
                        "${savedCards[index]["cardHolder"]} • Exp: ${savedCards[index]["expiry"]}",
                        style: buttonTextStyle.copyWith(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: const Color.fromARGB(255, 255, 118, 115)),
                        onPressed: () => _deleteCard(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 20.0),
              child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.lightPurple,
                fixedSize: Size(MediaQuery.of(context).size.width * 0.9, 60),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _showAddCardDialog,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text("Add Card", style: buttonTextStyle.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
