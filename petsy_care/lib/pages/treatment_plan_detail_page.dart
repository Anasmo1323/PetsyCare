import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petsy_care/models/treatment_plan_model.dart';
import 'package:petsy_care/widgets/daily_log_form.dart';

class TreatmentPlanDetailPage extends StatefulWidget {
  final String patientId;
  final TreatmentPlan plan;

  const TreatmentPlanDetailPage({
    super.key,
    required this.patientId,
    required this.plan,
  });

  @override
  State<TreatmentPlanDetailPage> createState() =>
      _TreatmentPlanDetailPageState();
}

class _TreatmentPlanDetailPageState extends State<TreatmentPlanDetailPage>
    with SingleTickerProviderStateMixin { // We need this for the TabController
      
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().format(widget.plan.startDate.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Text('Plan: $formattedDate'),
        // The TabBar goes at the bottom of the AppBar
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Allows scrolling on small screens
          tabs: const [
            Tab(text: 'Day 1'),
            Tab(text: 'Day 2'),
            Tab(text: 'Day 3'),
            Tab(text: 'Day 4'),
            Tab(text: 'Day 5'),
            Tab(text: 'Day 6'),
            Tab(text: 'Day 7'),
          ],
        ),
      ),
      // TabBarView holds the content for each tab
      body: TabBarView(
        controller: _tabController,
        children: [
          // We pass the correct data to each form
          DailyLogForm(
            patientId: widget.patientId,
            planId: widget.plan.id,
            dayKey: 'day1',
            dailyLog: widget.plan.day1,
          ),
          DailyLogForm(
            patientId: widget.patientId,
            planId: widget.plan.id,
            dayKey: 'day2',
            dailyLog: widget.plan.day2,
          ),
          DailyLogForm(
            patientId: widget.patientId,
            planId: widget.plan.id,
            dayKey: 'day3',
            dailyLog: widget.plan.day3,
          ),
          DailyLogForm(
            patientId: widget.patientId,
            planId: widget.plan.id,
            dayKey: 'day4',
            dailyLog: widget.plan.day4,
          ),
          DailyLogForm(
            patientId: widget.patientId,
            planId: widget.plan.id,
            dayKey: 'day5',
            dailyLog: widget.plan.day5,
          ),
          DailyLogForm(
            patientId: widget.patientId,
            planId: widget.plan.id,
            dayKey: 'day6',
            dailyLog: widget.plan.day6,
          ),
          DailyLogForm(
            patientId: widget.patientId,
            planId: widget.plan.id,
            dayKey: 'day7',
            dailyLog: widget.plan.day7,
          ),
        ],
      ),
    );
  }
}