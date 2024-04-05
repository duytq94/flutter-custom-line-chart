import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_custom_line_chart/line_chart_view.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _heightChart = 250.0;
  final _refreshChart$ = StreamController<Key>();

  @override
  void initState() {
    super.initState();
    _refreshChart$.add(UniqueKey());
  }

  @override
  void dispose() {
    _refreshChart$.close();
    super.dispose();
  }

  void _refreshChart() {
    // rebuild to refresh chart
    _refreshChart$.add(UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Line Chart"),
        actions: [
          IconButton(
            onPressed: _refreshChart,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffEBEBEB)),
            color: Colors.black12,
          ),
          child: StreamBuilder<Key>(
            stream: _refreshChart$.stream,
            builder: (context, snapshot) {
              if (snapshot.data == null) return const SizedBox.shrink();
              return LineChartView(
                key: snapshot.data,
                heightChart: _heightChart,
              );
            },
          ),
        ),
      ),
    );
  }
}
