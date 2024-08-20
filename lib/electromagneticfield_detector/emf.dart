import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:flutter_svg/svg.dart';

class ElectromagneticFieldDetector extends StatefulWidget {
  @override
  _ElectromagneticFieldDetectorState createState() =>
      _ElectromagneticFieldDetectorState();
}

class _ElectromagneticFieldDetectorState
    extends State<ElectromagneticFieldDetector>
    with SingleTickerProviderStateMixin {
  StreamSubscription<SensorEvent>? _magnetometerSubscription;
  List<double> _magneticField = [0, 0, 0];
  List<double> _previousField = [0, 0, 0];
  int _acEMF = 0;
  int _dcEMF = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isAdvanced = false;
  bool isMagnetometerActive = true;

  void toggleIsAdvanced() {
    setState(() {
      isAdvanced = !isAdvanced;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
    _initMagnetometer();
  }

  void _initMagnetometer() async {
    final stream = await SensorManager().sensorUpdates(
      sensorId: Sensors.MAGNETIC_FIELD,
      interval: Sensors.SENSOR_DELAY_NORMAL,
    );
    _magnetometerSubscription = stream.listen((event) {
      setState(() {
        _previousField = List.from(_magneticField);
        _magneticField = event.data;
        _calculateAcDcEMF();
        _updateAnimation();
      });
    });
  }

  void _updateAnimation() {
    if (_acEMF > 2 || _dcEMF > 60) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }
  }

  void _calculateAcDcEMF() {
    _dcEMF = (_calculateFieldStrength(_magneticField)).toInt();
    double deltaX = _magneticField[0] - _previousField[0];
    double deltaY = _magneticField[1] - _previousField[1];
    double deltaZ = _magneticField[2] - _previousField[2];
    _acEMF =
        (sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)).toInt();
  }

  Color _getIntensityColor(double strength) {
    if (strength < 50) return Colors.green;
    if (strength < 100) return Colors.yellow;
    return Colors.red;
  }

  String _getIntensityText(double strength) {
    if (_acEMF >= 3 || _dcEMF >= 120) {
      return "High EMF detected";
    } else {
      return "Normal EMF detected";
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTick = (_acEMF >= 3 || _dcEMF >= 120);

    int totalEMF = _dcEMF + _acEMF;
    Color intensityColor = _getIntensityColor((totalEMF).toDouble());
    String intensityText = _getIntensityText((totalEMF).toDouble());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              // color: Colors.white,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20), color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: SizedBox(
                      height: isAdvanced ? 350 : 450,
                      child: Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _animation.value,
                                    child: child,
                                  );
                                },
                                child: SvgPicture.asset(
                                  'lib/assets/s1.svg',
                                  semanticsLabel: 'My SVG Image',
                                  height: 200,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 1, horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SvgPicture.asset(
                          'lib/assets/sound-on.svg',
                          semanticsLabel: 'My SVG Image',
                          height: 24,
                        ),
                        Container(
                          alignment: Alignment.center,
                          height: 50,
                          child: Text(
                            intensityText,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SvgPicture.asset(
                          'lib/assets/vibrate.svg',
                          semanticsLabel: 'My SVG Image',
                          height: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            isAdvanced
                ? Column(
                    children: [
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Flexible(
                            flex: 1,
                            child: AcDcDisplay(
                              titleName: 'AC',
                              value: _acEMF.toStringAsFixed(0),
                              thresholdValue: '3',
                              isTick: isTick,
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Flexible(
                            flex: 1,
                            child: AcDcDisplay(
                              titleName: 'DC',
                              value: _dcEMF.toStringAsFixed(0),
                              thresholdValue: '120',
                              isTick: isTick,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isMagnetometerActive = !isMagnetometerActive;
                          });
                          if (isMagnetometerActive) {
                            _initMagnetometer(); // Restart magnetometer
                            _controller.repeat(); // Restart animation
                          } else {
                            _magnetometerSubscription
                                ?.cancel(); // Stop magnetometer
                            _controller.stop(); // Stop animation
                          }
                        },
                        child: SizedBox(
                          height: 50,
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white),
                              padding: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isMagnetometerActive
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    isMagnetometerActive
                                        ? "Deactivate"
                                        : "Activate",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )),
                        ),
                      ),
                    ],
                  )
                : SizedBox(),
            SizedBox(
              height: 20,
            ),
            SizedBox(
                width: 180,
                child: Text(
                  "The indicator rotates when a high emf is detected",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                )),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Advanced options",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CustomToggleButton(
                        isAdvanced: isAdvanced, onToggle: toggleIsAdvanced),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  double _calculateFieldStrength(List<double> field) {
    return sqrt(
        field[0] * field[0] + field[1] * field[1] + field[2] * field[2]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }
}

class AcDcDisplay extends StatelessWidget {
  final String titleName;
  final String value;
  final String thresholdValue;
  final bool isTick;
  const AcDcDisplay({
    required this.titleName,
    required this.value,
    required this.thresholdValue,
    required this.isTick,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${titleName}: ${value} µT",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Threshold: ${thresholdValue} µT",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline),
              ),
              Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade100,
                  ),
                  child: Center(
                      child: isTick
                          ? Icon(
                              Icons.check_circle_outline_outlined,
                              color: Colors.green,
                              size: 20,
                            )
                          : SizedBox()))
            ],
          )
        ],
      ),
    );
  }
}

class CustomToggleButton extends StatefulWidget {
  final bool isAdvanced;
  final VoidCallback onToggle;

  const CustomToggleButton({
    required this.isAdvanced,
    required this.onToggle,
    Key? key,
  }) : super(key: key);

  @override
  _CustomToggleButtonState createState() => _CustomToggleButtonState();
}

class _CustomToggleButtonState extends State<CustomToggleButton> {
  // bool isToggled = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // setState(() {
        widget.onToggle();
        // });
      },
      child: Container(
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.isAdvanced ? Colors.red.shade900 : Colors.grey,
        ),
        child: Stack(
          // alignment: ali,
          children: [
            Positioned(
              left: widget.isAdvanced ? 25 : 3,
              child: Container(
                width: 22,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


            // Text(
            //   'Electromagnetic Field Detector',
            //   style: Theme.of(context).textTheme.headlineSmall,
            // ),
            // Center(
            //   child: AnimatedBuilder(
            //     animation: _animation,
            //     builder: (context, child) {
            //       return Transform.rotate(
            //         angle: _animation.value,
            //         child: child,
            //       );
            //     },
            //     child: SvgPicture.asset(
            //       'lib/assets/s1.svg',
            //       semanticsLabel: 'My SVG Image',
            //       height: 150,
            //     ),
            //   ),
            // ),
            // SizedBox(height: 16),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceAround,
            //   children: [
            //     Column(
            //       children: [
            //         Text('DC EMF: ${_dcEMF.toStringAsFixed(0)} µT'),
            //         Text('AC EMF: ${_acEMF.toStringAsFixed(0)} µT'),
            //         Text('Total EMF: ${totalEMF.toStringAsFixed(2)} µT'),
            //       ],
            //     ),
            //     Container(
            //       width: 50,
            //       height: 50,
            //       decoration: BoxDecoration(
            //         shape: BoxShape.circle,
            //         color: intensityColor,
            //       ),
            //     ),
            //   ],
            // ),
            // SizedBox(height: 16),
            // Text('Individual Components:'),
            // Text('X: ${_magneticField[0].toStringAsFixed(2)} µT'),
            // Text('Y: ${_magneticField[1].toStringAsFixed(2)} µT'),
            // Text('Z: ${_magneticField[2].toStringAsFixed(2)} µT'),


// import 'dart:async';
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:flutter_sensors/flutter_sensors.dart';

// class ElectromagneticFieldDetector extends StatefulWidget {
//   @override
//   _ElectromagneticFieldDetectorState createState() =>
//       _ElectromagneticFieldDetectorState();
// }

// class _ElectromagneticFieldDetectorState
//     extends State<ElectromagneticFieldDetector> {
//   StreamSubscription<SensorEvent>? _magnetometerSubscription;
//   List<double> _magneticField = [0, 0, 0];

//   @override
//   void initState() {
//     super.initState();
//     _initMagnetometer();
//   }

//   void _initMagnetometer() async {
//     final stream = await SensorManager().sensorUpdates(
//       sensorId: Sensors.MAGNETIC_FIELD,
//       interval: Sensors.SENSOR_DELAY_NORMAL,
//     );
//     _magnetometerSubscription = stream.listen((event) {
//       setState(() {
//         _magneticField = event.data;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Electromagnetic Field Detector',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//             SizedBox(height: 16),
//             Column(
//               children: [
//                 Text(
//                     'Field Strength: ${_calculateFieldStrength(_magneticField).toStringAsFixed(2)} µT'),
//                 SizedBox(height: 8),
//                 Text('X: ${_magneticField[0].toStringAsFixed(2)} µT'),
//                 Text('Y: ${_magneticField[1].toStringAsFixed(2)} µT'),
//                 Text('Z: ${_magneticField[2].toStringAsFixed(2)} µT'),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   double _calculateFieldStrength(List<double> field) {
//     return sqrt(
//         field[0] * field[0] + field[1] * field[1] + field[2] * field[2]);
//   }

//   @override
//   void dispose() {
//     _magnetometerSubscription?.cancel();
//     super.dispose();
//   }
// }
