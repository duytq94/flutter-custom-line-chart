import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_custom_line_chart/line_chart_painter.dart';
import 'package:flutter_custom_line_chart/my_weight.dart';
import 'package:touchable/touchable.dart';

class LineChartView extends StatefulWidget {
  final double heightChart;

  const LineChartView({
    super.key,
    required this.heightChart,
  });

  @override
  State<LineChartView> createState() => _LineChartViewState();
}

class _LineChartViewState extends State<LineChartView> with SingleTickerProviderStateMixin {
  // this list keep the original value generated
  var _myWeightProgressGenerated = <MyWeight>[];

  // this list will change to serve the animation
  var _myWeightProgressAnim = <MyWeight>[];

  double _maxWeight = -double.maxFinite;
  double _minWeight = double.maxFinite;

  late final _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
  late final _animation = Tween<double>(begin: 0.0, end: 1.0);

  @override
  void initState() {
    super.initState();
    _myWeightProgressGenerated = _genDataList();
    _startListenAnimation();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MyWeight> _genDataList() {
    final progress = <MyWeight>[];
    final random = Random();
    // define range weight
    const minWeight = 40;
    const maxWeight = 50;
    for (int i = 0; i < 7; i++) {
      final randomWeight =
          (random.nextInt(maxWeight - minWeight) + minWeight) + double.parse(random.nextDouble().toStringAsFixed(1));
      final myWeight = MyWeight(dateTime: DateTime.now().add(Duration(days: i)), weight: randomWeight);
      progress.add(myWeight);
      _minWeight = randomWeight < _minWeight ? randomWeight : _minWeight;
      _maxWeight = randomWeight > _maxWeight ? randomWeight : _maxWeight;
    }
    return progress;
  }

  void _startListenAnimation() {
    _animation.animate(_controller).addListener(() {
      final result = <MyWeight>[];
      for (var myWeight in _myWeightProgressGenerated) {
        final diffWeight = myWeight.weight - _minWeight;
        final newMyWeight = MyWeight(
          dateTime: myWeight.dateTime,
          // weight will change to serve the animation
          weight: _minWeight + diffWeight * _controller.value,
        );
        result.add(newMyWeight);
      }
      setState(() {
        _myWeightProgressAnim = result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CanvasTouchDetector(
      gesturesToOverride: const [GestureType.onTapDown],
      builder: (context) {
        return CustomPaint(
          painter: LineChartPainter(
            myWeightProgress: _myWeightProgressAnim,
            heightView: widget.heightChart,
            minWeight: _minWeight,
            maxWeight: _maxWeight,
            context: context,
            onPointClick: (myWeight) {
              for (var e in _myWeightProgressAnim) {
                if (e == myWeight) {
                  e.isFocusing = true;
                } else {
                  e.isFocusing = false;
                }
              }
              setState(() {
                _myWeightProgressAnim = [..._myWeightProgressAnim];
              });
            },
          ),
          size: Size(double.infinity, widget.heightChart),
        );
      },
    );
  }
}
