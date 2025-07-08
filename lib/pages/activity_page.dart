import 'package:flutter/material.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool _isLoading = false;
  List<String> _activities = [];

  Future<void> _refreshActivity() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2)); // simulate API call

    setState(() {
      _activities = []; // set your activity data here
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshActivity(); // load on init
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshActivity,
          color: Colors.white,
          backgroundColor: Colors.grey[900],
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Text(
                  'Past',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.only(top: 40)))
              else if (_activities.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      "You don't have any recent activity",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              else
                ..._activities.map(
                  (e) => ListTile(
                    title: Text(e, style: const TextStyle(color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
