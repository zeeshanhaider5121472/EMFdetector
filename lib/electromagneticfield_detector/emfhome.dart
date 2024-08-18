import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ElectromagneticFieldDetectorHome extends StatefulWidget {
  // final int i;

  // const ElectromagneticFieldDetectorHome({super.key, required this.i});
  @override
  _ElectromagneticFieldDetectorHomeState createState() =>
      _ElectromagneticFieldDetectorHomeState();
}

class _ElectromagneticFieldDetectorHomeState
    extends State<ElectromagneticFieldDetectorHome>
    with SingleTickerProviderStateMixin {
  int i = 19;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Adjust spinning speed here
    );
    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
    if (i == 20) {
      isSpinning = true;
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: Colors.white,
            child: Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: isSpinning ? _animation.value : 0,
                    child: child,
                  );
                },
                child: SvgPicture.asset(
                  'lib/assets/s1.svg',
                  semanticsLabel: 'My SVG Image',
                  height: 300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
