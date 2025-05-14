import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

import '../../styles/styles.dart';
import '../../styles/custom_style.dart';

class VolWallet extends StatefulWidget with CustomStyle {
  VolWallet({super.key});

  @override
  _VolWalletState createState() => _VolWalletState();
}

class _VolWalletState extends State<VolWallet> {
  int _currentAmount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAmount();
  }

  Future<void> _loadAmount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _currentAmount = prefs.getInt('amount') ?? 0;
        });
      }
    } catch (e) {
      print('Error loading amount: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load wallet amount.')),
      );
    }
  }

  Future<void> _incrementAmount(int amountToAdd) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userType = prefs.getString('userType');

      if (userId != null && userType != null) {
        if (_currentAmount + amountToAdd <= 10000) {
          _currentAmount += amountToAdd;

          try {
            await FirebaseFirestore.instance
                .collection(userType)
                .doc(userId)
                .update({'amount': _currentAmount});
          } catch (e) {
            print('Error updating Firestore: $e');
            throw Exception('Failed to update Firestore.');
          }

          await prefs.setInt('amount', _currentAmount);

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rupees $amountToAdd Credited')),
          );
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot exceed the limit of 10,000')),
          );
        }
      } else {
        throw Exception('User ID or User Type is null');
      }
    } catch (e) {
      print('Error incrementing amount: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update amount. Please try again.')),
      );
    }
  }

  Future<void> _decrementAmount(int amountToWithdraw) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userType = prefs.getString('userType');

      if (userId != null && userType != null) {
        if (_currentAmount >= amountToWithdraw) {
          _currentAmount -= amountToWithdraw;

          try {
            await FirebaseFirestore.instance
                .collection(userType)
                .doc(userId)
                .update({'amount': _currentAmount});
          } catch (e) {
            print('Error updating Firestore: $e');
            throw Exception('Failed to update Firestore.');
          }

          await prefs.setInt('amount', _currentAmount);

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rupees $amountToWithdraw Withdrawn')),
          );
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insufficient balance')),
          );
        }
      } else {
        throw Exception('User ID or User Type is null');
      }
    } catch (e) {
      print('Error decrementing amount: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update amount. Please try again.')),
      );
    }
  }

  void _showTopUpDialog() {
    final TextEditingController _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Top Up Amount'),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter amount to add',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final amountToAdd = int.tryParse(_amountController.text) ?? 0;
                if (amountToAdd > 0) {
                  Navigator.pop(context); // Close the dialog
                  await _incrementAmount(amountToAdd);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount.')),
                  );
                }
              },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Top Up'),
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawDialog() {
    final TextEditingController _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Withdraw Amount'),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter amount to withdraw',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                FocusScope.of(context).unfocus();
                final amountToWithdraw =
                    int.tryParse(_amountController.text) ?? 0;
                if (amountToWithdraw > 0) {
                  Navigator.pop(context); // Close the dialog
                  await _decrementAmount(amountToWithdraw);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')),
                  );
                }
              },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Withdraw'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Ensures the layout adjusts when the keyboard appears
      body: Container(
        height: MediaQuery.of(context).size.height, // Full height
        decoration: BoxDecoration(color: Styles.darkPurple),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.33,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text("VolWallet", style: Styles.titleStyle),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: BackButton(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 200,
                    child: PageView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCard("₹ $_currentAmount.00"),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: _buildActionButton(
                      Icons.reply, // Changed icon for Withdraw
                      "Withdraw",
                      context,
                      _showWithdrawDialog,
                                      ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String balance) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Styles.lightPurple,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              balance,
              style: Styles.buttonTextStyle
                  .copyWith(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Styles.lightPurple,
            radius: 30,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: 10),
          Text(label,
              style: Styles.buttonTextStyle
                  .copyWith(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
