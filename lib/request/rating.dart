import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_ui/styles/styles.dart';

class RateVolunteerPage extends StatefulWidget {
  final String volunteerId;

  const RateVolunteerPage({super.key, required this.volunteerId});

  @override
  RateVolunteerPageState createState() => RateVolunteerPageState();
}

class RateVolunteerPageState extends State<RateVolunteerPage> {
  double _rating = 0.0;
  bool _isSubmitting = false;
  String _volunteerName = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchVolunteerName();
  }

  Future<void> _fetchVolunteerName() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("volunteers")
          .doc(widget.volunteerId)
          .get();
      if (snapshot.exists) {
        setState(() {
          _volunteerName = snapshot["name"] ?? "Unknown Volunteer";
        });
      } else {
        setState(() {
          _volunteerName = "Unknown Volunteer";
        });
      }
    } catch (e) {
      setState(() {
        _volunteerName = "Error fetching name";
      });
    }
  }

  void _submitRating() async {
  setState(() {
    _isSubmitting = true;
  });

  try {
    DocumentReference volunteerDoc = FirebaseFirestore.instance.collection("volunteers").doc(widget.volunteerId);
    DocumentSnapshot snapshot = await volunteerDoc.get();

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>? ?? {};

    double currentRating = data.containsKey("rating") ? (data["rating"] as num).toDouble() : 0;
    int ratingCount = data.containsKey("ratingcount") ? (data["ratingcount"] as num).toInt() : 0;

    double newRating = ((currentRating * ratingCount) + _rating) / (ratingCount + 1);
    newRating = double.parse(newRating.toStringAsFixed(1)); // Limit to 1 decimal place

    await volunteerDoc.set({
      "rating": newRating,
      "ratingcount": ratingCount + 1,
    }, SetOptions(merge: true)); // Merge to keep existing data

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to submit rating. Please try again.'),
      ),
    );
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.darkPurple,
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.33,
            child: Stack(
              children: [
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Rate Your Experience",
                    style: Styles.titleStyle,
                  ),
                ),
                Positioned(
                  bottom: 50,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Use the slider to rate volunteer $_volunteerName.',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Styles.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Slider(
                  value: _rating,
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                  min: 0,
                  max: 10,
                  divisions: 20,
                  label: _rating.toStringAsFixed(1),
                ),
                const SizedBox(height: 20),
                Text(
                  'Rating: ${_rating.toStringAsFixed(1)} / 10',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Styles.white,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_rating > 0) {
                            _submitRating();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a rating.'),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class StarThumbShape extends SliderComponentShape {
  final double thumbRadius;

  const StarThumbShape({this.thumbRadius = 10.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.fill;

    // Draw a star shape
    const int numPoints = 5;
    final double outerRadius = thumbRadius;
    final double innerRadius = thumbRadius / 2.5;
    final Path path = Path();

    for (int i = 0; i < numPoints * 2; i++) {
      final double radius = i.isEven ? outerRadius : innerRadius;
      final double angle = (math.pi * i) / numPoints;
      final Offset point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }
}
