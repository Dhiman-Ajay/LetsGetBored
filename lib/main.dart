import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screen_state/screen_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lets Get Bored',
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
  Timer? _screenOffTimer;
  late Screen _screen;
  late StreamSubscription<ScreenStateEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _initializeScreenStateListener();
    _startPhoneNotInUseTimer();
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastSavedTimestamp = prefs.getInt('lastSavedTimestamp');
    int? lastScreenOffTimestamp = prefs.getInt('lastScreenOffTimestamp');
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Restore phone usage time
    phoneNotInUseSeconds = prefs.getInt('phoneNotInUseSeconds') ?? 0;
    if (lastSavedTimestamp != null) {
      phoneNotInUseSeconds += currentTimestamp - lastSavedTimestamp;
    }

    // Restore screen off time
    screenOffSeconds = prefs.getInt('screenOffSeconds') ?? 0;
    if (lastScreenOffTimestamp != null) {
      screenOffSeconds += currentTimestamp - lastScreenOffTimestamp;
    }

    await _saveData();
    setState(() {});
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('phoneNotInUseSeconds', phoneNotInUseSeconds);
    prefs.setInt('screenOffSeconds', screenOffSeconds);
    prefs.setInt('lastSavedTimestamp', DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  void _startPhoneNotInUseTimer() {
    _phoneNotInUseTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isPhoneInUse) {
        setState(() {
          phoneNotInUseSeconds++;
        });
        _saveData();
      }
    });
  }

  void _initializeScreenStateListener() {
    _screen = Screen();
    _subscription = _screen.screenStateStream.listen((event) {
      if (event == ScreenStateEvent.SCREEN_OFF) {
        _pausePhoneNotInUseTimer();
        _startScreenOffTimer();
      } else if (event == ScreenStateEvent.SCREEN_ON) {
        _resumePhoneNotInUseTimer();
        _stopScreenOffTimer();
      }
      setState(() {
        isPhoneInUse = event == ScreenStateEvent.SCREEN_ON;
      });
    });
  }

  // Pause the phone not in use timer
  void _pausePhoneNotInUseTimer() {
    _phoneNotInUseTimer.cancel();
  }

  // Resume the phone not in use timer
  void _resumePhoneNotInUseTimer() {
    _startPhoneNotInUseTimer();
  }

  void _startScreenOffTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Only store timestamp if it's not already set
    if (prefs.getInt('lastScreenOffTimestamp') == null) {
      prefs.setInt('lastScreenOffTimestamp', DateTime.now().millisecondsSinceEpoch ~/ 1000);
    }

    if (_screenOffTimer != null) return;
    _screenOffTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        screenOffSeconds++;
      });
      _saveData();
    });
  }

  void _stopScreenOffTimer() async {
    _screenOffTimer?.cancel();
    _screenOffTimer = null;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastScreenOffTimestamp = prefs.getInt('lastScreenOffTimestamp');
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (lastScreenOffTimestamp != null) {
      screenOffSeconds += currentTimestamp - lastScreenOffTimestamp;
      prefs.setInt('screenOffSeconds', screenOffSeconds);
    }

    prefs.remove('lastScreenOffTimestamp'); // Remove only after updating
  }

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

  String _formatDays(int seconds) {
    int days = seconds ~/ 86400;
    return '$days ${days == 1 ? 'day' : 'days'}';
  }

  @override
  Widget build(BuildContext context) {
    String rank = _getRank(screenOffSeconds);
    return Scaffold(
      appBar: AppBar(
        title: Text('Lets Get Bored'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade300],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Time (Phone In Use):', style: TextStyle(fontSize: 20, color: Colors.white)),
              Text(_formatTime(phoneNotInUseSeconds),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(_formatDays(phoneNotInUseSeconds), style: TextStyle(fontSize: 16, color: Colors.white)),
              SizedBox(height: 32),
              Text('Time (Screen Off):', style: TextStyle(fontSize: 20, color: Colors.white)),
              Text(_formatTime(screenOffSeconds),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(_formatDays(screenOffSeconds), style: TextStyle(fontSize: 16, color: Colors.white)),
              SizedBox(height: 32),
              Text(
                'Current Rank: $rank',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RankPage(currentRank: rank)),
                  );
                },
                child: Text("My Rank"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ListTile(
        title: Text("About This App"),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("About This App"),
              content: Text("This app helps you track and improve your screen time habits."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class RankPage extends StatelessWidget {
  final String currentRank;
  RankPage({required this.currentRank});

  final List<String> ranks = [
    "Recruit (Keep going!)",
    "Soldier (20+ seconds)",
    "Lieutenant (1+ minute)",
    "Captain (2+ minutes)",
    "Major (3+ minutes)",
    "Colonel (4+ minutes)",
    "General (5+ minutes)"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Rank")),
      body: ListView.builder(
        itemCount: ranks.length,
        itemBuilder: (context, index) {
          bool isCurrentRank = ranks[index] == currentRank;
          return ListTile(
            title: Text(ranks[index],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isCurrentRank ? Colors.blue : Colors.black)),
            tileColor: isCurrentRank ? Colors.blue.withOpacity(0.2) : Colors.white,
          );
        },
      ),
    );
  }
}