import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_sound/flutter_sound.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DevicesScreen(),
    AudioFilesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My App'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Device',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.audiotrack),
            label: 'Audio Records',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> _connectedDevices = [];
  final List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    if (_isScanning) {
      print('Scan already in progress');
      return;
    }

    _isScanning = true;

    _flutterBlue.scanResults.listen((scanResults) {
      if (!mounted) return;
      setState(() {
        _scanResults.addAll(scanResults);
      });
    });

    _flutterBlue.startScan(timeout: Duration(seconds: 4)).catchError((error) {
      if (!mounted) return;
      print("Error starting scan: $error");
    }).whenComplete(() {
      _isScanning = false;
    });
  }

  @override
  void dispose() {
    if (_isScanning) {
      _flutterBlue.stopScan();
      _isScanning = false;
    }
    super.dispose();
  }

  void _connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      _connectedDevices.add(device);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(
          Icons.devices,
          size: 100,
          color: Colors.grey,
        ),
        const SizedBox(height: 20),
        const Text(
          'Added Devices:',
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _connectedDevices.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_connectedDevices[index].name),
                subtitle: Text(_connectedDevices[index].id.toString()),
              );
            },
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _startScan();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add device'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _scanResults.length,
            itemBuilder: (context, index) {
              final result = _scanResults[index];
              return ListTile(
                title: Text(result.device.name),
                subtitle: Text(result.device.id.toString()),
                onTap: () => _connectToDevice(result.device),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AudioFilesScreen extends StatefulWidget {
  const AudioFilesScreen({super.key});

  @override
  State<AudioFilesScreen> createState() => _AudioFilesScreenState();
}

class _AudioFilesScreenState extends State<AudioFilesScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final List<String> _audioFiles = [];

  void _startRecording() async {
    await _recorder.startRecorder(toFile: 'audio.aac');
    setState(() {
      _audioFiles.add('audio.aac');
    });
  }

  void _stopRecording() async {
    await _recorder.stopRecorder();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Text(
          'Audio files:',
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _audioFiles.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Record ${index + 1}'),
                subtitle: Text(_audioFiles[index]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                onPressed: _startRecording,
                child: const Text('Record'),
              ),
              ElevatedButton(
                onPressed: _stopRecording,
                child: const Text('Stop'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}