import 'package:flutter/material.dart';
// import 'package:mini_ui/navbar.dart';
import 'package:mini_ui/screens/auth_service.dart';
import 'package:mini_ui/screens/forgotpassword.dart';
import 'package:mini_ui/splash.dart';
import 'package:mini_ui/styles/styles.dart';
import 'screen_signup.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final _auth = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _login() async {
    if (!_formKey.currentState!.validate()) return 'Form validation failed';

    setState(() => _isLoading = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() => _isLoading = false);
        return 'No internet connection';
      }

      final user = await _auth.loginUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        // Check each collection for the email
        List<String> collections = [
          'homebound',
          'volunteers',
          'guardians',
          'organization'
        ];
        String? userType;

        for (String collection in collections) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection(collection)
              .where('email', isEqualTo: _emailController.text.trim())
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            userType = collection;
            break;
          }
        }

        if (userType == null) {
          setState(() => _isLoading = false);
          return 'User not found in any collection';
        }

        // Fetch user details and type from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection(userType) // userType is the collection name
            .doc(user.uid)
            .get();
        
        // Query 1: where homeboundId == userId
        final homeboundQuery = await FirebaseFirestore.instance
            .collection('guardian_requests')
            .where('homeboundId', isEqualTo: user.uid)
            .get();
        print(homeboundQuery.docs);

        // Query 2: where guardianId == userId
        final guardianQuery = await FirebaseFirestore.instance
            .collection('guardian_requests')
            .where('guardianId', isEqualTo: user.uid)
            .get();
        print(guardianQuery.docs);

        // Combine results (avoiding duplicates by doc.id)
        final allDocs = {
          for (var doc in homeboundQuery.docs) doc.id: doc,
          for (var doc in guardianQuery.docs) doc.id: doc,
        }.values.toList();

        final guardianData = allDocs.isNotEmpty ? allDocs[0].data() : null;
        print(guardianData);

        if (userDoc.exists) {
          final userData = userDoc.data();

          // Store user details and type in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user.uid);
          await prefs.setString('userType', userType);
          await prefs.setString('userName', userData?['name'] ?? '');
          await prefs.setString('userEmail', userData?['email'] ?? '');
          await prefs.setString('userAddress', userData?['address'] ?? '');
          await prefs.setString(
              'neighbourhoodId', userData?['neighbourhoodId'] ?? '');
          await prefs.setString('orgName', userData?['orgName'] ?? 'none');
          await prefs.setString('orgId', userData?['orgId'] ?? '');
          await prefs.setStringList(
              'services', userData?['services']?.cast<String>() ?? []);
          final rawAmount = userData?['amount']?.toString() ?? '0';
          final amount = int.tryParse(rawAmount.split('.').first) ?? 0; // Default to 0 if not found
          await prefs.setInt('amount', amount);
          await prefs.setString('homeboundId', guardianData?['homeboundId'] ?? '');
          await prefs.setString('guardianId', guardianData?['guardianId'] ?? '');
          await prefs.setString('guardianName', guardianData?['guardianName'] ?? '');
          setState(() => _isLoading = false);
          _goToHome();
          return 'success';
        } else {
          setState(() => _isLoading = false);
          return 'User details not found';
        }
      } else {
        setState(() => _isLoading = false);
        return 'Invalid email or password';
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('$e');
      return 'An error occurred';
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.darkPurple,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(10.0),
            children: [
              const SizedBox(height: 20),
              const Text(
                "NEIGHBOURLY",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                "Please login below!",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.all(10.0),
                padding: const EdgeInsets.all(16.0),
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Styles.mildPurple,
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(66, 0, 0, 0),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextFormField(
                        cursorColor: Colors.white,
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!RegExp(
                                  r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')
                              .hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 19),
                      TextFormField(
                        cursorColor: Colors.white,
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 25),
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton(
                              onPressed: () async {
                                FocusScope.of(context).unfocus();
                                final message = await _login();
                                if (mounted) {
                                  setState(() {
                                    if (message != "success") {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(message)),
                                      );
                                    }
                                  });
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 24.0),
                                child: Text(
                                  'Log In',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                      const SizedBox(height: 5),
                      Wrap(alignment: WrapAlignment.start, children: [
                        TextButton(
                          onPressed: () {
                            //Navigate to Forgot Password screen or handle password reset logic
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Colors.blue, fontSize: 16),
                          ),
                        ),
                      ]),
                      // Adjusted height
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text("Don't have an account?",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUpScreen()),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
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
