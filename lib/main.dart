import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screen_state/screen_state.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Wellbeing App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isPhoneInUse = false;
  int phoneNotInUseSeconds = 0;
  int screenOffSeconds = 0;
  late Timer _phoneNotInUseTimer;
  Timer? _screenOffTimer; // Nullable Timer
  late Screen _screen;
  late StreamSubscription<ScreenStateEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _initializeScreenStateListener();
    _startPhoneNotInUseTimer();
  }

  void _startPhoneNotInUseTimer() {
    _phoneNotInUseTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isPhoneInUse) {
        setState(() {
          phoneNotInUseSeconds++;
        });
      }
    });
  }

  void _initializeScreenStateListener() {
    _screen = Screen();
    _subscription = _screen.screenStateStream.listen((event) {
      if (event == ScreenStateEvent.SCREEN_OFF) {
        _startScreenOffTimer();
      } else if (event == ScreenStateEvent.SCREEN_ON) {
        _stopScreenOffTimer();
      }

      setState(() {
        isPhoneInUse = event == ScreenStateEvent.SCREEN_ON;
      });
    });
  }

  void _startScreenOffTimer() {
    if (_screenOffTimer != null) return; // Timer already running
    _screenOffTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        screenOffSeconds++;
      });
    });
  }

  void _stopScreenOffTimer() {
    _screenOffTimer?.cancel();
    _screenOffTimer = null;
  }

  // Ranking system based on screenOffSeconds
  String _getRank(int seconds) {
    if (seconds >= 300) return "General (5+ minutes)";
    if (seconds >= 240) return "Colonel (4+ minutes)";
    if (seconds >= 180) return "Major (3+ minutes)";
    if (seconds >= 120) return "Captain (2+ minutes)";
    if (seconds >= 60) return "Lieutenant (1+ minute)";
    if (seconds >= 20) return "Soldier (20+ seconds)";
    return "Recruit (Keep going!)";
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    String rank = _getRank(screenOffSeconds);

    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Wellbeing App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Time Phone Not In Use:',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              _formatTime(phoneNotInUseSeconds),
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            Text(
              'Time with Screen Off:',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              _formatTime(screenOffSeconds),
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            Text(
              'Your Rank:',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              rank,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneNotInUseTimer.cancel();
    _screenOffTimer?.cancel();
    _subscription.cancel();
    super.dispose();
  }
}
