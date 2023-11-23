import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_custom_line_chart/line_chart_painter.dart';
import 'package:flutter_custom_line_chart/my_weight.dart';
import 'package:touchable/touchable.dart';

class LineChartPage extends StatefulWidget {
  const LineChartPage({super.key});

  @override
  State<LineChartPage> createState() => _LineChartPageState();
}

class _LineChartPageState extends State<LineChartPage> {
  final _heightChartView = 200.0;
  final _backgroundChart = const Color(0xffFBFBFB);
  final _mainColorChart = const Color(0xff9493C8);

  var _myWeightProgress = <MyWeight>[];
  double _maxWeight = -double.maxFinite;
  double _minWeight = double.maxFinite;

  @override
  void initState() {
    super.initState();

    // gen data list
    final random = Random();
    const minWeight = 40;
    const maxWeight = 50;
    for (int i = 0; i < 7; i++) {
      final randomWeight =
          (random.nextInt(maxWeight - minWeight) + minWeight) + double.parse(random.nextDouble().toStringAsFixed(1));
      final myWeight = MyWeight(dateTime: DateTime.now().add(Duration(days: i)), weight: randomWeight);
      _myWeightProgress.add(myWeight);
      _minWeight = randomWeight < _minWeight ? randomWeight : _minWeight;
      _maxWeight = randomWeight > _maxWeight ? randomWeight : _maxWeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Line Chart")),
      backgroundColor: const Color(0xffE5E9EF),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffEBEBEB)),
                color: _backgroundChart,
              ),
              child: CanvasTouchDetector(
                gesturesToOverride: const [GestureType.onTapDown],
                builder: (context) {
                  return CustomPaint(
                    painter: LineChartPainter(
                      myWeightProgress: _myWeightProgress,
                      heightView: _heightChartView,
                      minWeight: _minWeight,
                      maxWeight: _maxWeight,
                      mainColor: _mainColorChart,
                      backgroundColor: _backgroundChart,
                      context: context,
                      onPointClick: (myWeight) {
                        for (var e in _myWeightProgress) {
                          if (e == myWeight) {
                            e.isFocusing = true;
                          } else {
                            e.isFocusing = false;
                          }
                        }
                        setState(() {
                          _myWeightProgress = [..._myWeightProgress];
                        });
                      },
                    ),
                    size: Size(double.infinity, _heightChartView),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
