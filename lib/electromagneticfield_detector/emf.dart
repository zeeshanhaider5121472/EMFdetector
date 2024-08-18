import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';

class ElectromagneticFieldDetector extends StatefulWidget {
  @override
  _ElectromagneticFieldDetectorState createState() =>
      _ElectromagneticFieldDetectorState();
}

class _ElectromagneticFieldDetectorState
    extends State<ElectromagneticFieldDetector> {
  StreamSubscription<SensorEvent>? _magnetometerSubscription;
  List<double> _magneticField = [0, 0, 0];
  List<double> _previousField = [0, 0, 0];
  int _acEMF = 0;
  int _dcEMF = 0;

  @override
  void initState() {
    super.initState();
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
      });
    });
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

  @override
  Widget build(BuildContext context) {
    int totalEMF = _dcEMF + _acEMF;
    Color intensityColor = _getIntensityColor((totalEMF).toDouble());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Electromagnetic Field Detector',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('DC EMF: ${_dcEMF.toStringAsFixed(0)} µT'),
                    Text('AC EMF: ${_acEMF.toStringAsFixed(0)} µT'),
                    Text('Total EMF: ${totalEMF.toStringAsFixed(2)} µT'),
                  ],
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: intensityColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Individual Components:'),
            Text('X: ${_magneticField[0].toStringAsFixed(2)} µT'),
            Text('Y: ${_magneticField[1].toStringAsFixed(2)} µT'),
            Text('Z: ${_magneticField[2].toStringAsFixed(2)} µT'),
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
    _magnetometerSubscription?.cancel();
    super.dispose();
  }
}
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
